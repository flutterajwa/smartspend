import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../providers/transaction_provider.dart';

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final insights = Provider.of<TransactionProvider>(context).getAIInsights();

    return Scaffold(
      appBar: AppBar(title: const Text('AI Insights')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.primary.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                   const Icon(Icons.auto_awesome_rounded, color: AppColors.primary, size: 32),
                   const SizedBox(width: 16),
                   Expanded(
                     child: Text(
                       'Our AI analyzed your spending patterns to give you these smart tips.',
                       style: GoogleFonts.outfit(color: AppColors.primary, fontWeight: FontWeight.bold),
                     ),
                   ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Text('Daily Recommendations', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.separated(
                itemCount: insights.length,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                           const CircleAvatar(
                             backgroundColor: AppColors.accent,
                             radius: 12,
                             child: Icon(Icons.check, size: 14, color: Colors.white),
                           ),
                           const SizedBox(width: 16),
                           Expanded(child: Text(insights[index], style: const TextStyle(fontSize: 16))),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
