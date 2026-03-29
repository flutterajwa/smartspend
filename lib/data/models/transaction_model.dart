enum TransactionType { income, expense, transfer }

enum PaymentMethod { cash, account }

class TransactionModel {
  final String id;
  final String userId;
  final String title;
  final double amount;
  final String category;
  final TransactionType type;
  final DateTime date;
  final String? note;
  final PaymentMethod paymentMethod;
  final PaymentMethod? toPaymentMethod; // Only for transfers

  TransactionModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.amount,
    required this.category,
    required this.type,
    required this.date,
    this.note,
    required this.paymentMethod,
    this.toPaymentMethod,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'amount': amount,
      'category': category,
      'type': type.name,
      'date': date.toIso8601String(),
      'note': note,
      'paymentMethod': paymentMethod.name,
      'toPaymentMethod': toPaymentMethod?.name,
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      amount: (map['amount'] ?? 0.0).toDouble(),
      category: map['category'] ?? 'Others',
      type: TransactionType.values.byName(map['type'] ?? 'expense'),
      date: DateTime.parse(map['date']),
      note: map['note'],
      paymentMethod: PaymentMethod.values.byName(map['paymentMethod'] ?? 'cash'),
      toPaymentMethod: map['toPaymentMethod'] != null
          ? PaymentMethod.values.byName(map['toPaymentMethod'])
          : null,
    );
  }
}
