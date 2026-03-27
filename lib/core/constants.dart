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

  static final List<TransactionCategory> categories = [
    TransactionCategory(name: 'Food', icon: Icons.restaurant, color: Colors.orange),
    TransactionCategory(name: 'Travel', icon: Icons.directions_car, color: Colors.blue),
    TransactionCategory(name: 'Bills', icon: Icons.receipt_long, color: Colors.red),
    TransactionCategory(name: 'Shopping', icon: Icons.shopping_bag, color: Colors.purple),
    TransactionCategory(name: 'Health', icon: Icons.medical_services, color: Colors.green),
    TransactionCategory(name: 'Salary', icon: Icons.payments, color: Colors.teal),
    TransactionCategory(name: 'Others', icon: Icons.more_horiz, color: Colors.grey),
  ];


  static TransactionCategory getByName(String name) {
    return categories.firstWhere(
      (cat) => cat.name.toLowerCase() == name.toLowerCase(),
      orElse: () => categories.last,
    );
  }
}
