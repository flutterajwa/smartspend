import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../data/local_db.dart';
import '../../data/models/transaction_model.dart';
import '../../data/models/budget_model.dart';

class TransactionProvider extends ChangeNotifier {
  List<TransactionModel> _transactions = [];
  List<BudgetModel> _budgets = [];
  bool _isLoading = false;

  List<TransactionModel> get transactions => _transactions;
  List<BudgetModel> get budgets => _budgets;
  bool get isLoading => _isLoading;

  double get totalIncome => _transactions
      .where((t) => t.type == TransactionType.income)
      .fold(0, (sum, t) => sum + t.amount);

  double get totalExpense => _transactions
      .where((t) => t.type == TransactionType.expense)
      .fold(0, (sum, t) => sum + t.amount);

  double get balance => totalIncome - totalExpense;

  Future<void> fetchTransactions(String userId) async {
    _isLoading = true;
    notifyListeners();
    _transactions = await LocalDB.getTransactions();
    _isLoading = false;
    notifyListeners();
  }

  // Budget Methods
  Future<void> fetchBudgets(int month, int year) async {
    _budgets = await LocalDB.getBudgets(month, year);
    notifyListeners();
  }

  Future<void> saveBudget(BudgetModel budget) async {
    await LocalDB.saveBudget(budget);
    await fetchBudgets(budget.month, budget.year);
  }

  Future<void> deleteBudget(String category, int month, int year) async {
    await LocalDB.deleteBudget(category, month, year);
    await fetchBudgets(month, year);
  }

  double getCategorySpending(String category, int month, int year) {
    return _transactions
        .where((t) => 
            t.category == category && 
            t.type == TransactionType.expense && 
            t.date.month == month && 
            t.date.year == year)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double getBudgetProgress(String category, int month, int year) {
    try {
      final budget = _budgets.firstWhere(
        (b) => b.category == category && b.month == month && b.year == year,
      );
      if (budget.amount == 0) return 0.0;
      final spending = getCategorySpending(category, month, year);
      return (spending / budget.amount).clamp(0.0, 1.0);
    } catch (_) {
      return 0.0;
    }
  }

  double getBudgetAmount(String category, int month, int year) {
    try {
      final budget = _budgets.firstWhere(
        (b) => b.category == category && b.month == month && b.year == year,
      );
      return budget.amount;
    } catch (_) {
      return 0.0;
    }
  }

  Future<void> addTransaction(TransactionModel transaction) async {
    final docId = const Uuid().v4();
    final newTransaction = TransactionModel(
      id: docId,
      userId: transaction.userId,
      title: transaction.title,
      amount: transaction.amount,
      category: transaction.category,
      type: transaction.type,
      date: transaction.date,
      note: transaction.note,
    );

    await LocalDB.insertTransaction(newTransaction);
    await fetchTransactions(transaction.userId);
  }

  Future<void> deleteTransaction(String userId, String transactionId) async {
    await LocalDB.deleteTransaction(transactionId);
    await fetchTransactions(userId);
  }

  List<String> getAIInsights() {
    List<String> insights = [];
    if (_transactions.isEmpty) return ["Add some transactions for AI insights!"];

    final now = DateTime.now();
    final thisMonthTransactions = _transactions.where((t) => t.date.month == now.month).toList();
    
    final categoryTotals = <String, double>{};
    for (var t in thisMonthTransactions.where((t) => t.type == TransactionType.expense)) {
      categoryTotals[t.category] = (categoryTotals[t.category] ?? 0) + t.amount;
    }
    
    if (categoryTotals.isNotEmpty) {
      final highestCat = categoryTotals.entries.reduce((a, b) => a.value > b.value ? a : b);
      insights.add("You've spent most on **${highestCat.key}** this month (₹${highestCat.value.toStringAsFixed(0)}).");
    }

    final totalThisMonth = thisMonthTransactions
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (sum, t) => sum + t.amount);
    
    if (totalThisMonth > 0) {
      insights.add("Your total spending this month is **₹${totalThisMonth.toStringAsFixed(0)}**.");
    }

    if (categoryTotals['Food'] != null && categoryTotals['Food']! > 5000) {
      insights.add("Tip: Consider cooking at home to save on Food expenses.");
    }
    
    return insights;
  }
}
