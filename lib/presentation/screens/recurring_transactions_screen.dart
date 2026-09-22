import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../core/app_colors.dart';
import '../../core/constants.dart';
import '../../data/models/recurring_transaction_model.dart';
import '../../data/models/transaction_model.dart';
import '../providers/transaction_provider.dart';

class RecurringTransactionsScreen extends StatefulWidget {
  const RecurringTransactionsScreen({super.key});

  @override
  State<RecurringTransactionsScreen> createState() => _RecurringTransactionsScreenState();
}

class _RecurringTransactionsScreenState extends State<RecurringTransactionsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TransactionProvider>(context, listen: false).fetchRecurringTransactions();
    });
  }

  void _showAddRecurringDialog() {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    TransactionType selectedType = TransactionType.expense;
    String selectedCategory = TransactionCategory.categories.first.name;
    RecurrenceFrequency selectedFrequency = RecurrenceFrequency.monthly;
    PaymentMethod selectedPaymentMethod = PaymentMethod.account;
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Add Subscription / Recurring',
                    style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  // Income vs Expense Segment
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(child: Text('Expense')),
                          selected: selectedType == TransactionType.expense,
                          onSelected: (val) {
                            if (val) {
                              setDialogState(() {
                                selectedType = TransactionType.expense;
                                selectedCategory = TransactionCategory.categories.first.name;
                              });
                            }
                          },
                          selectedColor: AppColors.expense,
                          labelStyle: TextStyle(
                            color: selectedType == TransactionType.expense ? Colors.white : Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(child: Text('Income')),
                          selected: selectedType == TransactionType.income,
                          onSelected: (val) {
                            if (val) {
                              setDialogState(() {
                                selectedType = TransactionType.income;
                                selectedCategory = 'Salary';
                              });
                            }
                          },
                          selectedColor: AppColors.income,
                          labelStyle: TextStyle(
                            color: selectedType == TransactionType.income ? Colors.white : Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Title
                  Text('Title', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey[700])),
                  const SizedBox(height: 6),
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      hintText: 'e.g., Netflix subscription, Rent',
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Amount
                  Text('Amount (₹)', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey[700])),
                  const SizedBox(height: 6),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: '0.00',
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      prefixIcon: const Icon(Icons.currency_rupee, size: 16),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Category (Only for expenses)
                  if (selectedType == TransactionType.expense) ...[
                    Text('Category', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey[700])),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedCategory,
                          isExpanded: true,
                          items: TransactionCategory.categories.where((c) => c.name != 'Salary').map((c) => 
                            DropdownMenuItem(
                              value: c.name,
                              child: Row(
                                children: [
                                  Icon(c.icon, size: 18, color: c.color),
                                  const SizedBox(width: 10),
                                  Text(c.name, style: GoogleFonts.outfit()),
                                ],
                              ),
                            )
                          ).toList(),
                          onChanged: (val) => setDialogState(() => selectedCategory = val!),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Frequency
                  Text('Frequency', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey[700])),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<RecurrenceFrequency>(
                        value: selectedFrequency,
                        isExpanded: true,
                        items: RecurrenceFrequency.values.map((f) => 
                          DropdownMenuItem(
                            value: f,
                            child: Text(f.name.toUpperCase(), style: GoogleFonts.outfit()),
                          )
                        ).toList(),
                        onChanged: (val) => setDialogState(() => selectedFrequency = val!),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Payment Method
                  Text('Payment Account', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey[700])),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<PaymentMethod>(
                        value: selectedPaymentMethod,
                        isExpanded: true,
                        items: PaymentMethod.values.map((m) => 
                          DropdownMenuItem(
                            value: m,
                            child: Text(m.name.toUpperCase(), style: GoogleFonts.outfit()),
                          )
                        ).toList(),
                        onChanged: (val) => setDialogState(() => selectedPaymentMethod = val!),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Start Date Picker
                  Text('Start Date', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey[700])),
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) {
                        setDialogState(() => selectedDate = picked);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(DateFormat('dd MMMM yyyy').format(selectedDate), style: GoogleFonts.outfit()),
                          const Icon(Icons.calendar_today, size: 16, color: AppColors.primary),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Buttons
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text('Cancel', style: GoogleFonts.outfit(color: Colors.grey)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            final title = titleController.text.trim();
                            final amount = double.tryParse(amountController.text) ?? 0.0;
                            if (title.isEmpty || amount <= 0) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please fill valid inputs')),
                              );
                              return;
                            }

                            final id = const Uuid().v4();
                            final recurring = RecurringTransactionModel(
                              id: id,
                              title: title,
                              amount: amount,
                              category: selectedType == TransactionType.income ? 'Salary' : selectedCategory,
                              type: selectedType,
                              startDate: selectedDate,
                              frequency: selectedFrequency,
                              lastExecutedDate: selectedDate.subtract(const Duration(minutes: 1)), // execute first occurrence immediately if start date is today
                              paymentMethod: selectedPaymentMethod,
                            );

                            Provider.of<TransactionProvider>(context, listen: false)
                                .addRecurringTransaction(recurring);
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text('Save', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tp = Provider.of<TransactionProvider>(context);
    final recurrings = tp.recurringTransactions;

    return Scaffold(
      appBar: AppBar(
        title: Text('Subscriptions & Recurring', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
      ),
      body: recurrings.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.autorenew_rounded, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    'No recurring transactions set up.',
                    style: GoogleFonts.outfit(color: Colors.grey, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Automatically log your regular expenses.',
                    style: GoogleFonts.outfit(color: Colors.grey[400], fontSize: 12),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              itemCount: recurrings.length,
              itemBuilder: (context, index) {
                final rec = recurrings[index];
                final cat = TransactionCategory.getByName(rec.category);

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: rec.type == TransactionType.income
                                  ? AppColors.income.withOpacity(0.1)
                                  : cat.color.withOpacity(0.1),
                              child: Icon(
                                rec.type == TransactionType.income ? Icons.payments : cat.icon,
                                color: rec.type == TransactionType.income ? AppColors.income : cat.color,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    rec.title,
                                    style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    '${rec.frequency.name.toUpperCase()} • ${rec.paymentMethod.name.toUpperCase()}',
                                    style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey[500]),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${rec.type == TransactionType.income ? '+' : '-'} ₹${rec.amount.toStringAsFixed(0)}',
                                  style: GoogleFonts.outfit(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: rec.type == TransactionType.income
                                        ? AppColors.income
                                        : AppColors.expense,
                                  ),
                                ),
                                Switch.adaptive(
                                  value: rec.isActive,
                                  activeColor: AppColors.primary,
                                  onChanged: (val) {
                                    tp.toggleRecurringTransaction(rec);
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Next Execution',
                                  style: GoogleFonts.outfit(fontSize: 10, color: Colors.grey[400]),
                                ),
                                Text(
                                  DateFormat('dd MMMM yyyy').format(
                                    rec.lastExecutedDate.isBefore(rec.startDate)
                                        ? rec.startDate
                                        : _calculateNextDate(rec.lastExecutedDate, rec.frequency),
                                  ),
                                  style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, color: Colors.grey),
                              onPressed: () {
                                _showDeleteConfirmation(tp, rec.id);
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddRecurringDialog,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showDeleteConfirmation(TransactionProvider tp, String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Subscription', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to delete this recurring transaction?', style: GoogleFonts.outfit()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.outfit(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              tp.deleteRecurringTransaction(id);
              Navigator.pop(context);
            },
            child: Text('Delete', style: GoogleFonts.outfit(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  DateTime _calculateNextDate(DateTime from, RecurrenceFrequency frequency) {
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
        return DateTime(nextYear, nextMonth, day);
      case RecurrenceFrequency.yearly:
        return DateTime(from.year + 1, from.month, from.day);
    }
  }
}
