import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../core/constants.dart';
import '../../data/models/transaction_model.dart';
import '../providers/auth_provider.dart';
import '../providers/transaction_provider.dart';

class TransactionHistoryScreen extends StatefulWidget {
  final TransactionType? initialType;
  final int? initialMonth;
  final int? initialYear;
  final PaymentMethod? initialPaymentMethod;

  const TransactionHistoryScreen({
    super.key, 
    this.initialType,
    this.initialMonth,
    this.initialYear,
    this.initialPaymentMethod,
  });

  @override
  State<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();
  bool _isDescending = true;
  DateTime? _filterDate;
  TransactionType? _filterType;
  PaymentMethod? _filterPaymentMethod;
  List<String> _selectedCategories = [];
  int? _filterMonth;
  int? _filterYear;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _filterType = widget.initialType;
    _filterPaymentMethod = widget.initialPaymentMethod;
    _filterMonth = widget.initialMonth;
    _filterYear = widget.initialYear;
  }

  Map<String, List<TransactionModel>> _groupTransactions(List<TransactionModel> transactions) {
    Map<String, List<TransactionModel>> grouped = {};
    for (var t in transactions) {
      String dateStr;
      final tDate = DateTime(t.date.year, t.date.month, t.date.day);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));

      if (tDate == today) {
        dateStr = "Today";
      } else if (tDate == yesterday) {
        dateStr = "Yesterday";
      } else {
        dateStr = DateFormat('dd MMMM yyyy').format(t.date);
      }

      if (!grouped.containsKey(dateStr)) {
        grouped[dateStr] = [];
      }
      grouped[dateStr]!.add(t);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final allTransactions = Provider.of<TransactionProvider>(context).transactions;
    List<TransactionModel> filteredTransactions = allTransactions.where((t) {
      final matchesSearch = t.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              t.category.toLowerCase().contains(_searchQuery.toLowerCase());
      
      bool matchesDate = true;
      if (_filterDate != null) {
        matchesDate = t.date.day == _filterDate!.day && 
                      t.date.month == _filterDate!.month && 
                      t.date.year == _filterDate!.year;
      } else if (_filterMonth != null && _filterYear != null) {
        matchesDate = t.date.month == _filterMonth && t.date.year == _filterYear;
      }

      bool matchesType = true;
      if (_filterType != null) {
        matchesType = t.type == _filterType;
      }

      bool matchesPayment = true;
      if (_filterPaymentMethod != null) {
        if (t.type == TransactionType.transfer) {
           matchesPayment = t.paymentMethod == _filterPaymentMethod || t.toPaymentMethod == _filterPaymentMethod;
        } else {
           matchesPayment = t.paymentMethod == _filterPaymentMethod;
        }
      }

      bool matchesCategory = true;
      if (_selectedCategories.isNotEmpty) {
        matchesCategory = _selectedCategories.contains(t.category);
      }

      return matchesSearch && matchesDate && matchesType && matchesPayment && matchesCategory;
    }).toList();

    // Sorting
    filteredTransactions.sort((a, b) => _isDescending ? b.date.compareTo(a.date) : a.date.compareTo(b.date));

    final groupedTransactions = _groupTransactions(filteredTransactions);
    final sortedDates = groupedTransactions.keys.toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        actions: [
          IconButton(
            icon: Icon(_isDescending ? Icons.arrow_downward : Icons.arrow_upward),
            onPressed: () => setState(() => _isDescending = !_isDescending),
            tooltip: 'Sort by Date',
          ),
        ],
      ),
      body: Column(
        children: [
          // Modern Search & Filter Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) => setState(() => _searchQuery = val),
                      decoration: InputDecoration(
                        hintText: 'Search transactions...',
                        prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                        suffixIcon: _searchQuery.isNotEmpty 
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18), 
                              onPressed: () => setState(() {
                                _searchController.clear();
                                _searchQuery = "";
                              }),
                            ) 
                          : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: _showFilterSheet,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: (_filterDate != null || _filterMonth != null || _filterType != null || _filterPaymentMethod != null || _selectedCategories.isNotEmpty) 
                          ? AppColors.primary 
                          : Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.tune_rounded, 
                      color: (_filterDate != null || _filterMonth != null || _filterType != null || _filterPaymentMethod != null || _selectedCategories.isNotEmpty)
                          ? Colors.white 
                          : Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Active Filters
          if (_hasActiveFilters())
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  if (_filterDate != null)
                    _buildActiveFilterChip(
                      'Date: ${DateFormat('dd MMM').format(_filterDate!)}', 
                      () => setState(() => _filterDate = null)
                    ),
                  if (_filterMonth != null)
                    _buildActiveFilterChip(
                      'Month: ${DateFormat('MMM yyyy').format(DateTime(_filterYear!, _filterMonth!))}', 
                      () => setState(() { _filterMonth = null; _filterYear = null; })
                    ),
                  if (_filterType != null)
                    _buildActiveFilterChip(
                      'Type: ${_filterType!.name.toUpperCase()}', 
                      () => setState(() => _filterType = null)
                    ),
                  if (_filterPaymentMethod != null)
                    _buildActiveFilterChip(
                      'Source: ${_filterPaymentMethod!.name.toUpperCase()}', 
                      () => setState(() => _filterPaymentMethod = null)
                    ),
                  ..._selectedCategories.map((cat) => 
                    _buildActiveFilterChip(
                      'Cat: $cat', 
                      () => setState(() => _selectedCategories.remove(cat))
                    )
                  ),
                  TextButton(
                    onPressed: _clearAllFilters,
                    child: const Text('Clear All', style: TextStyle(color: Colors.red, fontSize: 12)),
                  ),
                ],
              ),
            ),
          
          Expanded(
            child: filteredTransactions.isEmpty
                ? const Center(child: Text('No matching transactions found'))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    itemCount: sortedDates.length,
                    itemBuilder: (context, dateIndex) {
                      final date = sortedDates[dateIndex];
                      final transactions = groupedTransactions[date]!;
                      
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 16.0, bottom: 8.0, left: 4.0),
                            child: Text(
                              date,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.indigo,
                              ),
                            ),
                          ),
                          ...transactions.map((t) {
                            final isTransfer = t.type == TransactionType.transfer;
                            final category = isTransfer ? TransactionCategory.categories.firstWhere((c) => c.name == 'Others') : TransactionCategory.getByName(t.category);
                            
                            return Dismissible(
                              key: Key(t.id),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 20),
                                margin: const EdgeInsets.symmetric(vertical: 6),
                                decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(12)),
                                child: const Icon(Icons.delete_outline, color: Colors.white),
                              ),
                              confirmDismiss: (direction) async {
                                return await showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Delete Transaction'),
                                    content: const Text('Are you sure you want to delete this transaction?'),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                                      TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
                                    ],
                                  ),
                                );
                              },
                              onDismissed: (direction) {
                                final auth = Provider.of<AuthProvider>(context, listen: false);
                                Provider.of<TransactionProvider>(context, listen: false).deleteTransaction(auth.user!.uid, t.id);
                              },
                              child: Card(
                                margin: const EdgeInsets.symmetric(vertical: 6),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  side: BorderSide(color: Colors.grey.withOpacity(0.2)),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: isTransfer ? Colors.blue.withOpacity(0.1) : category.color.withOpacity(0.1),
                                    child: Icon(
                                      isTransfer ? Icons.swap_horiz_rounded : category.icon, 
                                      color: isTransfer ? Colors.blue : category.color, 
                                      size: 20
                                    ),
                                  ),
                                  title: Text(
                                    isTransfer ? 'Transfer: ${t.paymentMethod.name.toUpperCase()} → ${t.toPaymentMethod?.name.toUpperCase()}' : t.title, 
                                    style: const TextStyle(fontWeight: FontWeight.w600)
                                  ),
                                  subtitle: Text(
                                    '${isTransfer ? 'Internal' : category.name} • ${t.paymentMethod.name.toUpperCase()} • ${DateFormat('hh:mm a').format(t.date)}'
                                  ),
                                  trailing: Text(
                                    '${t.type == TransactionType.income ? '+' : (t.type == TransactionType.expense ? '-' : '')} ₹${t.amount.toStringAsFixed(0)}',
                                    style: TextStyle(
                                      color: t.type == TransactionType.income ? AppColors.income : (t.type == TransactionType.expense ? AppColors.expense : Colors.blue),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }


  bool _hasActiveFilters() {
    return _filterDate != null || _filterMonth != null || _filterType != null || _filterPaymentMethod != null || _selectedCategories.isNotEmpty;
  }

  void _clearAllFilters() {
    setState(() {
      _filterDate = null;
      _filterType = null;
      _filterPaymentMethod = null;
      _selectedCategories = [];
      _filterMonth = null;
      _filterYear = null;
    });
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Filters', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  TextButton(
                    onPressed: () {
                      _clearAllFilters();
                      setModalState(() {});
                    },
                    child: const Text('Reset', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              const Text('Transaction Type', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  _modalChoiceChip('All', null, _filterType, (val) => setModalState(() => _filterType = null)),
                  _modalChoiceChip('Income', TransactionType.income, _filterType, (val) => setModalState(() => _filterType = TransactionType.income)),
                  _modalChoiceChip('Expense', TransactionType.expense, _filterType, (val) => setModalState(() => _filterType = TransactionType.expense)),
                  _modalChoiceChip('Transfer', TransactionType.transfer, _filterType, (val) => setModalState(() => _filterType = TransactionType.transfer)),
                ],
              ),
              const SizedBox(height: 20),

              const Text('Payment Source', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  _modalChoiceChip('All', null, _filterPaymentMethod, (val) => setModalState(() => _filterPaymentMethod = null)),
                  _modalChoiceChip('Cash', PaymentMethod.cash, _filterPaymentMethod, (val) => setModalState(() => _filterPaymentMethod = PaymentMethod.cash)),
                  _modalChoiceChip('Account', PaymentMethod.account, _filterPaymentMethod, (val) => setModalState(() => _filterPaymentMethod = PaymentMethod.account)),
                ],
              ),
              const SizedBox(height: 20),

              const Text('Categories', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              SizedBox(
                height: 40,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: TransactionCategory.categories.length,
                  itemBuilder: (context, index) {
                    final cat = TransactionCategory.categories[index];
                    final isSelected = _selectedCategories.contains(cat.name);
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: FilterChip(
                        label: Text(cat.name, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : null)),
                        selected: isSelected,
                        onSelected: (val) {
                          setModalState(() {
                            if (val) {
                              _selectedCategories.add(cat.name);
                            } else {
                              _selectedCategories.remove(cat.name);
                            }
                          });
                        },
                        selectedColor: AppColors.primary,
                        showCheckmark: false,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),

              const Text('Date Filter', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.calendar_today, size: 18),
                      label: Text(_filterDate == null ? 'Select Date' : DateFormat('dd MMM yyyy').format(_filterDate!)),
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context, 
                          initialDate: _filterDate ?? DateTime.now(), 
                          firstDate: DateTime(2000), 
                          lastDate: DateTime.now(),
                        );
                        if (date != null) setModalState(() => _filterDate = date);
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {}); // Update main screen
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Apply Filters', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _modalChoiceChip<T>(String label, T? value, T? groupValue, Function(bool) onSelected) {
    final isSelected = value == groupValue;
    return ChoiceChip(
      label: Text(label, style: TextStyle(color: isSelected ? Colors.white : null, fontSize: 13)),
      selected: isSelected,
      onSelected: onSelected,
      selectedColor: AppColors.primary,
      showCheckmark: false,
    );
  }

  Widget _buildActiveFilterChip(String label, VoidCallback onDelete) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: Chip(
        label: Text(label, style: const TextStyle(fontSize: 11)),
        onDeleted: onDelete,
        deleteIcon: const Icon(Icons.close, size: 14),
        backgroundColor: AppColors.primary.withOpacity(0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide.none),
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}
