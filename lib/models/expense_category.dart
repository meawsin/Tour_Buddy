import 'package:flutter/material.dart';

class ExpenseCategory {
  final String name;
  final IconData icon;
  final Color color;

  const ExpenseCategory({
    required this.name,
    required this.icon,
    required this.color,
  });

  static const List<ExpenseCategory> defaultCategories = [
    ExpenseCategory(
      name: 'Food',
      icon: Icons.restaurant_rounded,
      color: Color(0xFFF57C00), // Orange
    ),
    ExpenseCategory(
      name: 'Transport',
      icon: Icons.directions_bus_rounded,
      color: Color(0xFF1976D2), // Blue
    ),
    ExpenseCategory(
      name: 'Accommodation',
      icon: Icons.hotel_rounded,
      color: Color(0xFF5E35B1), // Deep Purple
    ),
    ExpenseCategory(
      name: 'Shopping',
      icon: Icons.shopping_bag_outlined,
      color: Color(0xFFE91E63), // Pink
    ),
    ExpenseCategory(
      name: 'Activities',
      icon: Icons.local_activity_outlined,
      color: Color(0xFF2E7D32), // Green
    ),
    ExpenseCategory(
      name: 'Other',
      icon: Icons.receipt_long_outlined,
      color: Color(0xFF607D8B), // Blue Grey
    ),
  ];

  static ExpenseCategory getCategory(String? name) {
    final search = (name ?? '').trim().toLowerCase();
    return defaultCategories.firstWhere(
      (cat) {
        final catName = cat.name.toLowerCase();
        if (catName == search) return true;
        if ((search == 'stay' || search == 'hotel') && catName == 'accommodation') return true;
        return false;
      },
      orElse: () => defaultCategories.last,
    );
  }
}
