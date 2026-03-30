import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../data/local_db.dart';
import '../../data/models/debt_model.dart';

class DebtProvider extends ChangeNotifier {
  List<DebtModel> _debts = [];
  bool _isLoading = false;

  List<DebtModel> get debts => _debts;
  bool get isLoading => _isLoading;

  double get totalToGive => _debts
      .where((d) => d.type == DebtType.toGive && !d.isSettled)
      .fold(0, (sum, d) => sum + d.amount);

  double get totalToGet => _debts
      .where((d) => d.type == DebtType.toGet && !d.isSettled)
      .fold(0, (sum, d) => sum + d.amount);

  Future<void> fetchDebts() async {
    _isLoading = true;
    notifyListeners();
    _debts = await LocalDB.getDebts();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addDebt(DebtModel debt) async {
    final docId = const Uuid().v4();
    final newDebt = DebtModel(
      id: docId,
      personName: debt.personName,
      amount: debt.amount,
      type: debt.type,
      date: debt.date,
      note: debt.note,
      isSettled: false,
      dueDate: debt.dueDate,
    );

    await LocalDB.insertDebt(newDebt);
    await fetchDebts();
  }

  Future<void> toggleSettlement(String id, bool isSettled) async {
    await LocalDB.updateDebtSettlement(id, isSettled, settledDate: isSettled ? DateTime.now() : null);
    await fetchDebts();
  }

  Future<void> deleteDebt(String id) async {
    await LocalDB.deleteDebt(id);
    await fetchDebts();
  }
}
