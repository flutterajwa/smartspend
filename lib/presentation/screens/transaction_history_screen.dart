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

  const TransactionHistoryScreen({
    super.key, 
    this.initialType,
    this.initialMonth,
    this.initialYear,
  });

  @override
  State<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  String _searchQuery = "";
  bool _isDescending = true;
  DateTime? _filterDate;
  TransactionType? _filterType;
  int? _filterMonth;
  int? _filterYear;

  @override
  void initState() {
    super.initState();
    _filterType = widget.initialType;
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

      return matchesSearch && matchesDate && matchesType;
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
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (val) => setState(() => _searchQuery = val),
                    decoration: InputDecoration(
                      hintText: 'Search...',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.grey.withOpacity(0.1),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: (_filterDate != null || _filterMonth != null) ? AppColors.primary : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: Icon(Icons.calendar_month, color: (_filterDate != null || _filterMonth != null) ? Colors.white : Colors.grey),
                    onPressed: () async {
                      if (_filterDate != null || _filterMonth != null) {
                        setState(() {
                          _filterDate = null;
                          _filterMonth = null;
                          _filterYear = null;
                        });
                      } else {
                        final date = await showDatePicker(
                          context: context, 
                          initialDate: DateTime.now(), 
                          firstDate: DateTime(2000), 
                          lastDate: DateTime.now(),
                        );
                        if (date != null) setState(() => _filterDate = date);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          
          // Type Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildTypeChip('All', null),
                const SizedBox(width: 8),
                _buildTypeChip('Income', TransactionType.income),
                const SizedBox(width: 8),
                _buildTypeChip('Expense', TransactionType.expense),
              ],
            ),
          ),
          
          if (_filterDate != null || _filterMonth != null)
             Padding(
               padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
               child: Row(
                 children: [
                   Chip(
                     label: Text(_filterDate != null 
                        ? 'Date: ${DateFormat('dd MMM yyyy').format(_filterDate!)}'
                        : 'Month: ${DateFormat('MMMM yyyy').format(DateTime(_filterYear!, _filterMonth!))}'),
                     onDeleted: () => setState(() {
                       _filterDate = null;
                       _filterMonth = null;
                       _filterYear = null;
                     }),
                     deleteIconColor: Colors.red,
                     backgroundColor: AppColors.primary.withOpacity(0.1),
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
                            final category = TransactionCategory.getByName(t.category);
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
                                    backgroundColor: category.color.withOpacity(0.1),
                                    child: Icon(category.icon, color: category.color, size: 20),
                                  ),
                                  title: Text(t.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                                  subtitle: Text('${category.name} • ${DateFormat('hh:mm a').format(t.date)}'),
                                  trailing: Text(
                                    '${t.type == TransactionType.income ? '+' : '-'} ₹${t.amount.toStringAsFixed(0)}',
                                    style: TextStyle(
                                      color: t.type == TransactionType.income ? AppColors.income : AppColors.expense,
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

  Widget _buildTypeChip(String label, TransactionType? type) {
    final isSelected = _filterType == type;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (val) {
        if (val) setState(() => _filterType = type);
      },
      selectedColor: AppColors.primary,
      labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black87),
      showCheckmark: false,
    );
  }
}
