import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../core/constants.dart';
import '../../data/models/transaction_model.dart';
import '../providers/transaction_provider.dart';
import '../providers/auth_provider.dart';
import '../screens/add_expense_screen.dart';

class QuickAddBottomSheet extends StatefulWidget {
  const QuickAddBottomSheet({super.key});

  @override
  State<QuickAddBottomSheet> createState() => _QuickAddBottomSheetState();
}

class _QuickAddBottomSheetState extends State<QuickAddBottomSheet> {
  final _quickInputController = TextEditingController();
  final _amountController = TextEditingController();

  String _selectedCategory = 'Food';
  TransactionType _selectedType = TransactionType.expense;
  PaymentMethod _selectedMethod = PaymentMethod.account;

  // Parsed quick transaction representation (if parsed successfully)
  TransactionModel? _parsedTransaction;
  String? _parseError;

  @override
  void dispose() {
    _quickInputController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _parseText(String text, String userId, TransactionProvider tp) {
    if (text.trim().isEmpty) {
      setState(() {
        _parsedTransaction = null;
        _parseError = null;
      });
      return;
    }

    final parsed = tp.parseQuickInput(text, userId);
    setState(() {
      if (parsed != null) {
        _parsedTransaction = parsed;
        _parseError = null;
        // Populate standard inputs with parsed values for backup
        _amountController.text = parsed.amount.toStringAsFixed(0);
        _selectedCategory = parsed.category;
        _selectedType = parsed.type;
      } else {
        _parsedTransaction = null;
        _parseError = "Couldn't extract amount (e.g. try: '250 food')";
      }
    });
  }

  void _saveTransaction(TransactionProvider tp, AuthProvider auth) async {
    final uid = auth.user?.uid ?? '';
    TransactionModel transaction;

    if (_parsedTransaction != null) {
      transaction = TransactionModel(
        id: '',
        userId: uid,
        title: _parsedTransaction!.title,
        amount: _parsedTransaction!.amount,
        category: _parsedTransaction!.category,
        type: _parsedTransaction!.type,
        date: DateTime.now(),
        paymentMethod: _selectedMethod,
      );
    } else {
      final amount = double.tryParse(_amountController.text) ?? 0.0;
      if (amount <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid amount')),
        );
        return;
      }

      transaction = TransactionModel(
        id: '',
        userId: uid,
        title: 'Quick $_selectedCategory',
        amount: amount,
        category: _selectedCategory,
        type: _selectedType,
        date: DateTime.now(),
        paymentMethod: _selectedMethod,
      );
    }

    try {
      await tp.addTransaction(transaction);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added: Rs. ${transaction.amount.toStringAsFixed(0)} for ${transaction.category}!'),
            action: SnackBarAction(
              label: 'Undo',
              textColor: Colors.white,
              onPressed: () async {
                // If undone, remove last added transaction
                if (tp.transactions.isNotEmpty) {
                  await tp.deleteTransaction(uid, tp.transactions.first.id);
                }
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tp = Provider.of<TransactionProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final uid = auth.user?.uid ?? '';

    return Container(
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
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Quick Add Transaction',
                  style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const AddExpenseScreen()));
                  },
                  child: Text(
                    'More details...',
                    style: GoogleFonts.outfit(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // AI Natural Language Input
            Text(
              'AI Quick Log (Type or speak)',
              style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[700]),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _quickInputController,
              decoration: InputDecoration(
                hintText: 'Try: "150 food", "salary 50000", "200 travel"...',
                hintStyle: const TextStyle(fontSize: 13),
                filled: true,
                fillColor: Colors.grey.withOpacity(0.05),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                prefixIcon: const Icon(Icons.psychology, color: AppColors.primary, size: 20),
                suffixIcon: _quickInputController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _quickInputController.clear();
                          _parseText('', uid, tp);
                        },
                      )
                    : null,
              ),
              onChanged: (val) => _parseText(val, uid, tp),
            ),
            
            if (_parseError != null) ...[
              const SizedBox(height: 6),
              Text(_parseError!, style: const TextStyle(color: Colors.red, fontSize: 10)),
            ],

            // Display Parsed Result Card if matching
            if (_parsedTransaction != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: _parsedTransaction!.type == TransactionType.income ? const Color(0xFF10B981).withOpacity(0.1) : const Color(0xFFEF4444).withOpacity(0.1),
                      child: Icon(
                        _parsedTransaction!.type == TransactionType.income ? Icons.arrow_upward : Icons.arrow_downward,
                        color: _parsedTransaction!.type == TransactionType.income ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _parsedTransaction!.title,
                            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          Text(
                            'Category: ${_parsedTransaction!.category}',
                            style: const TextStyle(fontSize: 10, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      'Rs. ${_parsedTransaction!.amount.toStringAsFixed(0)}',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15, color: _parsedTransaction!.type == TransactionType.income ? const Color(0xFF10B981) : const Color(0xFFEF4444)),
                    ),
                  ],
                ),
              ),
            ],

            const Divider(height: 32),

            // MANUAL PANEL (Only focus if AI field is empty)
            if (_parsedTransaction == null) ...[
              // Transaction type Toggle (Tabs)
              Row(
                children: [
                  _buildTypeTab(TransactionType.expense, 'Expense', const Color(0xFFEF4444)),
                  const SizedBox(width: 12),
                  _buildTypeTab(TransactionType.income, 'Income', const Color(0xFF10B981)),
                ],
              ),
              const SizedBox(height: 16),

              // Amount Input + Presets Row
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: 'Enter amount...',
                        filled: true,
                        fillColor: Colors.grey.withOpacity(0.05),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        prefixIcon: const Icon(Icons.currency_rupee, size: 16),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              
              // Preset chips row
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [50, 100, 200, 500, 1000].map((val) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ActionChip(
                        label: Text('₹$val'),
                        backgroundColor: Colors.grey.withOpacity(0.05),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        onPressed: () {
                          setState(() {
                            _amountController.text = val.toString();
                          });
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 20),

              // Category Selector Horizontal
              Text(
                'Category',
                style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[700]),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 80,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _selectedType == TransactionType.income
                      ? 1
                      : TransactionCategory.categories.where((c) => c.name != 'Salary').length,
                  itemBuilder: (context, index) {
                    final categories = _selectedType == TransactionType.income
                        ? [TransactionCategory.categories.firstWhere((c) => c.name == 'Salary')]
                        : TransactionCategory.categories.where((c) => c.name != 'Salary').toList();
                    final cat = categories[index];
                    final isSelected = _selectedCategory == cat.name;

                    return Padding(
                      padding: const EdgeInsets.only(right: 12.0),
                      child: Column(
                        children: [
                          InkWell(
                            onTap: () {
                              setState(() {
                                _selectedCategory = cat.name;
                              });
                            },
                            customBorder: const CircleBorder(),
                            child: CircleAvatar(
                              radius: 24,
                              backgroundColor: isSelected ? cat.color : cat.color.withOpacity(0.1),
                              child: Icon(cat.icon, color: isSelected ? Colors.white : cat.color, size: 18),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(cat.name, style: GoogleFonts.outfit(fontSize: 10, color: isSelected ? Colors.black : Colors.grey, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],

            // Payment Account Toggle
            const SizedBox(height: 12),
            Text(
              'Account / Wallet',
              style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[700]),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildMethodChip(PaymentMethod.cash, 'Cash', Icons.money_rounded),
                const SizedBox(width: 12),
                _buildMethodChip(PaymentMethod.account, 'Card / Bank', Icons.credit_card_rounded),
              ],
            ),

            const SizedBox(height: 24),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () => _saveTransaction(tp, auth),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: Text(
                  _parsedTransaction != null ? 'Add AI Logged Transaction' : 'Save Transaction',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeTab(TransactionType type, String label, Color color) {
    final isSelected = _selectedType == type;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedType = type;
            _selectedCategory = type == TransactionType.income ? 'Salary' : 'Food';
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isSelected ? color : Colors.grey.withOpacity(0.3)),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.outfit(
              color: isSelected ? color : Colors.grey,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMethodChip(PaymentMethod method, String label, IconData icon) {
    final isSelected = _selectedMethod == method;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedMethod = method;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isSelected ? AppColors.primary : Colors.grey.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: isSelected ? AppColors.primary : Colors.grey),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.outfit(
                  color: isSelected ? AppColors.primary : Colors.grey,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
