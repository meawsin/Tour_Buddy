import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

class Expense {
  final String id;
  final String title;
  final double amount;
  final String category;
  final DateTime date;
  final double? foreignAmount;
  final String? foreignCurrency;

  const Expense({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.date,
    this.foreignAmount,
    this.foreignCurrency,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'category': category,
      'date': DateFormat('yyyy-MM-dd HH:mm').format(date),
      if (foreignAmount != null) 'foreignAmount': foreignAmount,
      if (foreignCurrency != null) 'foreignCurrency': foreignCurrency,
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    DateTime parsedDate;
    final rawDate = map['date'];
    if (rawDate is Timestamp) {
      parsedDate = rawDate.toDate();
    } else if (rawDate is String) {
      try {
        parsedDate = DateFormat('yyyy-MM-dd HH:mm').parse(rawDate);
      } catch (_) {
        parsedDate = DateTime.tryParse(rawDate) ?? DateTime.now();
      }
    } else {
      parsedDate = DateTime.now();
    }

    return Expense(
      id: map['id']?.toString() ?? const Uuid().v4(),
      title: map['title']?.toString() ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      category: map['category']?.toString() ?? 'Other',
      date: parsedDate,
      foreignAmount: (map['foreignAmount'] as num?)?.toDouble(),
      foreignCurrency: map['foreignCurrency']?.toString(),
    );
  }

  Expense copyWith({
    String? id,
    String? title,
    double? amount,
    String? category,
    DateTime? date,
    double? foreignAmount,
    String? foreignCurrency,
  }) {
    return Expense(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      date: date ?? this.date,
      foreignAmount: foreignAmount ?? this.foreignAmount,
      foreignCurrency: foreignCurrency ?? this.foreignCurrency,
    );
  }
}
