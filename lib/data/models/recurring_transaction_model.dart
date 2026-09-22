import 'transaction_model.dart';

enum RecurrenceFrequency { daily, weekly, monthly, yearly }

class RecurringTransactionModel {
  final String id;
  final String title;
  final double amount;
  final String category;
  final TransactionType type;
  final DateTime startDate;
  final RecurrenceFrequency frequency;
  final bool isActive;
  final DateTime lastExecutedDate;
  final PaymentMethod paymentMethod;

  RecurringTransactionModel({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.type,
    required this.startDate,
    required this.frequency,
    this.isActive = true,
    required this.lastExecutedDate,
    required this.paymentMethod,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'category': category,
      'type': type.name,
      'startDate': startDate.toIso8601String(),
      'frequency': frequency.name,
      'isActive': isActive ? 1 : 0,
      'lastExecutedDate': lastExecutedDate.toIso8601String(),
      'paymentMethod': paymentMethod.name,
    };
  }

  factory RecurringTransactionModel.fromMap(Map<String, dynamic> map) {
    return RecurringTransactionModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      amount: (map['amount'] ?? 0.0).toDouble(),
      category: map['category'] ?? 'Others',
      type: TransactionType.values.byName(map['type'] ?? 'expense'),
      startDate: DateTime.parse(map['startDate']),
      frequency: RecurrenceFrequency.values.byName(map['frequency'] ?? 'monthly'),
      isActive: (map['isActive'] ?? 1) == 1,
      lastExecutedDate: DateTime.parse(map['lastExecutedDate']),
      paymentMethod: PaymentMethod.values.byName(map['paymentMethod'] ?? 'cash'),
    );
  }

  RecurringTransactionModel copyWith({
    String? id,
    String? title,
    double? amount,
    String? category,
    TransactionType? type,
    DateTime? startDate,
    RecurrenceFrequency? frequency,
    bool? isActive,
    DateTime? lastExecutedDate,
    PaymentMethod? paymentMethod,
  }) {
    return RecurringTransactionModel(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      type: type ?? this.type,
      startDate: startDate ?? this.startDate,
      frequency: frequency ?? this.frequency,
      isActive: isActive ?? this.isActive,
      lastExecutedDate: lastExecutedDate ?? this.lastExecutedDate,
      paymentMethod: paymentMethod ?? this.paymentMethod,
    );
  }
}
