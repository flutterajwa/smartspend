import 'package:flutter/material.dart';

class TransactionCategory {
  final String name;
  final IconData icon;
  final Color color;

  TransactionCategory({
    required this.name,
    required this.icon,
    required this.color,
  });

  // A dynamic list that is populated from the DB at startup
  static List<TransactionCategory> categories = List.from(defaultCategories);

  static final List<TransactionCategory> defaultCategories = [
    TransactionCategory(name: 'Food', icon: Icons.restaurant, color: Colors.orange),
    TransactionCategory(name: 'Travel', icon: Icons.directions_car, color: Colors.blue),
    TransactionCategory(name: 'Bills', icon: Icons.receipt_long, color: Colors.red),
    TransactionCategory(name: 'Shopping', icon: Icons.shopping_bag, color: Colors.purple),
    TransactionCategory(name: 'Health', icon: Icons.medical_services, color: Colors.green),
    TransactionCategory(name: 'Salary', icon: Icons.payments, color: Colors.teal),
    TransactionCategory(name: 'Others', icon: Icons.more_horiz, color: Colors.grey),
  ];

  factory TransactionCategory.fromMap(Map<String, dynamic> map) {
    return TransactionCategory(
      name: map['name'] as String,
      icon: IconData(map['icon'] as int, fontFamily: 'MaterialIcons'),
      color: Color(map['color'] as int),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'icon': icon.codePoint,
      'color': color.value,
    };
  }

  static TransactionCategory getByName(String name) {
    return categories.firstWhere(
      (cat) => cat.name.toLowerCase() == name.toLowerCase(),
      orElse: () {
        // Fallback search in default categories if not found in active list
        try {
          return defaultCategories.firstWhere(
            (cat) => cat.name.toLowerCase() == name.toLowerCase(),
          );
        } catch (_) {
          return categories.last; // 'Others'
        }
      },
    );
  }
}
