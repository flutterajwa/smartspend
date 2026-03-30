import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/app_colors.dart';
import '../../core/constants.dart';
import '../providers/auth_provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/expense_chart.dart';
import '../../data/models/transaction_model.dart';
import '../../data/models/budget_model.dart';
import 'add_expense_screen.dart';
import 'insights_screen.dart';
import 'transaction_history_screen.dart';
import 'debt_screen.dart';
import '../providers/debt_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedFilter = 'Monthly';
  DateTimeRange? _customRange;
  DateTime _summaryMonth = DateTime.now();
  String _selectedAverageCategory = 'All';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshData();
    });
  }

  void _refreshData() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.user != null) {
      final tp = Provider.of<TransactionProvider>(context, listen: false);
      tp.fetchTransactions(auth.user!.uid);
      tp.fetchBudgets(_summaryMonth.month, _summaryMonth.year);
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning,';
    if (hour < 17) return 'Good Afternoon,';
    return 'Good Evening,';
  }

  List<TransactionModel> _getFilteredTransactions(List<TransactionModel> transactions) {
    final now = DateTime.now();
    switch (_selectedFilter) {
      case 'Day':
        return transactions.where((t) => 
          t.date.day == now.day && t.date.month == now.month && t.date.year == now.year).toList();
      case 'Week':
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        return transactions.where((t) => 
          t.date.isAfter(startOfWeek.subtract(const Duration(seconds: 1)))).toList();
      case 'Yearly':
        return transactions.where((t) => t.date.year == now.year).toList();
      case 'Custom':
        if (_customRange == null) return transactions;
        return transactions.where((t) => 
          t.date.isAfter(_customRange!.start.subtract(const Duration(seconds: 1))) && 
          t.date.isBefore(_customRange!.end.add(const Duration(days: 1)))).toList();
      case 'Monthly':
      default:
        return transactions.where((t) => t.date.month == now.month && t.date.year == now.year).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final tp = Provider.of<TransactionProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final filteredTransactions = _getFilteredTransactions(tp.transactions);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_getGreeting(), style: GoogleFonts.outfit(fontSize: 14, color: Colors.grey)),
            Text(auth.user?.name ?? 'User', style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: const [],
      ),
      drawer: _buildDrawer(context, auth),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Activity Summary', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text('Swipe for more', style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey)),
                ],
              ),
              const SizedBox(height: 12),
              _buildSummarySection(tp),
              const SizedBox(height: 20),
              _buildSpendingOverviewHeader(),
              const SizedBox(height: 12),
              _buildFilterChips(),
              const SizedBox(height: 16),
              _buildQuickStatsData(filteredTransactions),
              const SizedBox(height: 16),
              SizedBox(height: 250, child: ExpenseChart(transactions: filteredTransactions)),
              const SizedBox(height: 30),

              _buildBudgetSection(tp),
              const SizedBox(height: 30),
              _buildRecentTransactionsHeader(context),
              _buildRecentTransactionsList(tp, auth),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AddExpenseScreen())),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white, size: 32),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, AuthProvider auth) {
    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(auth.user?.name ?? 'User', style: const TextStyle(fontWeight: FontWeight.bold)),
            accountEmail: Text(auth.user?.email ?? 'user@example.com'),
            currentAccountPicture: const CircleAvatar(backgroundColor: Colors.white, child: Icon(Icons.person, color: AppColors.primary)),
            decoration: const BoxDecoration(color: AppColors.primary),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard_outlined),
            title: const Text('Dashboard'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.insights_rounded),
            title: const Text('AI Insights'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const InsightsScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.history_rounded),
            title: const Text('History'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const TransactionHistoryScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.handshake_outlined),
            title: const Text('Debts'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const DebtScreen()));
            },
          ),
          const Divider(),
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) => SwitchListTile(
              title: const Text('Dark Mode'),
              secondary: Icon(
                themeProvider.isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                color: themeProvider.isDarkMode ? Colors.amber : Colors.orange,
              ),
              value: themeProvider.isDarkMode,
              onChanged: (val) => themeProvider.toggleTheme(val),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummarySection(TransactionProvider tp) {
    return SizedBox(
      height: 210,
      child: PageView(
        controller: PageController(viewportFraction: 0.95),
        children: [
          _buildMonthlySummaryCard(tp.transactions),
          _buildSummaryCard(
            'Total Balance', 
            tp.balance, 
            tp.totalIncome, 
            tp.totalExpense,
            [AppColors.primary, AppColors.primary.withOpacity(0.8)],
            Icons.account_balance_wallet_rounded,
          ),
          _buildSummaryCard(
            'Cash Balance', 
            tp.cashBalance, 
            tp.transactions.where((t) => t.paymentMethod == PaymentMethod.cash && t.type == TransactionType.income).fold(0.0, (sum, t) => sum + t.amount), 
            tp.transactions.where((t) => t.paymentMethod == PaymentMethod.cash && t.type == TransactionType.expense).fold(0.0, (sum, t) => sum + t.amount),
            [Colors.orange, Colors.orangeAccent],
            Icons.money_rounded,
            paymentMethod: PaymentMethod.cash,
          ),
          _buildSummaryCard(
            'Account Balance', 
            tp.accountBalance, 
            tp.transactions.where((t) => t.paymentMethod == PaymentMethod.account && t.type == TransactionType.income).fold(0.0, (sum, t) => sum + t.amount), 
            tp.transactions.where((t) => t.paymentMethod == PaymentMethod.account && t.type == TransactionType.expense).fold(0.0, (sum, t) => sum + t.amount),
            [Colors.blue, Colors.blueAccent],
            Icons.account_balance_rounded,
            paymentMethod: PaymentMethod.account,
          ),
          Consumer<DebtProvider>(
            builder: (context, dp, child) => _buildSummaryCard(
              'Net Debt Position', 
              dp.totalToGet - dp.totalToGive, 
              dp.totalToGet, 
              dp.totalToGive,
              [Colors.grey[800]!, Colors.black],
              Icons.handshake_rounded,
              isDebt: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpendingOverviewHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('Spending Overview', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold)),
        if (_selectedFilter == 'Custom' && _customRange != null)
          Text(
            '${_customRange!.start.day}/${_customRange!.start.month} - ${_customRange!.end.day}/${_customRange!.end.month}',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
      ],
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: ['Day', 'Monthly', 'Yearly', 'Custom'].map((filter) {
          final isSelected = _selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 10.0),
            child: ChoiceChip(
              label: Text(filter),
              selected: isSelected,
              onSelected: (val) async {
                if (filter == 'Custom' && val) {
                  final range = await showDateRangePicker(
                    context: context, 
                    firstDate: DateTime(2000), 
                    lastDate: DateTime.now(),
                    initialDateRange: _customRange,
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: ColorScheme.light(
                            primary: AppColors.primary,
                            onPrimary: Colors.white,
                            onSurface: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black,
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (range != null) {
                    setState(() {
                      _customRange = range;
                      _selectedFilter = filter;
                    });
                  }
                } else {
                  setState(() => _selectedFilter = filter);
                }
              },
              selectedColor: AppColors.primary,
              backgroundColor: Theme.of(context).cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isSelected ? AppColors.primary : Colors.grey.withOpacity(0.1),
                ),
              ),
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[600], 
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              elevation: isSelected ? 4 : 0,
              showCheckmark: false,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildQuickStatsData(List<TransactionModel> transactions) {
    if (transactions.isEmpty) return const SizedBox.shrink();
    
    var expenses = transactions.where((t) => t.type == TransactionType.expense).toList();
    if (expenses.isEmpty) return const SizedBox.shrink();

    // Get all unique categories in this period that have expenses
    final availableCategories = ['All', ...expenses.map((t) => t.category).toSet().toList()];

    // Ensure the selected category still exists in the dropdown, otherwise reset to All
    if (!availableCategories.contains(_selectedAverageCategory)) {
      // Don't setState here during build, just override locally
      _selectedAverageCategory = 'All';
    }

    if (_selectedAverageCategory != 'All') {
      expenses = expenses.where((t) => t.category == _selectedAverageCategory).toList();
    }
    
    final categoryExpense = expenses.fold(0.0, (sum, t) => sum + t.amount);

    double average = 0;
    String label = '';

    if (_selectedFilter == 'Monthly' || _selectedFilter == 'Custom') {
      int days = DateTime.now().day; // roughly defaults to month-to-date
      if (_selectedFilter == 'Custom' && _customRange != null) {
        days = _customRange!.end.difference(_customRange!.start).inDays + 1;
      }
      average = days > 0 ? (categoryExpense / days) : categoryExpense;
      label = 'Daily Avg';
    } else if (_selectedFilter == 'Yearly') {
      int months = DateTime.now().month;
      average = months > 0 ? (categoryExpense / months) : categoryExpense;
      label = 'Monthly Avg';
    }

    if (average == 0 && categoryExpense == 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildCategoryDropdown(availableCategories),
          Container(width: 1, height: 30, color: Colors.grey.withOpacity(0.2)),
          _buildMiniStat(label, '₹${average.toStringAsFixed(0)}', Icons.calculate_rounded, AppColors.primary),
        ],
      ),
    );
  }

  Widget _buildCategoryDropdown(List<String> categories) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), shape: BoxShape.circle),
          child: const Icon(Icons.category_rounded, size: 16, color: Colors.orange),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Filter By', style: TextStyle(fontSize: 11, color: Colors.grey)),
            SizedBox(
              height: 24,
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isDense: true,
                  value: _selectedAverageCategory,
                  icon: const Icon(Icons.arrow_drop_down_rounded, size: 20, color: Colors.grey),
                  items: categories.map((cat) => DropdownMenuItem(
                    value: cat,
                    child: Text(cat, style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold)),
                  )).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                         _selectedAverageCategory = val;
                      });
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMiniStat(String label, String value, IconData icon, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
            Text(value, style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }


  Widget _buildBudgetSection(TransactionProvider tp) {
    final categoriesWithBudgets = TransactionCategory.categories.where((cat) {
      return tp.getBudgetAmount(cat.name, _summaryMonth.month, _summaryMonth.year) > 0;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Monthly Budget', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold)),
                Text('Spending limits by category', style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey)),
              ],
            ),
            TextButton.icon(
              onPressed: () => _showSetBudgetDialog(tp),
              icon: const Icon(Icons.tune_rounded, size: 18),
              label: Text('Adjust', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (categoriesWithBudgets.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.withOpacity(0.1)),
            ),
            child: Column(
              children: [
                Icon(Icons.pie_chart_outline_rounded, size: 48, color: Colors.grey.withOpacity(0.3)),
                const SizedBox(height: 12),
                Text('No budgets set for this month', style: GoogleFonts.outfit(color: Colors.grey)),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => _showSetBudgetDialog(tp),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Start Budgeting'),
                ),
              ],
            ),
          )
        else
          ...categoriesWithBudgets.map((cat) {
            final progress = tp.getBudgetProgress(cat.name, _summaryMonth.month, _summaryMonth.year);
            final spending = tp.getCategorySpending(cat.name, _summaryMonth.month, _summaryMonth.year);
            final budget = tp.getBudgetAmount(cat.name, _summaryMonth.month, _summaryMonth.year);
            final isOverBudget = progress >= 1.0;
            final percent = (progress * 100).clamp(0.0, 100.0).toInt();

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isOverBudget ? Colors.red.withOpacity(0.2) : Colors.transparent),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: cat.color.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(cat.icon, size: 16, color: cat.color),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(cat.name, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15)),
                            Text(
                              isOverBudget ? 'Budget Exceeded!' : '${100 - percent}% remaining',
                              style: TextStyle(color: isOverBudget ? Colors.red : Colors.grey, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => _showDeleteBudgetConfirm(tp, cat.name),
                        icon: Icon(Icons.delete_outline_rounded, size: 18, color: Colors.grey[400]),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '₹${spending.toStringAsFixed(0)}',
                            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          Text(
                            'of ₹${budget.toStringAsFixed(0)}',
                            style: const TextStyle(color: Colors.grey, fontSize: 11),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Stack(
                    children: [
                      Container(
                        height: 8,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      LayoutBuilder(
                        builder: (context, constraints) => Container(
                          height: 8,
                          width: constraints.maxWidth * (progress.clamp(0.0, 1.0)),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isOverBudget 
                                ? [Colors.red, Colors.redAccent] 
                                : [AppColors.primary, const Color(0xFF6366F1)],
                            ),
                            borderRadius: BorderRadius.circular(4),
                            boxShadow: [
                              BoxShadow(
                                color: (isOverBudget ? Colors.red : AppColors.primary).withOpacity(0.3),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              )
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  void _showDeleteBudgetConfirm(TransactionProvider tp, String category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Remove Budget', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to remove the budget for $category for ${DateFormat('MMMM yyyy').format(_summaryMonth)}?', 
          style: GoogleFonts.outfit()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.outfit(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              await tp.deleteBudget(category, _summaryMonth.month, _summaryMonth.year);
              if (mounted) Navigator.pop(context);
            },
            child: Text('Remove', style: GoogleFonts.outfit(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showSetBudgetDialog(TransactionProvider tp) {
    String selectedCategory = TransactionCategory.categories.first.name;
    final amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Set Monthly Budget',
                  style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Set a limit for this category for ${DateFormat('MMMM yyyy').format(_summaryMonth)}.',
                  style: GoogleFonts.outfit(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(height: 24),
                
                // Category Selector
                Text('Category', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey[700])),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedCategory,
                      isExpanded: true,
                      items: TransactionCategory.categories.map((c) => 
                        DropdownMenuItem(
                          value: c.name, 
                          child: Row(
                            children: [
                              Icon(c.icon, size: 18, color: c.color),
                              const SizedBox(width: 12),
                              Text(c.name, style: GoogleFonts.outfit()),
                            ],
                          )
                        )).toList(),
                      onChanged: (val) => setDialogState(() => selectedCategory = val!),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                
                // Amount Input
                Text('Budget Amount', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey[700])),
                const SizedBox(height: 8),
                TextField(
                  controller: amountController,
                  autofocus: true,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.currency_rupee, size: 18),
                    hintText: '0.00',
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 32),
                
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text('Cancel', style: GoogleFonts.outfit(color: Colors.grey[600], fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          final amount = double.tryParse(amountController.text);
                          if (amount != null && amount > 0) {
                            tp.saveBudget(BudgetModel(
                              category: selectedCategory, 
                              amount: amount, 
                              month: _summaryMonth.month, 
                              year: _summaryMonth.year,
                            ));
                            Navigator.pop(context);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text('Set Budget', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMonthlySummaryCard(List<TransactionModel> transactions) {
    final monthly = transactions.where((t) => 
      t.date.month == _summaryMonth.month && t.date.year == _summaryMonth.year).toList();
    final income = monthly.where((t) => t.type == TransactionType.income).fold(0.0, (sum, t) => sum + t.amount);
    final expense = monthly.where((t) => t.type == TransactionType.expense).fold(0.0, (sum, t) => sum + t.amount);
    final balance = income - expense;
    final monthName = DateFormat('MMMM yyyy').format(_summaryMonth);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)]),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: const Color(0xFF10B981).withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '$monthName Balance', 
                  style: GoogleFonts.outfit(color: Colors.white70, fontSize: 16),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left, color: Colors.white, size: 20),
                    onPressed: () {
                      setState(() => _summaryMonth = DateTime(_summaryMonth.year, _summaryMonth.month - 1));
                      _refreshData();
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right, color: Colors.white, size: 20),
                    onPressed: () {
                      final next = DateTime(_summaryMonth.year, _summaryMonth.month + 1);
                      if (next.isBefore(DateTime.now()) || (next.month == DateTime.now().month && next.year == DateTime.now().year)) {
                        setState(() => _summaryMonth = next);
                        _refreshData();
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
          Text('₹${balance.toStringAsFixed(2)}', style: GoogleFonts.outfit(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
          const Spacer(),
          Row(
            children: [
              _buildStat(
                'Income', 
                '₹${income.toStringAsFixed(0)}', 
                Icons.arrow_upward,
                onTap: () => Navigator.push(context, MaterialPageRoute(
                  builder: (context) => TransactionHistoryScreen(
                    initialType: TransactionType.income,
                    initialMonth: _summaryMonth.month,
                    initialYear: _summaryMonth.year,
                  ),
                )),
              ),
              const Spacer(),
              _buildStat(
                'Expenses', 
                '₹${expense.toStringAsFixed(0)}', 
                Icons.arrow_downward,
                onTap: () => Navigator.push(context, MaterialPageRoute(
                  builder: (context) => TransactionHistoryScreen(
                    initialType: TransactionType.expense,
                    initialMonth: _summaryMonth.month,
                    initialYear: _summaryMonth.year,
                  ),
                )),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, double balance, double income, double expense, List<Color> colors, IconData icon, {
    PaymentMethod? paymentMethod,
    bool isDebt = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: colors.first.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: GoogleFonts.outfit(color: Colors.white70, fontSize: 16)),
              Icon(icon, color: Colors.white.withOpacity(0.5), size: 24),
            ],
          ),
          const SizedBox(height: 4),
          Text('₹${balance.toStringAsFixed(2)}', style: GoogleFonts.outfit(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
          const Spacer(),
          Row(
            children: [
              _buildStat(
                isDebt ? 'To Get' : (paymentMethod != null ? 'Income' : 'Monthly Income'), 
                '₹${income.toStringAsFixed(0)}', 
                Icons.arrow_upward,
                onTap: isDebt ? null : () => Navigator.push(context, MaterialPageRoute(
                  builder: (context) => TransactionHistoryScreen(
                    initialType: TransactionType.income,
                    initialPaymentMethod: paymentMethod,
                  ),
                )),
              ),
              const Spacer(),
              _buildStat(
                isDebt ? 'To Give' : (paymentMethod != null ? 'Expenses' : 'Monthly Expenses'), 
                '₹${expense.toStringAsFixed(0)}', 
                Icons.arrow_downward,
                onTap: isDebt ? null : () => Navigator.push(context, MaterialPageRoute(
                  builder: (context) => TransactionHistoryScreen(
                    initialType: TransactionType.expense,
                    initialPaymentMethod: paymentMethod,
                  ),
                )),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value, IconData icon, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
            child: Icon(icon, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: GoogleFonts.outfit(color: Colors.white70, fontSize: 12)),
              Text(value, style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTransactionsHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('Recent Transactions', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold)),
        TextButton(
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const TransactionHistoryScreen())),
          child: const Text('See All'),
        ),
      ],
    );
  }

  Widget _buildRecentTransactionsList(TransactionProvider tp, AuthProvider auth) {
    final recent = tp.transactions.take(5).toList();
    if (recent.isEmpty) return const Center(child: Padding(padding: EdgeInsets.all(20), child: Text("No transactions yet!")));
    
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: recent.length,
      itemBuilder: (context, index) {
        final t = recent[index];
        final isTransfer = t.type == TransactionType.transfer;
        final category = isTransfer ? TransactionCategory.categories.firstWhere((c) => c.name == 'Others') : TransactionCategory.getByName(t.category);
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isTransfer ? Colors.blue.withOpacity(0.1) : category.color.withOpacity(0.1),
              child: Icon(
                isTransfer ? Icons.swap_horiz_rounded : category.icon, 
                color: isTransfer ? Colors.blue : category.color, 
                size: 18
              ),
            ),
            title: Text(
              isTransfer ? 'Transfer: ${t.paymentMethod.name.toUpperCase()} → ${t.toPaymentMethod?.name.toUpperCase()}' : t.title, 
              style: const TextStyle(fontWeight: FontWeight.w600)
            ),
            subtitle: Row(
              children: [
                Text(isTransfer ? 'Internal Transfer' : category.name),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: t.paymentMethod == PaymentMethod.cash ? Colors.orange.withOpacity(0.1) : Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    t.paymentMethod.name.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10, 
                      fontWeight: FontWeight.bold,
                      color: t.paymentMethod == PaymentMethod.cash ? Colors.orange : Colors.blue,
                    ),
                  ),
                ),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${t.type == TransactionType.income ? '+' : (t.type == TransactionType.expense ? '-' : '')} ₹${t.amount.toStringAsFixed(0)}',
                  style: TextStyle(
                    color: t.type == TransactionType.income ? AppColors.income : (t.type == TransactionType.expense ? AppColors.expense : Colors.blue),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text('${t.date.day}/${t.date.month}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
        );
      },
    );
  }
}
