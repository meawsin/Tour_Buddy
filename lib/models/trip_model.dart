class Trip {
  final String id;
  final String name;
  final String? destination;
  final DateTime startDate;
  final DateTime endDate;
  final double totalBudget;

  Trip({
    required this.id,
    required this.name,
    this.destination,
    required this.startDate,
    required this.endDate,
    required this.totalBudget,
  });

  // Convert a Trip into a Map for storage (SQLite/SharedPrefs)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'destination': destination,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'totalBudget': totalBudget,
    };
  }
}