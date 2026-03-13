/// Lightweight expense model used for in-memory operations.
///
/// In Firestore, expenses are stored as maps inside the parent [Trip]'s
/// `expenses` array — not as separate documents. This class is used when
/// constructing new expense maps via [toMap].
class Expense {
  /// Unique ID for this expense, generated client-side with uuid.
  final String id;
  /// ID of the parent [Trip]. Used to associate expenses before Firestore write.
  final String tripId;
  /// Human-readable expense label (e.g. 'Pad Thai', 'Bus ticket').
  final String title;
  /// Expense amount in the parent trip's currency.
  final double amount;
  final DateTime date;
  /// Category from [TripCategories.defaultList] (Food, Transport, Hotel, Shopping, Other).
  final String category;
  /// Optional notes. Null if not provided.
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