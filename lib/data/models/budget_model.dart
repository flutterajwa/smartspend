class BudgetModel {
  final String category;
  final double amount;
  final int month;
  final int year;

  BudgetModel({
    required this.category,
    required this.amount,
    required this.month,
    required this.year,
  });

  Map<String, dynamic> toMap() {
    return {
      'category': category,
      'amount': amount,
      'month': month,
      'year': year,
    };
  }

  factory BudgetModel.fromMap(Map<String, dynamic> map) {
    return BudgetModel(
      category: map['category'] ?? 'Others',
      amount: (map['amount'] ?? 0.0).toDouble(),
      month: map['month'] ?? 1,
      year: map['year'] ?? 2024,
    );
  }
}
