import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../core/app_colors.dart';
import '../../core/constants.dart';
import '../../data/models/budget_model.dart';
import '../../data/models/transaction_model.dart';
import '../providers/transaction_provider.dart';

class BudgetManagerScreen extends StatefulWidget {
  const BudgetManagerScreen({super.key});

  @override
  State<BudgetManagerScreen> createState() => _BudgetManagerScreenState();
}

class _BudgetManagerScreenState extends State<BudgetManagerScreen> {
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshBudgets();
    });
  }

  void _refreshBudgets() {
    Provider.of<TransactionProvider>(context, listen: false)
        .fetchBudgets(_selectedDate.month, _selectedDate.year);
  }

  void _showAdjustBudgetSheet(TransactionProvider tp, String categoryName, double currentBudget) {
    final amountController = TextEditingController(
      text: currentBudget > 0 ? currentBudget.toStringAsFixed(0) : '',
    );
    double sliderValue = currentBudget > 0 ? currentBudget.clamp(0.0, 50000.0) : 0.0;
    final cat = TransactionCategory.getByName(categoryName);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            top: 24,
            left: 24,
            right: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: cat.color.withOpacity(0.1), shape: BoxShape.circle),
                    child: Icon(cat.icon, color: cat.color, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Set Budget for ${cat.name}',
                    style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Budget Amount (₹)',
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey[700]),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                autofocus: true,
                style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.currency_rupee, size: 20),
                  hintText: '0.00',
                  filled: true,
                  fillColor: Colors.grey.withOpacity(0.05),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                onChanged: (val) {
                  final parsed = double.tryParse(val) ?? 0.0;
                  setSheetState(() {
                    sliderValue = parsed.clamp(0.0, 50000.0);
                  });
                },
              ),
              const SizedBox(height: 24),
              
              // Slider for quick editing
              Slider.adaptive(
                value: sliderValue,
                min: 0.0,
                max: 50000.0,
                divisions: 100,
                activeColor: cat.color,
                inactiveColor: cat.color.withOpacity(0.15),
                label: '₹${sliderValue.toStringAsFixed(0)}',
                onChanged: (val) {
                  setSheetState(() {
                    sliderValue = val;
                    amountController.text = val.toStringAsFixed(0);
                  });
                },
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('₹0', style: GoogleFonts.outfit(color: Colors.grey, fontSize: 11)),
                  Text('₹50k+', style: GoogleFonts.outfit(color: Colors.grey, fontSize: 11)),
                ],
              ),
              const SizedBox(height: 32),

              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Cancel', style: GoogleFonts.outfit(color: Colors.grey, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        final amount = double.tryParse(amountController.text) ?? 0.0;
                        if (amount >= 0) {
                          if (amount == 0) {
                            await tp.deleteBudget(categoryName, _selectedDate.month, _selectedDate.year);
                          } else {
                            await tp.saveBudget(BudgetModel(
                              category: categoryName,
                              amount: amount,
                              month: _selectedDate.month,
                              year: _selectedDate.year,
                            ));
                          }
                          if (mounted) Navigator.pop(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text('Save Budget', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleCopyLastMonth(TransactionProvider tp) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Copy Last Month\'s Budgets', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Text('This will overwrite any budgets set for the current month. Continue?', style: GoogleFonts.outfit()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.outfit(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await tp.copyBudgetsFromPreviousMonth(_selectedDate.month, _selectedDate.year);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Budgets copied successfully!')),
                );
              }
            },
            child: Text('Copy', style: GoogleFonts.outfit(color: AppColors.primary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tp = Provider.of<TransactionProvider>(context);
    final monthLabel = DateFormat('MMMM yyyy').format(_selectedDate);

    // Calculate total limits and spending
    final double totalBudget = tp.budgets.fold(0.0, (sum, b) => sum + b.amount);
    final double totalSpending = TransactionCategory.categories
        .where((c) => c.name != 'Salary')
        .fold(0.0, (sum, c) => sum + tp.getCategorySpending(c.name, _selectedDate.month, _selectedDate.year));

    final double overallProgress = totalBudget > 0 ? (totalSpending / totalBudget).clamp(0.0, 1.0) : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: Text('Budget Manager', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date Switcher Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () {
                    setState(() {
                      _selectedDate = DateTime(_selectedDate.year, _selectedDate.month - 1);
                      _refreshBudgets();
                    });
                  },
                ),
                Text(
                  monthLabel,
                  style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () {
                    setState(() {
                      _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + 1);
                      _refreshBudgets();
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Overall Summary Card (Circular progress indicator or Allocation Ring)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppColors.primary, Color(0xFF4F46E5)]),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Overall Allocation', style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13)),
                        const SizedBox(height: 6),
                        Text(
                          '₹${totalSpending.toStringAsFixed(0)} / ₹${totalBudget.toStringAsFixed(0)}',
                          style: GoogleFonts.outfit(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          totalBudget > 0
                              ? '${(overallProgress * 100).toStringAsFixed(0)}% of monthly budget spent'
                              : 'No budgets allocated yet',
                          style: GoogleFonts.outfit(color: Colors.white70, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  
                  // Radial progress style indicator
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 70,
                        height: 70,
                        child: CircularProgressIndicator(
                          value: overallProgress,
                          backgroundColor: Colors.white24,
                          color: Colors.white,
                          strokeWidth: 8,
                        ),
                      ),
                      Text(
                        '${(overallProgress * 100).toStringAsFixed(0)}%',
                        style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Action options (Copy from last month)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Category Budgets', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
                TextButton.icon(
                  onPressed: () => _handleCopyLastMonth(tp),
                  icon: const Icon(Icons.copy_rounded, size: 16),
                  label: Text('Copy Last Month', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 12)),
                  style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // List of category budgets
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: TransactionCategory.categories.where((c) => c.name != 'Salary').length,
              itemBuilder: (context, index) {
                final categories = TransactionCategory.categories.where((c) => c.name != 'Salary').toList();
                final cat = categories[index];
                
                final budgetAmount = tp.getBudgetAmount(cat.name, _selectedDate.month, _selectedDate.year);
                final spending = tp.getCategorySpending(cat.name, _selectedDate.month, _selectedDate.year);
                final progress = tp.getBudgetProgress(cat.name, _selectedDate.month, _selectedDate.year);
                final isOver = progress >= 1.0;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => _showAdjustBudgetSheet(tp, cat.name, budgetAmount),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(color: cat.color.withOpacity(0.1), shape: BoxShape.circle),
                                child: Icon(cat.icon, color: cat.color, size: 16),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(cat.name, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15)),
                                    Text(
                                      budgetAmount > 0
                                          ? 'Spent ₹${spending.toStringAsFixed(0)}'
                                          : 'No budget set',
                                      style: GoogleFonts.outfit(fontSize: 11, color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    budgetAmount > 0 ? '₹${budgetAmount.toStringAsFixed(0)}' : 'Set Limit',
                                    style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: budgetAmount > 0 ? Colors.black : AppColors.primary,
                                    ),
                                  ),
                                  if (budgetAmount > 0)
                                    Text(
                                      isOver ? 'Exceeded!' : '${((1 - progress) * 100).toInt()}% left',
                                      style: GoogleFonts.outfit(
                                        fontSize: 10,
                                        color: isOver ? Colors.red : Colors.grey,
                                        fontWeight: isOver ? FontWeight.bold : FontWeight.normal,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(width: 8),
                              Icon(Icons.chevron_right, size: 18, color: Colors.grey[400]),
                            ],
                          ),
                          if (budgetAmount > 0) ...[
                            const SizedBox(height: 12),
                            Stack(
                              children: [
                                Container(
                                  height: 6,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                                LayoutBuilder(
                                  builder: (context, constraints) => Container(
                                    height: 6,
                                    width: constraints.maxWidth * progress,
                                    decoration: BoxDecoration(
                                      color: isOver ? Colors.red : cat.color,
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
