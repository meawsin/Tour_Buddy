class Expense {
  final String id;
  final String tripId; // Links expense to a specific Trip
  final String title;
  final double amount;
  final DateTime date;
  final String category; // e.g., Food, Transport, Hotel [5]
  final String? notes;

  Expense({
    required this.id,
    required this.tripId,
    required this.title,
    required this.amount,
    required this.date,
    required this.category,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tripId': tripId,
      'title': title,
      'amount': amount,
      'date': date.toIso8601String(),
      'category': category,
      'notes': notes,
    };
  }
}