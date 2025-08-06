import 'package:uuid/uuid.dart'; // Import uuid package

class Trip {
  final String id;
  String name;
  List<Map<String, dynamic>> expenses;
  double budget;
  String currency;
  DateTime startDate;
  DateTime endDate;

  Trip({
    String? id,
    required this.name,
    List<Map<String, dynamic>>? expenses,
    this.budget = 0.0,
    this.currency = 'BDT', // Default currency
    required this.startDate,
    required this.endDate,
  })  : id = id ?? const Uuid().v4(), // Generate a unique ID if not provided
        expenses = expenses ?? [];

  // Convert Trip object to JSON for SharedPreferences
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'expenses': expenses,
        'budget': budget,
        'currency': currency,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
      };

  // Create Trip object from JSON
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
