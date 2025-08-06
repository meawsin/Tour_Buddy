import 'package:uuid/uuid.dart';

class Trip {
  final String id;
  String name;
  List<Map<String, dynamic>> expenses;
  double budget;
  String currency; // This is the trip's specific currency
  DateTime startDate;
  DateTime endDate;

  Trip({
    String? id,
    required this.name,
    List<Map<String, dynamic>>? expenses,
    this.budget = 0.0,
    this.currency = 'BDT',
    required this.startDate,
    required this.endDate,
  })  : id = id ?? const Uuid().v4(),
        expenses = expenses ?? [];

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'expenses': expenses,
        'budget': budget,
        'currency': currency,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
      };

  factory Trip.fromJson(Map<String, dynamic> json) {
    return Trip(
      id: json['id'],
      name: json['name'],
      expenses: List<Map<String, dynamic>>.from(json['expenses'] ?? []),
      budget: (json['budget'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] ?? 'BDT',
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
    );
  }
}
