import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import '../../data/models/transaction_model.dart';

class ReportGenerator {
  static Future<void> shareCSV(List<TransactionModel> transactions, String dateRangeLabel) async {
    final csvContent = StringBuffer();
    // Headers
    csvContent.writeln('Date,Title,Type,Category,Amount,Payment Method,Note');

    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');
    for (var t in transactions) {
      final titleEscaped = t.title.replaceAll('"', '""');
      final noteEscaped = (t.note ?? '').replaceAll('"', '""');
      
      csvContent.writeln(
        '"${dateFormat.format(t.date)}","${titleEscaped}","${t.type.name}","${t.category}",${t.amount},"${t.paymentMethod.name}","${noteEscaped}"'
      );
    }

    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/smartspend_report_${dateRangeLabel.replaceAll(' ', '_')}.csv');
    await file.writeAsString(csvContent.toString());

    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'SmartSpend AI CSV Financial Report ($dateRangeLabel)',
      subject: 'SmartSpend Financial Report',
    );
  }

  static Future<void> sharePDF({
    required List<TransactionModel> transactions,
    required String dateRangeLabel,
    required double totalIncome,
    required double totalExpense,
    required double netBalance,
  }) async {
    final pdf = pw.Document();

    final dateFormat = DateFormat('dd MMM yyyy, HH:mm');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Title Header
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'SmartSpend AI',
                        style: pw.TextStyle(
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColor.fromHex('#6366F1'),
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Financial Activity Report',
                        style: const pw.TextStyle(
                          fontSize: 14,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'Period: $dateRangeLabel',
                        style: const pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.grey700,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Generated: ${DateFormat('dd MMMM yyyy').format(DateTime.now())}',
                        style: const pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.grey500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // Summary Section
            pw.Text(
              'Summary Metrics',
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey900,
              ),
            ),
            pw.SizedBox(height: 10),

            pw.Row(
              children: [
                _buildSummaryBox('Total Income', totalIncome, PdfColor.fromHex('#10B981')),
                pw.SizedBox(width: 16),
                _buildSummaryBox('Total Expenses', totalExpense, PdfColor.fromHex('#EF4444')),
                pw.SizedBox(width: 16),
                _buildSummaryBox('Net Savings', netBalance, PdfColor.fromHex('#6366F1')),
              ],
            ),
            pw.SizedBox(height: 30),

            // Detailed Transactions Table
            pw.Text(
              'Transaction Log',
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey900,
              ),
            ),
            pw.SizedBox(height: 10),

            _buildTransactionsTable(transactions, dateFormat),
          ];
        },
      ),
    );

    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/smartspend_report_${dateRangeLabel.replaceAll(' ', '_')}.pdf');
    await file.writeAsBytes(await pdf.save());

    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'SmartSpend AI PDF Financial Report ($dateRangeLabel)',
      subject: 'SmartSpend Financial Report',
    );
  }

  static pw.Widget _buildSummaryBox(String label, double amount, PdfColor accentColor) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey300),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
          color: PdfColors.grey50,
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              label,
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
            ),
            pw.SizedBox(height: 6),
            pw.Text(
              'Rs. ${amount.toStringAsFixed(2)}',
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
                color: accentColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static pw.Widget _buildTransactionsTable(List<TransactionModel> transactions, DateFormat dateFormat) {
    final headers = ['Date', 'Title', 'Category', 'Type', 'Method', 'Amount'];
    
    return pw.Table(
      border: const pw.TableBorder(
        bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
        horizontalInside: pw.BorderSide(color: PdfColors.grey200, width: 0.5),
      ),
      columnWidths: const {
        0: pw.FixedColumnWidth(80), // Date
        1: pw.FlexColumnWidth(),     // Title
        2: pw.FixedColumnWidth(80), // Category
        3: pw.FixedColumnWidth(60), // Type
        4: pw.FixedColumnWidth(60), // Method
        5: pw.FixedColumnWidth(70), // Amount
      },
      children: [
        // Header row
        pw.TableRow(
          decoration: pw.BoxDecoration(
            color: PdfColor.fromHex('#F3F4F6'),
          ),
          children: headers.map((header) {
            return pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              child: pw.Text(
                header,
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 10,
                  color: PdfColors.grey800,
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
              ? PdfColor.fromHex('#10B981')
              : (isExpense ? PdfColor.fromHex('#EF4444') : PdfColors.blue);
          
          final amountPrefix = isIncome ? '+' : (isExpense ? '-' : '');

          return pw.TableRow(
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                child: pw.Text(
                  dateFormat.format(t.date),
                  style: const pw.TextStyle(fontSize: 8),
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                child: pw.Text(
                  t.type == TransactionType.transfer
                      ? 'Transfer: ${t.paymentMethod.name.toUpperCase()} -> ${t.toPaymentMethod?.name.toUpperCase()}'
                      : t.title,
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8),
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                child: pw.Text(
                  t.type == TransactionType.transfer ? 'Transfer' : t.category,
                  style: const pw.TextStyle(fontSize: 8),
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                child: pw.Text(
                  t.type.name.toUpperCase(),
                  style: pw.TextStyle(
                    fontSize: 8,
                    fontWeight: pw.FontWeight.bold,
                    color: t.type == TransactionType.income
                        ? PdfColor.fromHex('#10B981')
                        : (t.type == TransactionType.expense ? PdfColor.fromHex('#EF4444') : PdfColors.blue),
                  ),
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                child: pw.Text(
                  t.paymentMethod.name.toUpperCase(),
                  style: const pw.TextStyle(fontSize: 8),
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                child: pw.Text(
                  '$amountPrefix Rs. ${t.amount.toStringAsFixed(2)}',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 8,
                    color: amountColor,
                  ),
                  textAlign: pw.TextAlign.right,
                ),
              ),
            ],
          );
        }).toList(),
      ],
    );
  }
}
