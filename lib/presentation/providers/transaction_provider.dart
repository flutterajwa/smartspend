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

  double get cashBalance {
    double income = _transactions
        .where((t) => t.type == TransactionType.income && t.paymentMethod == PaymentMethod.cash)
        .fold(0, (sum, t) => sum + t.amount);
    double expense = _transactions
        .where((t) => t.type == TransactionType.expense && t.paymentMethod == PaymentMethod.cash)
        .fold(0, (sum, t) => sum + t.amount);
    double transferOut = _transactions
        .where((t) => t.type == TransactionType.transfer && t.paymentMethod == PaymentMethod.cash)
        .fold(0, (sum, t) => sum + t.amount);
    double transferIn = _transactions
        .where((t) => t.type == TransactionType.transfer && t.toPaymentMethod == PaymentMethod.cash)
        .fold(0, (sum, t) => sum + t.amount);
    return income - expense - transferOut + transferIn;
  }

  double get accountBalance {
    double income = _transactions
        .where((t) => t.type == TransactionType.income && t.paymentMethod == PaymentMethod.account)
        .fold(0, (sum, t) => sum + t.amount);
    double expense = _transactions
        .where((t) => t.type == TransactionType.expense && t.paymentMethod == PaymentMethod.account)
        .fold(0, (sum, t) => sum + t.amount);
    double transferOut = _transactions
        .where((t) => t.type == TransactionType.transfer && t.paymentMethod == PaymentMethod.account)
        .fold(0, (sum, t) => sum + t.amount);
    double transferIn = _transactions
        .where((t) => t.type == TransactionType.transfer && t.toPaymentMethod == PaymentMethod.account)
        .fold(0, (sum, t) => sum + t.amount);
    return income - expense - transferOut + transferIn;
  }

  double get balance => cashBalance + accountBalance;

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
      paymentMethod: transaction.paymentMethod,
      toPaymentMethod: transaction.toPaymentMethod,
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
    final thisMonthTransactions = _transactions.where((t) => t.date.month == now.month && t.date.year == now.year).toList();
    
    // 1. Highest Category
    final categoryTotals = <String, double>{};
    for (var t in thisMonthTransactions.where((t) => t.type == TransactionType.expense)) {
      categoryTotals[t.category] = (categoryTotals[t.category] ?? 0) + t.amount;
    }
    
    if (categoryTotals.isNotEmpty) {
      final highestCat = categoryTotals.entries.reduce((a, b) => a.value > b.value ? a : b);
      insights.add("You've spent most on **${highestCat.key}** this month (₹${highestCat.value.toStringAsFixed(0)}).");
    }

    // 2. Total and Averages
    final totalThisMonth = thisMonthTransactions
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (sum, t) => sum + t.amount);
    
    if (totalThisMonth > 0) {
      insights.add("Your total spending this month is **₹${totalThisMonth.toStringAsFixed(0)}**.");
      
      // Calculate Daily Average
      int daysInMonthSoFar = now.day;
      double dailyAverage = totalThisMonth / daysInMonthSoFar;
      insights.add("You are spending an average of **₹${dailyAverage.toStringAsFixed(0)} per day** this month.");

      // Projected Monthly Spend
      int totalDaysInMonth = DateTime(now.year, now.month + 1, 0).day;
      double projectedSpend = dailyAverage * totalDaysInMonth;
      insights.add("At this rate, you'll spend roughly **₹${projectedSpend.toStringAsFixed(0)}** by the end of the month.");
    }

    // 3. Highest Spending Day of the Week
    final dayTotals = <int, double>{};
    for (var t in _transactions.where((t) => t.type == TransactionType.expense)) {
      dayTotals[t.date.weekday] = (dayTotals[t.date.weekday] ?? 0) + t.amount;
    }
    if (dayTotals.isNotEmpty) {
      final days = ["", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"];
      final highestDay = dayTotals.entries.reduce((a, b) => a.value > b.value ? a : b);
      insights.add("Historically, your highest spending day is **${days[highestDay.key]}**.");
    }

    insights.add("Your current split: **Cash (₹${cashBalance.toStringAsFixed(0)})** and **Account (₹${accountBalance.toStringAsFixed(0)})**.");

    if (categoryTotals['Food'] != null && categoryTotals['Food']! > 5000) {
      insights.add("Tip: Consider cooking at home to save on Food expenses.");
    }
    if (categoryTotals['Shopping'] != null && categoryTotals['Shopping']! > totalThisMonth * 0.3) {
      insights.add("Overspending Alert: Shopping accounts for more than 30% of your current expenses.");
    }
    
    return insights;
  }
}

