import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../core/app_colors.dart';
import '../../core/utils/report_generator.dart';
import '../../data/models/transaction_model.dart';
import '../providers/transaction_provider.dart';

class ExportReportScreen extends StatefulWidget {
  const ExportReportScreen({super.key});

  @override
  State<ExportReportScreen> createState() => _ExportReportScreenState();
}

class _ExportReportScreenState extends State<ExportReportScreen> {
  String _selectedRangeType = 'This Month'; // 'This Month', 'Last Month', 'This Year', 'Custom'
  DateTimeRange? _customRange;
  String _exportFormat = 'PDF'; // 'PDF', 'CSV'
  bool _isGenerating = false;

  DateTimeRange _getDateRange() {
    final now = DateTime.now();
    switch (_selectedRangeType) {
      case 'Last Month':
        final lastMonth = DateTime(now.year, now.month - 1, 1);
        final lastDay = DateTime(now.year, now.month, 0);
        return DateTimeRange(start: lastMonth, end: lastDay);
      case 'This Year':
        return DateTimeRange(start: DateTime(now.year, 1, 1), end: now);
      case 'Custom':
        return _customRange ?? DateTimeRange(start: DateTime(now.year, now.month, 1), end: now);
      case 'This Month':
      default:
        return DateTimeRange(start: DateTime(now.year, now.month, 1), end: now);
    }
  }

  String _getDateRangeLabel(DateTimeRange range) {
    final format = DateFormat('dd MMM yyyy');
    return '${format.format(range.start)} - ${format.format(range.end)}';
  }

  List<TransactionModel> _getFilteredTransactions(List<TransactionModel> transactions, DateTimeRange range) {
    return transactions.where((t) {
      return t.date.isAfter(range.start.subtract(const Duration(seconds: 1))) &&
          t.date.isBefore(range.end.add(const Duration(days: 1)));
    }).toList();
  }

  void _handleExport(List<TransactionModel> transactions, DateTimeRange range) async {
    if (transactions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No transactions found in this date range!')),
      );
      return;
    }

    setState(() => _isGenerating = true);
    final rangeLabel = _selectedRangeType == 'Custom' 
        ? _getDateRangeLabel(range)
        : _selectedRangeType;

    try {
      if (_exportFormat == 'CSV') {
        await ReportGenerator.shareCSV(transactions, rangeLabel);
      } else {
        final income = transactions
            .where((t) => t.type == TransactionType.income)
            .fold(0.0, (sum, t) => sum + t.amount);
        final expense = transactions
            .where((t) => t.type == TransactionType.expense)
            .fold(0.0, (sum, t) => sum + t.amount);
        
        await ReportGenerator.sharePDF(
          transactions: transactions,
          dateRangeLabel: _getDateRangeLabel(range),
          totalIncome: income,
          totalExpense: expense,
          netBalance: income - expense,
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating report: $e')),
      );
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tp = Provider.of<TransactionProvider>(context);
    final range = _getDateRange();
    final filtered = _getFilteredTransactions(tp.transactions, range);

    final income = filtered
        .where((t) => t.type == TransactionType.income)
        .fold(0.0, (sum, t) => sum + t.amount);
    final expense = filtered
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (sum, t) => sum + t.amount);
    final net = income - expense;

    return Scaffold(
      appBar: AppBar(
        title: Text('Financial Reports', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Select Date Range', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            
            // Range selection chips
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ['This Month', 'Last Month', 'This Year', 'Custom'].map((type) {
                final isSelected = _selectedRangeType == type;
                return ChoiceChip(
                  label: Text(type),
                  selected: isSelected,
                  onSelected: (val) async {
                    if (type == 'Custom' && val) {
                      final picked = await showDateRangePicker(
                        context: context,
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now(),
                        initialDateRange: _customRange,
                        builder: (context, child) => Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: const ColorScheme.light(
                              primary: AppColors.primary,
                              onPrimary: Colors.white,
                            ),
                          ),
                          child: child!,
                        ),
                      );
                      if (picked != null) {
                        setState(() {
                          _customRange = picked;
                          _selectedRangeType = type;
                        });
                      }
                    } else if (val) {
                      setState(() => _selectedRangeType = type);
                    }
                  },
                  selectedColor: AppColors.primary,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.black,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                );
              }).toList(),
            ),

            if (_selectedRangeType == 'Custom' && _customRange != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.withOpacity(0.1)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.date_range, color: AppColors.primary, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      _getDateRangeLabel(range),
                      style: GoogleFonts.outfit(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Report Preview Sheet Container (Mimics PDF Document Layout structure)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Report Preview', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
                const Icon(Icons.print_outlined, color: Colors.grey, size: 20),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.withOpacity(0.2)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 15,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // PDF Header Representation
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'SmartSpend AI',
                            style: GoogleFonts.outfit(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Financial Activity Report',
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Period: ${_selectedRangeType == 'Custom' ? _getDateRangeLabel(range) : _selectedRangeType}',
                            style: GoogleFonts.outfit(fontSize: 9, color: Colors.grey[600], fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Generated: ${DateFormat('dd MMM yyyy').format(DateTime.now())}',
                            style: GoogleFonts.outfit(fontSize: 8, color: Colors.grey[400]),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Divider(height: 24, thickness: 1),

                  // Summary Metrics
                  Text(
                    'Summary Metrics',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[900],
                    ),
                  ),
                  const SizedBox(height: 10),

                  Row(
                    children: [
                      _buildSummaryStatBox('Total Income', income, const Color(0xFF10B981)),
                      const SizedBox(width: 8),
                      _buildSummaryStatBox('Total Expenses', expense, const Color(0xFFEF4444)),
                      const SizedBox(width: 8),
                      _buildSummaryStatBox('Net Savings', net, AppColors.primary),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),
            Text('Export Options', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            // Format Selection Toggle Buttons
            Row(
              children: [
                _buildFormatButton('PDF', Icons.picture_as_pdf_rounded, Colors.red),
                const SizedBox(width: 16),
                _buildFormatButton('CSV', Icons.table_chart_rounded, Colors.green),
              ],
            ),

            const SizedBox(height: 24),
            
            // Action Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _isGenerating ? null : () => _handleExport(filtered, range),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 2,
                ),
                icon: _isGenerating 
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.share_rounded),
                label: Text(
                  _isGenerating ? 'Generating report...' : 'Export & Share Report',
                  style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 28),

            // Transactions Table (Matches PDF table layout)
            Text(
              'Transaction Log',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            if (filtered.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text('No transactions in this period', style: GoogleFonts.outfit(color: Colors.grey)),
                ),
              )
            else
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.withOpacity(0.2)),
                ),
                child: _buildTransactionsTable(filtered),
              ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryStatBox(String label, double amount, Color accentColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.withOpacity(0.3)),
          borderRadius: const BorderRadius.all(Radius.circular(8)),
          color: Colors.grey.withOpacity(0.02),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.outfit(fontSize: 9, color: Colors.grey[600]),
            ),
            const SizedBox(height: 4),
            Text(
              '₹${amount.toStringAsFixed(0)}',
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: accentColor,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionsTable(List<TransactionModel> transactions) {
    final headers = ['Date', 'Title', 'Category', 'Type', 'Method', 'Amount'];
    
    return Table(
      border: TableBorder(
        bottom: BorderSide(color: Colors.grey.withOpacity(0.2), width: 0.5),
        horizontalInside: BorderSide(color: Colors.grey.withOpacity(0.15), width: 0.5),
      ),
      columnWidths: const {
        0: FixedColumnWidth(55), // Date
        1: FlexColumnWidth(),    // Title
        2: FixedColumnWidth(65), // Category
        3: FixedColumnWidth(50), // Type
        4: FixedColumnWidth(50), // Method
        5: FixedColumnWidth(65), // Amount
      },
      children: [
        // Header row
        TableRow(
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.05),
          ),
          children: headers.map((header) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
              child: Text(
                header,
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: 9,
                  color: Colors.grey[800],
                ),
              ),
            );
          }).toList(),
        ),
        // Data rows
        ...transactions.map((t) {
          final isIncome = t.type == TransactionType.income;
          final isExpense = t.type == TransactionType.expense;
          final amountColor = isIncome
              ? const Color(0xFF10B981)
              : (isExpense ? const Color(0xFFEF4444) : Colors.blue);
          
          final amountPrefix = isIncome ? '+' : (isExpense ? '-' : '');

          return TableRow(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
                child: Text(
                  DateFormat('dd MMM').format(t.date),
                  style: GoogleFonts.outfit(fontSize: 8, color: Colors.grey[700]),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
                child: Text(
                  t.type == TransactionType.transfer
                      ? 'Transfer'
                      : t.title,
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 8),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
                child: Text(
                  t.type == TransactionType.transfer ? 'Transfer' : t.category,
                  style: GoogleFonts.outfit(fontSize: 8, color: Colors.grey[600]),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
                child: Text(
                  t.type.name.toUpperCase(),
                  style: GoogleFonts.outfit(
                    fontSize: 7,
                    fontWeight: FontWeight.bold,
                    color: amountColor,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
                child: Text(
                  t.paymentMethod.name.toUpperCase(),
                  style: GoogleFonts.outfit(fontSize: 7, color: Colors.grey[500]),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
                child: Text(
                  '$amountPrefix₹${t.amount.toStringAsFixed(0)}',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 8,
                    color: amountColor,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          );
        }).toList(),
      ],
    );
  }

  Widget _buildFormatButton(String format, IconData icon, Color color) {
    final isSelected = _exportFormat == format;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _exportFormat = format),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isSelected ? color : Colors.grey.withOpacity(0.3), width: 1.5),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? color : Colors.grey, size: 28),
              const SizedBox(height: 8),
              Text(
                format,
                style: GoogleFonts.outfit(
                  color: isSelected ? color : Colors.grey,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
