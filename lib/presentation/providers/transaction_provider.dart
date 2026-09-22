import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../data/local_db.dart';
import '../../data/models/transaction_model.dart';
import '../../data/models/budget_model.dart';
import '../../data/models/recurring_transaction_model.dart';
import '../../core/utils/notification_helper.dart';
import '../../core/constants.dart';

class TransactionProvider extends ChangeNotifier {
  List<TransactionModel> _transactions = [];
  List<BudgetModel> _budgets = [];
  List<RecurringTransactionModel> _recurringTransactions = [];
  bool _isLoading = false;

  List<TransactionModel> get transactions => _transactions;
  List<BudgetModel> get budgets => _budgets;
  List<RecurringTransactionModel> get recurringTransactions => _recurringTransactions;
  bool get isLoading => _isLoading;

  Future<void> fetchRecurringTransactions() async {
    _recurringTransactions = await LocalDB.getRecurringTransactions();
    notifyListeners();
  }

  Future<void> addRecurringTransaction(RecurringTransactionModel recurring) async {
    await LocalDB.insertRecurringTransaction(recurring);
    await fetchRecurringTransactions();
  }

  Future<void> deleteRecurringTransaction(String id) async {
    await LocalDB.deleteRecurringTransaction(id);
    await fetchRecurringTransactions();
  }

  Future<void> toggleRecurringTransaction(RecurringTransactionModel recurring) async {
    final updated = recurring.copyWith(isActive: !recurring.isActive);
    await LocalDB.updateRecurringTransaction(updated);
    await fetchRecurringTransactions();
  }

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
    
    try {
      // 1. Load transactions instantly to render the UI immediately
      _transactions = await LocalDB.getTransactions();
      _isLoading = false;
      notifyListeners();
      
      // 2. Perform category updates and recurring checks in the background
      await fetchCategories();
      await checkAndExecuteRecurring(userId);
      
      // 3. Refresh list if any new recurring items were automatically generated
      _transactions = await LocalDB.getTransactions();
      notifyListeners();
    } catch (e) {
      debugPrint('Error syncing data: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchCategories() async {
    final maps = await LocalDB.getCategories();
    if (maps.isNotEmpty) {
      TransactionCategory.categories = maps.map((m) => TransactionCategory.fromMap(m)).toList();
    } else {
      TransactionCategory.categories = List.from(TransactionCategory.defaultCategories);
    }
    notifyListeners();
  }

  Future<void> addCategory(String name, int iconCode, int colorValue) async {
    await LocalDB.saveCategory(name, iconCode, colorValue);
    await fetchCategories();
  }

  Future<void> deleteCategory(String name) async {
    await LocalDB.deleteCategory(name);
    await fetchCategories();
  }

  Future<void> checkAndExecuteRecurring(String userId) async {
    final recurrings = await LocalDB.getRecurringTransactions();
    final now = DateTime.now();

    for (var rec in recurrings) {
      if (!rec.isActive) continue;

      DateTime lastExec = rec.lastExecutedDate;
      DateTime nextExec = _calculateNextExecutionDate(lastExec, rec.frequency);
      
      bool updated = false;
      var currentRec = rec;

      while (nextExec.isBefore(now) || _isSameDay(nextExec, now)) {
        final docId = const Uuid().v4();
        final transaction = TransactionModel(
          id: docId,
          userId: userId,
          title: rec.title,
          amount: rec.amount,
          category: rec.category,
          type: rec.type,
          date: nextExec,
          note: 'Automatically logged subscription',
          paymentMethod: rec.paymentMethod,
        );
        await LocalDB.insertTransaction(transaction);

        lastExec = nextExec;
        nextExec = _calculateNextExecutionDate(lastExec, rec.frequency);
        updated = true;
      }

      if (updated) {
        currentRec = currentRec.copyWith(lastExecutedDate: lastExec);
        await LocalDB.updateRecurringTransaction(currentRec);
      }
    }
  }

  DateTime _calculateNextExecutionDate(DateTime from, RecurrenceFrequency frequency) {
    switch (frequency) {
      case RecurrenceFrequency.daily:
        return from.add(const Duration(days: 1));
      case RecurrenceFrequency.weekly:
        return from.add(const Duration(days: 7));
      case RecurrenceFrequency.monthly:
        int nextMonth = from.month + 1;
        int nextYear = from.year;
        if (nextMonth > 12) {
          nextMonth = 1;
          nextYear += 1;
        }
        int day = from.day;
        int lastDayOfNextMonth = DateTime(nextYear, nextMonth + 1, 0).day;
        if (day > lastDayOfNextMonth) {
          day = lastDayOfNextMonth;
        }
        return DateTime(nextYear, nextMonth, day, from.hour, from.minute);
      case RecurrenceFrequency.yearly:
        return DateTime(from.year + 1, from.month, from.day, from.hour, from.minute);
    }
  }

  bool _isSameDay(DateTime d1, DateTime d2) {
    return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
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

  Future<void> copyBudgetsFromPreviousMonth(int currentMonth, int currentYear) async {
    int prevMonth = currentMonth - 1;
    int prevYear = currentYear;
    if (prevMonth == 0) {
      prevMonth = 12;
      prevYear = currentYear - 1;
    }

    final prevBudgets = await LocalDB.getBudgets(prevMonth, prevYear);
    for (var b in prevBudgets) {
      final copied = BudgetModel(
        category: b.category,
        amount: b.amount,
        month: currentMonth,
        year: currentYear,
      );
      await LocalDB.saveBudget(copied);
    }
    await fetchBudgets(currentMonth, currentYear);
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

  TransactionModel? parseQuickInput(String text, String userId) {
    if (text.isEmpty) return null;

    // 1. Extract amount using regex
    final amountRegex = RegExp(r'(\d+(?:\.\d{1,2})?)');
    final match = amountRegex.firstMatch(text);
    if (match == null) return null; // No amount found
    final amount = double.tryParse(match.group(1)!) ?? 0.0;
    if (amount <= 0) return null;

    // 2. Determine transaction type (Income vs Expense)
    final lowercaseText = text.toLowerCase();
    TransactionType type = TransactionType.expense;
    if (lowercaseText.contains('salary') || 
        lowercaseText.contains('income') || 
        lowercaseText.contains('received') || 
        lowercaseText.contains('earned') ||
        lowercaseText.contains('refund')) {
      type = TransactionType.income;
    }

    // 3. Extract Category
    String category = 'Others';
    if (type == TransactionType.income) {
      category = 'Salary';
    } else {
      final catKeywords = {
        'Food': ['food', 'lunch', 'dinner', 'breakfast', 'eat', 'restaurant', 'cafe', 'tea', 'coffee', 'hotel', 'groceries', 'snack', 'swiggy', 'zomato'],
        'Travel': ['travel', 'cab', 'taxi', 'fuel', 'petrol', 'diesel', 'bus', 'train', 'flight', 'auto', 'uber', 'ola', 'ride', 'ticket'],
        'Bills': ['bill', 'rent', 'electricity', 'water', 'recharge', 'wifi', 'internet', 'subscription', 'netflix', 'spotify', 'prime', 'fee', 'tax'],
        'Shopping': ['shop', 'dress', 'shirt', 'pant', 'shoe', 'buy', 'gift', 'amazon', 'flipkart', 'gadget', 'phone', 'laptop', 'cloth'],
        'Health': ['health', 'hospital', 'doctor', 'medicine', 'clinic', 'pharmacy', 'gym', 'fitness', 'medical', 'pill'],
      };

      for (var entry in catKeywords.entries) {
        for (var keyword in entry.value) {
          if (lowercaseText.contains(keyword)) {
            category = entry.key;
            break;
          }
        }
        if (category != 'Others') break;
      }
    }

    // 4. Determine Title
    String title = text
        .replaceAll(match.group(1)!, '') // Remove amount
        .replaceAll(RegExp(r'\b(for|on|at|spent|received|of|in|to)\b', caseSensitive: false), '') // Remove helper prepositions
        .trim();
    
    title = title.replaceAll(RegExp(r'\s+'), ' ');

    if (title.length < 3) {
      title = 'Quick ${type == TransactionType.income ? "Income" : category}';
    } else {
      title = title[0].toUpperCase() + title.substring(1);
    }

    return TransactionModel(
      id: '',
      userId: userId,
      title: title,
      amount: amount,
      category: category,
      type: type,
      date: DateTime.now(),
      paymentMethod: PaymentMethod.account, // Default payment method
    );
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
    
    // Save state before fetching so we can compare
    final double previousSpending = getCategorySpending(transaction.category, transaction.date.month, transaction.date.year);
    final double budgetAmount = getBudgetAmount(transaction.category, transaction.date.month, transaction.date.year);

    await fetchTransactions(transaction.userId);

    // Budget alert check (only for expenses)
    if (transaction.type == TransactionType.expense && budgetAmount > 0) {
      final currentSpending = getCategorySpending(transaction.category, transaction.date.month, transaction.date.year);
      
      final previousProgress = previousSpending / budgetAmount;
      final currentProgress = currentSpending / budgetAmount;

      if (currentProgress >= 1.0 && previousProgress < 1.0) {
        await NotificationHelper.showBudgetAlert(
          category: transaction.category,
          spending: currentSpending,
          budgetAmount: budgetAmount,
          isExceeded: true,
        );
      } else if (currentProgress >= 0.8 && currentProgress < 1.0 && previousProgress < 0.8) {
        await NotificationHelper.showBudgetAlert(
          category: transaction.category,
          spending: currentSpending,
          budgetAmount: budgetAmount,
          isExceeded: false,
        );
      }
    }
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

