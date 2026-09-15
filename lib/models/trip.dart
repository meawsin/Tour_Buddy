import 'package:cloud_firestore/cloud_firestore.dart';
import 'expense.dart';

class Trip {
  String? id;
  String name;
  String destination;
  DateTime startDate;
  DateTime endDate;
  double budget;
  String currency;
  List<Expense> expenses;

  Trip({
    this.id,
    required this.name,
    required this.destination,
    required this.startDate,
    required this.endDate,
    required this.budget,
    required this.currency,
    this.expenses = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'destination': destination,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'budget': budget,
      'currency': currency,
      'expenses': expenses.map((e) => e.toMap()).toList(),
    };
  }

  factory Trip.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>? ?? {};

    DateTime parsedStartDate;
    if (data['startDate'] is Timestamp) {
      parsedStartDate = (data['startDate'] as Timestamp).toDate();
    } else if (data['startDate'] is String) {
      parsedStartDate = DateTime.tryParse(data['startDate']) ?? DateTime.now();
    } else {
      parsedStartDate = DateTime.now();
    }

    DateTime parsedEndDate;
    if (data['endDate'] is Timestamp) {
      parsedEndDate = (data['endDate'] as Timestamp).toDate();
    } else if (data['endDate'] is String) {
      parsedEndDate = DateTime.tryParse(data['endDate']) ?? DateTime.now().add(const Duration(days: 7));
    } else {
      parsedEndDate = DateTime.now().add(const Duration(days: 7));
    }

    List<Expense> parsedExpenses = [];
    if (data['expenses'] is List) {
      for (var item in data['expenses']) {
        if (item is Map) {
          parsedExpenses.add(Expense.fromMap(Map<String, dynamic>.from(item)));
        }
      }
    }

    return Trip(
      id: doc.id,
      name: data['name'] ?? '',
      destination: data['destination'] ?? '',
      startDate: parsedStartDate,
      endDate: parsedEndDate,
      budget: (data['budget'] as num?)?.toDouble() ?? 0.0,
      currency: data['currency'] ?? 'BDT',
      expenses: parsedExpenses,
    );
  }

  Trip copyWith({
    String? id,
    String? name,
    String? destination,
    DateTime? startDate,
    DateTime? endDate,
    double? budget,
    String? currency,
    List<Expense>? expenses,
  }) {
    return Trip(
      id: id ?? this.id,
      name: name ?? this.name,
      destination: destination ?? this.destination,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      budget: budget ?? this.budget,
      currency: currency ?? this.currency,
      expenses: expenses ?? this.expenses,
    );
  }
}
