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

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedFilter = 'Monthly';
  DateTimeRange? _customRange;
  DateTime _summaryMonth = DateTime.now();

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

  List<TransactionModel> _getFilteredTransactions(List<TransactionModel> transactions) {
    final now = DateTime.now();
    switch (_selectedFilter) {
      case 'Day':
        return transactions.where((t) => 
          t.date.day == now.day && t.date.month == now.month && t.date.year == now.year).toList();
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
            Text('Welcome back,', style: GoogleFonts.outfit(fontSize: 14, color: Colors.grey)),
            Text(auth.user?.name ?? 'User', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
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
              const SizedBox(height: 20),
              _buildSummarySection(tp),
              const SizedBox(height: 20),
              _buildSpendingOverviewHeader(),
              const SizedBox(height: 12),
              _buildFilterChips(),
              const SizedBox(height: 20),
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
      child: Row(
        children: ['Day', 'Monthly', 'Yearly', 'Custom'].map((filter) {
          final isSelected = _selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
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
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Theme.of(context).textTheme.bodyMedium?.color, 
                fontSize: 13,
              ),
              showCheckmark: false,
            ),
          );
        }).toList(),
      ),
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
            Text('Budgets', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold)),
            IconButton(
              icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
              onPressed: () => _showSetBudgetDialog(tp),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (categoriesWithBudgets.isEmpty)
          Center(
            child: TextButton(
              onPressed: () => _showSetBudgetDialog(tp),
              child: const Text('Set up your first budget'),
            ),
          )
        else
          ...categoriesWithBudgets.map((cat) {
            final progress = tp.getBudgetProgress(cat.name, _summaryMonth.month, _summaryMonth.year);
            final spending = tp.getCategorySpending(cat.name, _summaryMonth.month, _summaryMonth.year);
            final budget = tp.getBudgetAmount(cat.name, _summaryMonth.month, _summaryMonth.year);
            final isOverBudget = progress >= 1.0;

            return Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(cat.icon, size: 16, color: cat.color),
                          const SizedBox(width: 8),
                          Text(cat.name, style: const TextStyle(fontWeight: FontWeight.w500)),
                        ],
                      ),
                      Text(
                        '₹${spending.toStringAsFixed(0)} / ₹${budget.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 12, 
                          color: isOverBudget ? Colors.red : Colors.grey,
                          fontWeight: isOverBudget ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 8,
                      backgroundColor: Colors.grey.withOpacity(0.1),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isOverBudget ? Colors.red : AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
      ],
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

  Widget _buildSummaryCard(String title, double balance, double income, double expense, List<Color> colors, IconData icon, {PaymentMethod? paymentMethod}) {
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
                'Income', 
                '₹${income.toStringAsFixed(0)}', 
                Icons.arrow_upward,
                onTap: () => Navigator.push(context, MaterialPageRoute(
                  builder: (context) => TransactionHistoryScreen(
                    initialType: TransactionType.income,
                    initialPaymentMethod: paymentMethod,
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
