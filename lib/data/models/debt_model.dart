
enum DebtType { toGive, toGet }

class DebtModel {
  final String id;
  final String personName;
  final double amount;
  final DebtType type;
  final DateTime date;
  final String? note;
  final bool isSettled;
  final DateTime? dueDate;
  final DateTime? settledDate;

  DebtModel({
    required this.id,
    required this.personName,
    required this.amount,
    required this.type,
    required this.date,
    this.note,
    this.isSettled = false,
    this.dueDate,
    this.settledDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'personName': personName,
      'amount': amount,
      'type': type.name,
      'date': date.toIso8601String(),
      'note': note,
      'isSettled': isSettled ? 1 : 0,
      'dueDate': dueDate?.toIso8601String(),
      'settledDate': settledDate?.toIso8601String(),
    };
  }

  factory DebtModel.fromMap(Map<String, dynamic> map) {
    return DebtModel(
      id: map['id'] ?? '',
      personName: map['personName'] ?? '',
      amount: (map['amount'] ?? 0.0).toDouble(),
      type: DebtType.values.byName(map['type'] ?? 'toGive'),
      date: DateTime.parse(map['date']),
      note: map['note'],
      isSettled: (map['isSettled'] ?? 0) == 1,
      dueDate: map['dueDate'] != null ? DateTime.parse(map['dueDate']) : null,
      settledDate: map['settledDate'] != null ? DateTime.parse(map['settledDate']) : null,
    );
  }

  DebtModel copyWith({
    String? id,
    String? personName,
    double? amount,
    DebtType? type,
    DateTime? date,
    String? note,
    bool? isSettled,
    DateTime? dueDate,
    DateTime? settledDate,
  }) {
    return DebtModel(
      id: id ?? this.id,
      personName: personName ?? this.personName,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      date: date ?? this.date,
      note: note ?? this.note,
      isSettled: isSettled ?? this.isSettled,
      dueDate: dueDate ?? this.dueDate,
      settledDate: settledDate ?? this.settledDate,
    );
  }
}
