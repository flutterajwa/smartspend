import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../core/app_colors.dart';
import '../../core/constants.dart';
import '../../data/models/transaction_model.dart';
import '../providers/auth_provider.dart';
import '../providers/transaction_provider.dart';

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  TransactionType _type = TransactionType.expense;
  PaymentMethod _paymentMethod = PaymentMethod.account;
  PaymentMethod _toPaymentMethod = PaymentMethod.cash;
  String _selectedCategory = 'Others';
  DateTime _selectedDate = DateTime.now();
  String? _amountError;

  @override
  void initState() {
    super.initState();
    _amountController.addListener(() {
      if (_amountError != null) setState(() => _amountError = null);
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  bool _isSaving = false;

  void _submit() async {
    if (_isSaving) return;

    final title = _type == TransactionType.transfer ? 'Transfer' : _titleController.text;
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    final userId = Provider.of<AuthProvider>(context, listen: false).user?.uid;

    if (amount <= 0 || userId == null || (_type != TransactionType.transfer && title.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter valid data')));
      return;
    }

    if (_type == TransactionType.transfer && _paymentMethod == _toPaymentMethod) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Source and Destination cannot be the same')));
       return;
    }

    final tp = Provider.of<TransactionProvider>(context, listen: false);
    final sourceBalance = _paymentMethod == PaymentMethod.cash ? tp.cashBalance : tp.accountBalance;

    if (_type != TransactionType.income && amount > sourceBalance) {
       setState(() => _amountError = 'Not enough money in ${_paymentMethod.name.toUpperCase()} (₹${sourceBalance.toStringAsFixed(0)})');
       return;
    }

    setState(() => _isSaving = true);

    try {
      final transaction = TransactionModel(
        id: '',
        userId: userId,
        title: title,
        amount: amount,
        category: _type == TransactionType.transfer ? 'Transfer' : (_type == TransactionType.expense ? _selectedCategory : 'Salary'),
        type: _type,
        date: _selectedDate,
        note: _noteController.text,
        paymentMethod: _paymentMethod,
        toPaymentMethod: _type == TransactionType.transfer ? _toPaymentMethod : null,
      );

      await Provider.of<TransactionProvider>(context, listen: false).addTransaction(transaction);
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Transaction added successfully!')));
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving transaction: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Add ${_getLabel(_type)}')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                 _typeButton(TransactionType.expense, 'Expense', AppColors.expense),
                 const SizedBox(width: 8),
                 _typeButton(TransactionType.income, 'Income', AppColors.income),
                 const SizedBox(width: 8),
                 _typeButton(TransactionType.transfer, 'Transfer', Colors.blue),
              ],
            ),
            const SizedBox(height: 32),
            if (_type != TransactionType.transfer) ...[
              _buildTextField(_titleController, 'Title', Icons.title, TextInputType.text),
              const SizedBox(height: 20),
            ],
            _buildTextField(_amountController, 'Amount (₹)', Icons.currency_rupee, TextInputType.number, errorText: _amountError),
            // Payment Method Selection
            if (_type != TransactionType.transfer) ...[
               const Text('Payment Method', style: TextStyle(fontWeight: FontWeight.bold)),
               const SizedBox(height: 12),
               Row(
                 children: [
                   _paymentMethodButton(PaymentMethod.cash, 'Cash', Icons.money, true),
                   const SizedBox(width: 16),
                   _paymentMethodButton(PaymentMethod.account, 'Account', Icons.account_balance, true),
                 ],
               ),
               const SizedBox(height: 20),
            ],

            if (_type == TransactionType.transfer) ...[
               const Text('Transfer To', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
               const SizedBox(height: 12),
               Row(
                 children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() {
                           _toPaymentMethod = PaymentMethod.cash;
                           _paymentMethod = PaymentMethod.account;
                        }),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: _toPaymentMethod == PaymentMethod.cash ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _toPaymentMethod == PaymentMethod.cash ? AppColors.primary : Colors.grey),
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.money, color: _toPaymentMethod == PaymentMethod.cash ? AppColors.primary : Colors.grey),
                              const SizedBox(height: 4),
                              Text('Cash', style: TextStyle(color: _toPaymentMethod == PaymentMethod.cash ? AppColors.primary : Colors.grey, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() {
                           _toPaymentMethod = PaymentMethod.account;
                           _paymentMethod = PaymentMethod.cash;
                        }),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: _toPaymentMethod == PaymentMethod.account ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _toPaymentMethod == PaymentMethod.account ? AppColors.primary : Colors.grey),
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.account_balance, color: _toPaymentMethod == PaymentMethod.account ? AppColors.primary : Colors.grey),
                              const SizedBox(height: 4),
                              Text('Account', style: TextStyle(color: _toPaymentMethod == PaymentMethod.account ? AppColors.primary : Colors.grey, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    ),
                 ],
               ),
               const SizedBox(height: 20),
            ],

             if (_type == TransactionType.expense) ...[
                const Text('Category', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                SizedBox(
                  height: 50,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: TransactionCategory.categories.where((c) => c.name != 'Salary').length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (context, index) {
                      final categories = TransactionCategory.categories.where((c) => c.name != 'Salary').toList();
                      final cat = categories[index];
                      final isSelected = _selectedCategory == cat.name;
                      return ChoiceChip(
                        label: Text(cat.name),
                        selected: isSelected,
                        onSelected: (val) => setState(() => _selectedCategory = cat.name),
                        avatar: Icon(cat.icon, size: 16, color: isSelected ? Colors.white : cat.color),
                        selectedColor: AppColors.primary,
                        showCheckmark: false,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Theme.of(context).textTheme.bodyMedium?.color,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
             ],
            if (_type != TransactionType.transfer) ...[
               _buildTextField(_noteController, 'Note (Optional)', Icons.notes, TextInputType.text),
               const SizedBox(height: 20),
            ],
            
            // Date Picker Field
            InkWell(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now(),
                );
                if (date != null) {
                  setState(() => _selectedDate = date);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.withOpacity(0.5)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, color: AppColors.primary, size: 20),
                    const SizedBox(width: 12),
                    Text(
                      'Date: ${DateFormat('dd MMMM yyyy').format(_selectedDate)}',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const Spacer(),
                    const Icon(Icons.arrow_drop_down, color: Colors.grey),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSaving 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Save Transaction', style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getLabel(TransactionType type) {
    switch (type) {
      case TransactionType.income: return 'Income';
      case TransactionType.expense: return 'Expense';
      case TransactionType.transfer: return 'Transfer';
    }
  }

  Widget _typeButton(TransactionType type, String label, Color color) {
    final isSelected = _type == type;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _type = type),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? color : color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color),
          ),
          child: Center(
            child: Text(label, style: TextStyle(color: isSelected ? Colors.white : color, fontWeight: FontWeight.bold, fontSize: 13)),
          ),
        ),
      ),
    );
  }

  Widget _paymentMethodButton(PaymentMethod method, String label, IconData icon, bool isSource) {
    final isSelected = isSource ? _paymentMethod == method : _toPaymentMethod == method;
    final color = isSelected ? AppColors.primary : Colors.grey;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() {
          if (isSource) {
            _paymentMethod = method;
          } else {
            _toPaymentMethod = method;
          }
        }),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Text(label, style: TextStyle(color: color, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, TextInputType type, {String? errorText}) {
    return TextField(
      controller: controller,
      keyboardType: type,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        errorText: errorText,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
