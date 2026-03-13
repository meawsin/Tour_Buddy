import 'package:cloud_firestore/cloud_firestore.dart';

class Trip {
  /// Firebase document ID. Null until the trip is saved to Firestore.
  String? id;
  /// Display name of the trip (e.g. 'Eid Trip 2026').
  String name;
  /// Destination string shown on the trip card.
  String destination;
  /// Trip start date. Stored as Firestore Timestamp.
  DateTime startDate;
  /// Trip end date. Stored as Firestore Timestamp.
  DateTime endDate;
  /// Budget amount in [currency]. Zero means no budget set.
  double budget;
  /// ISO currency code (e.g. 'BDT', 'USD').
  String currency;
  /// List of expenses stored as maps.
  /// Each map contains: id, title, amount, category, date (ISO string), notes?.
  List<Map<String, dynamic>> expenses;

  Trip({
    this.id,
    required this.name, // Changed from title to name
    required this.destination,
    required this.startDate,
    required this.endDate,
    required this.budget,
    required this.currency,
    this.expenses = const [],
  });

  // Convert a Trip object to a Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name, // Changed from title to name
      'destination': destination,
      'startDate': Timestamp.fromDate(
          startDate), // Convert DateTime to Firestore Timestamp
      'endDate': Timestamp.fromDate(
          endDate), // Convert DateTime to Firestore Timestamp
      'budget': budget,
      'currency': currency,
      'expenses': expenses,
    };
  }

  // Create a Trip object from a Firestore document snapshot
  factory Trip.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Trip(
      id: doc.id,
      name: data['name'] ?? '', // Changed from title to name
      destination: data['destination'] ?? '',
      startDate: (data['startDate'] as Timestamp)
          .toDate(), // Convert Timestamp to DateTime
      endDate: (data['endDate'] as Timestamp)
          .toDate(), // Convert Timestamp to DateTime
      budget: (data['budget'] as num).toDouble(),
      currency: data['currency'] ?? '',
      expenses: List<Map<String, dynamic>>.from(data['expenses'] ?? []),
    );
  }
}
