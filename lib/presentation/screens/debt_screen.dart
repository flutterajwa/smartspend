import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/app_colors.dart';
import '../../data/models/debt_model.dart';
import '../providers/debt_provider.dart';

class DebtScreen extends StatefulWidget {
  const DebtScreen({super.key});

  @override
  State<DebtScreen> createState() => _DebtScreenState();
}

class _DebtScreenState extends State<DebtScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DebtProvider>(context, listen: false).fetchDebts();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dp = Provider.of<DebtProvider>(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? AppColors.darkBackground : AppColors.background,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context, dp, isDarkMode),
          SliverToBoxAdapter(
            child: _buildCategoryTabs(context),
          ),
          if (dp.isLoading)
            const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: _tabController.index == 0 
                  ? _buildSliverDebtList(dp.debts.where((d) => d.type == DebtType.toGive).toList(), dp, isDarkMode)
                  : _buildSliverDebtList(dp.debts.where((d) => d.type == DebtType.toGet).toList(), dp, isDarkMode),
            ),
        ],
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(colors: [AppColors.primary, Color(0xFF6366F1)]),
          boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 8))],
        ),
        child: FloatingActionButton.extended(
          onPressed: () => _showAddDebtDialog(context),
          backgroundColor: Colors.transparent,
          elevation: 0,
          highlightElevation: 0,
          icon: const Icon(Icons.add_rounded, color: Colors.white),
          label: Text('Record Debt', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context, DebtProvider dp, bool isDark) {
    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      elevation: 0,
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.primary,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark 
                  ? [AppColors.darkBackground, const Color(0xFF1E293B)]
                  : [AppColors.primary, const Color(0xFF818CF8)],
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 18),
                  Text('Debts Tracking', style: GoogleFonts.outfit(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Text('Global Debt Balance', style: GoogleFonts.outfit(color: Colors.white70, fontSize: 14)),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('₹${(dp.totalToGet - dp.totalToGive).toStringAsFixed(0)}', 
                        style: GoogleFonts.outfit(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.account_balance_rounded, color: Colors.white),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      _buildMiniStat('Give', dp.totalToGive, Colors.redAccent),
                      const SizedBox(width: 24),
                      _buildMiniStat('Get', dp.totalToGet, Colors.greenAccent),
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

  Widget _buildMiniStat(String label, double amount, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.outfit(color: Colors.white60, fontSize: 12)),
        Text('₹${amount.toStringAsFixed(0)}', 
          style: GoogleFonts.outfit(color: color, fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildCategoryTabs(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Container(
        height: 52,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.withOpacity(0.1)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: TabBar(
          controller: _tabController,
          indicatorSize: TabBarIndicatorSize.tab,
          indicator: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: const LinearGradient(colors: [AppColors.primary, Color(0xFF6366F1)]),
            boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          dividerColor: Colors.transparent,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey[500],
          labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 12, letterSpacing: 0.5),
          unselectedLabelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w500, fontSize: 12, letterSpacing: 0.5),
          tabs: const [
            Tab(text: 'DEBT TO GIVE'),
            Tab(text: 'DEBT TO GET'),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverDebtList(List<DebtModel> debts, DebtProvider dp, bool isDark) {
    if (debts.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.layers_clear_outlined, size: 64, color: Colors.grey.withOpacity(0.3)),
              const SizedBox(height: 16),
              Text('No debt records found', style: GoogleFonts.outfit(color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    final active = debts.where((d) => !d.isSettled).toList();
    
    final now = DateTime.now();
    final settled = debts.where((d) {
      if (!d.isSettled) return false;
      final refDate = d.settledDate ?? d.date;
      return now.difference(refDate).inDays <= 30;
    }).toList();

    return SliverList(
      delegate: SliverChildListDelegate([
        if (active.isNotEmpty) ...[
          _buildHeader('ACTIVE COMMITMENTS', Colors.blue),
          ...active.map((d) => _buildModernDebtCard(d, dp, isDark)),
        ],
        if (settled.isNotEmpty) ...[
          const SizedBox(height: 24),
          _buildHeader('COMPLETED & SETTLED', Colors.grey),
          ...settled.map((d) => _buildModernDebtCard(d, dp, isDark)),
        ],
        const SizedBox(height: 100),
      ]),
    );
  }

  Widget _buildHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(title, 
        style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: color, letterSpacing: 1.5)),
    );
  }

  Widget _buildModernDebtCard(DebtModel debt, DebtProvider dp, bool isDark) {
    final isToGive = debt.type == DebtType.toGive;
    final isOverdue = !debt.isSettled && debt.dueDate != null && debt.dueDate!.isBefore(DateTime.now());
    final accentColor = isToGive ? AppColors.expense : AppColors.income;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isOverdue ? Colors.red.withOpacity(0.3) : Colors.transparent),
        boxShadow: [
          BoxShadow(
            color: (isOverdue ? Colors.red : Colors.black).withOpacity(0.04), 
            blurRadius: 20, 
            offset: const Offset(0, 10)
          )
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              tilePadding: const EdgeInsets.fromLTRB(20, 12, 12, 12),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Row(
                    children: [
                      Container(
                        width: 4,
                        height: 20,
                        decoration: BoxDecoration(
                          color: debt.isSettled ? Colors.grey : accentColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(debt.personName, 
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold, 
                            fontSize: 18,
                            decoration: debt.isSettled ? TextDecoration.lineThrough : null,
                            color: debt.isSettled ? Colors.grey : null
                          )),
                      ),
                      Text('₹${debt.amount.toStringAsFixed(0)}', 
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w800, 
                          fontSize: 20, 
                          color: debt.isSettled ? Colors.grey : accentColor
                        )),
                    ],
                  ),
                ],
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 8.0, left: 16),
                child: Row(
                  children: [
                    Icon(Icons.access_time_filled_rounded, size: 14, color: Colors.grey[400]),
                    const SizedBox(width: 6),
                    Text(DateFormat('dd MMM').format(debt.date), style: TextStyle(color: Colors.grey[500], fontSize: 13, fontWeight: FontWeight.w500)),
                    if (debt.dueDate != null && !debt.isSettled) ...[
                      const SizedBox(width: 16),
                      Icon(Icons.event_available_rounded, size: 14, color: isOverdue ? Colors.red : Colors.grey[400]),
                      const SizedBox(width: 6),
                      Text(
                        'Due ${DateFormat('dd MMM').format(debt.dueDate!)}', 
                        style: TextStyle(
                          color: isOverdue ? Colors.red : Colors.grey[500], 
                          fontSize: 13, 
                          fontWeight: isOverdue ? FontWeight.bold : FontWeight.w500
                        )
                      ),
                    ],
                  ],
                ),
              ),
              trailing: _buildActionButton(debt, dp),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        _buildDetailItem(Icons.history_rounded, 'Initial Recording', DateFormat('dd MMMM yyyy').format(debt.date)),
                        if (debt.dueDate != null) 
                          _buildDetailItem(Icons.timer_outlined, 'Payment Deadline', DateFormat('dd MMMM yyyy').format(debt.dueDate!), 
                            color: isOverdue ? Colors.red : null),
                        if (debt.isSettled && debt.settledDate != null)
                          _buildDetailItem(Icons.verified_rounded, 'Fully Settled On', DateFormat('dd MMMM yyyy').format(debt.settledDate!), color: Colors.green),
                        if (debt.note != null && debt.note!.isNotEmpty)
                          _buildDetailItem(Icons.notes_rounded, 'Reference Note', debt.note!),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: TextButton.icon(
                                onPressed: () => _showDeleteConfirm(context, debt.id, dp),
                                icon: const Icon(Icons.delete_outline_rounded, size: 18),
                                label: const Text('Remove Entry'),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.red[400],
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (isOverdue)
            Positioned(
              top: -8,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Colors.red, Color(0xFFEF4444)]),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [BoxShadow(color: Colors.red.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.priority_high_rounded, color: Colors.white, size: 10),
                    const SizedBox(width: 4),
                    Text('OVERDUE', 
                      style: GoogleFonts.outfit(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                  ],
                ),
              ),
            ),
          if (debt.isSettled)
            Positioned(
              top: -8,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)]),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [BoxShadow(color: Colors.green.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))],
                ),
                child: Text('SETTLED', 
                  style: GoogleFonts.outfit(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButton(DebtModel debt, DebtProvider dp) {
    return IconButton(
      icon: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: debt.isSettled ? Colors.grey.withOpacity(0.2) : AppColors.primary.withOpacity(0.1),
          shape: BoxShape.circle
        ),
        child: Icon(
          debt.isSettled ? Icons.undo_rounded : Icons.check_rounded, 
          color: debt.isSettled ? Colors.grey : AppColors.primary, 
          size: 18
        ),
      ),
      onPressed: () => dp.toggleSettlement(debt.id, !debt.isSettled),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color ?? Colors.grey[600]),
          const SizedBox(width: 12),
          Text('$label: ', style: GoogleFonts.outfit(color: Colors.grey[600], fontSize: 13)),
          Expanded(child: Text(value, style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 13, color: color))),
        ],
      ),
    );
  }

  void _showDeleteConfirm(BuildContext context, String id, DebtProvider dp) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Purge Record?', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Text('This debt information will be permanently deleted from your local storage.', style: GoogleFonts.outfit()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel', style: GoogleFonts.outfit())),
          ElevatedButton(
            onPressed: () {
              dp.deleteDebt(id);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: Text('Delete', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showAddDebtDialog(BuildContext context) {
    final personController = TextEditingController();
    final amountController = TextEditingController();
    final noteController = TextEditingController();
    DebtType selectedType = _tabController.index == 0 ? DebtType.toGive : DebtType.toGet;
    DateTime selectedDate = DateTime.now();
    DateTime? dueDate;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 24),
                Text('New Financial Entry', style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(child: _buildTypeToggle('I OWE TO', DebtType.toGive, selectedType, (val) => setModalState(() => selectedType = val), Colors.red)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildTypeToggle('OWED TO ME', DebtType.toGet, selectedType, (val) => setModalState(() => selectedType = val), Colors.green)),
                  ],
                ),
                const SizedBox(height: 24),
                _buildFieldLabel('WHO IS THE PERSON?'),
                TextField(
                  controller: personController,
                  style: GoogleFonts.outfit(),
                  decoration: _inputDecoration('Person name', Icons.person_rounded),
                ),
                const SizedBox(height: 16),
                _buildFieldLabel('WHAT IS THE AMOUNT?'),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold),
                  decoration: _inputDecoration('0.00', Icons.currency_rupee_rounded),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFieldLabel('ENTRY DATE'),
                          _buildDatePickerButton(context, DateFormat('dd MMM yyyy').format(selectedDate), () async {
                            final date = await showDatePicker(context: context, initialDate: selectedDate, firstDate: DateTime(2000), lastDate: DateTime.now());
                            if (date != null) setModalState(() => selectedDate = date);
                          }),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFieldLabel('REPAYMENT DUE'),
                          _buildDatePickerButton(context, dueDate == null ? 'Set Limit' : DateFormat('dd MMM yyyy').format(dueDate!), () async {
                            final date = await showDatePicker(context: context, initialDate: DateTime.now().add(const Duration(days: 7)), firstDate: DateTime.now(), lastDate: DateTime(2030));
                            if (date != null) setModalState(() => dueDate = date);
                          }, isSet: dueDate != null),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildFieldLabel('ADDITIONAL NOTES'),
                TextField(
                  controller: noteController,
                  decoration: _inputDecoration('Mention anything important...', Icons.description_rounded),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      final amount = double.tryParse(amountController.text);
                      if (personController.text.isNotEmpty && amount != null) {
                        Provider.of<DebtProvider>(context, listen: false).addDebt(DebtModel(
                          id: '', personName: personController.text, amount: amount, type: selectedType, date: selectedDate, dueDate: dueDate, note: noteController.text,
                        ));
                        Navigator.pop(context);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary, foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 8, shadowColor: AppColors.primary.withOpacity(0.5)
                    ),
                    child: Text('Add Commitment', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(label, style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey[600], letterSpacing: 1.2)),
    );
  }

  Widget _buildTypeToggle(String label, DebtType type, DebtType current, Function(DebtType) onSelect, Color color) {
    final isSelected = type == current;
    return GestureDetector(
      onTap: () => onSelect(type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.12) : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? color : Colors.grey.withOpacity(0.2), width: 1.5),
        ),
        child: Center(
          child: Text(label, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 12, color: isSelected ? color : Colors.grey[500])),
        ),
      ),
    );
  }

  Widget _buildDatePickerButton(BuildContext context, String label, VoidCallback onTap, {bool isSet = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Icon(Icons.event_note_rounded, size: 18, color: isSet ? AppColors.primary : Colors.grey),
            const SizedBox(width: 8),
            Expanded(child: Text(label, style: GoogleFonts.outfit(fontSize: 14, fontWeight: isSet ? FontWeight.bold : FontWeight.normal, color: isSet ? AppColors.primary : (isDark ? Colors.white70 : Colors.black87)), overflow: TextOverflow.ellipsis)),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, size: 20),
      filled: true,
      fillColor: Theme.of(context).cardColor.withOpacity(0.5),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.withOpacity(0.1))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.withOpacity(0.1))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.primary)),
      contentPadding: const EdgeInsets.all(16),
    );
  }
}
