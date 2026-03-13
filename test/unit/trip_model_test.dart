import 'package:flutter_test/flutter_test.dart';
import 'package:tour_buddy/models/trip.dart';

void main() {
  group('Trip model', () {
    late Trip trip;

    setUp(() {
      trip = Trip(
        id: 'trip_001',
        name: 'Bangkok Adventure',
        destination: 'Bangkok, Thailand',
        startDate: DateTime(2025, 3, 1),
        endDate: DateTime(2025, 3, 10),
        budget: 1000.0,
        currency: 'USD',
        expenses: [],
      );
    });

    // ── Construction ─────────────────────────────────────────────────────

    test('creates trip with all required fields', () {
      expect(trip.name, 'Bangkok Adventure');
      expect(trip.destination, 'Bangkok, Thailand');
      expect(trip.budget, 1000.0);
      expect(trip.currency, 'USD');
      expect(trip.expenses, isEmpty);
    });

    test('id is optional and can be null', () {
      final noIdTrip = Trip(
        name: 'Quick Trip',
        destination: 'Paris',
        startDate: DateTime(2025, 6, 1),
        endDate: DateTime(2025, 6, 7),
        budget: 500.0,
        currency: 'EUR',
      );
      expect(noIdTrip.id, isNull);
    });

    test('expenses defaults to empty list when not provided', () {
      final t = Trip(
        name: 'No Expenses',
        destination: 'London',
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 3)),
        budget: 300.0,
        currency: 'GBP',
      );
      expect(t.expenses, isA<List>());
      expect(t.expenses, isEmpty);
    });

    // ── toMap ─────────────────────────────────────────────────────────────

    test('toMap returns correct keys', () {
      final map = trip.toMap();
      expect(map.containsKey('name'), isTrue);
      expect(map.containsKey('destination'), isTrue);
      expect(map.containsKey('startDate'), isTrue);
      expect(map.containsKey('endDate'), isTrue);
      expect(map.containsKey('budget'), isTrue);
      expect(map.containsKey('currency'), isTrue);
      expect(map.containsKey('expenses'), isTrue);
    });

    test('toMap does not include id (Firestore manages doc ID)', () {
      final map = trip.toMap();
      expect(map.containsKey('id'), isFalse);
    });

    test('toMap encodes name and destination correctly', () {
      final map = trip.toMap();
      expect(map['name'], 'Bangkok Adventure');
      expect(map['destination'], 'Bangkok, Thailand');
    });

    test('toMap encodes budget as double', () {
      final map = trip.toMap();
      expect(map['budget'], isA<double>());
      expect(map['budget'], 1000.0);
    });

    test('toMap encodes expenses list', () {
      final tripWithExpenses = Trip(
        name: 'Test',
        destination: 'Tokyo',
        startDate: DateTime(2025, 5, 1),
        endDate: DateTime(2025, 5, 5),
        budget: 500.0,
        currency: 'JPY',
        expenses: [
          {'id': 'e1', 'title': 'Ramen', 'amount': 12.5, 'category': 'Food'},
        ],
      );
      final map = tripWithExpenses.toMap();
      expect(map['expenses'], hasLength(1));
      expect(map['expenses'][0]['title'], 'Ramen');
    });

    // ── Date validation ───────────────────────────────────────────────────

    test('trip with same start and end date is valid (day trip)', () {
      final dayTrip = Trip(
        name: 'Day Trip',
        destination: 'Nearby City',
        startDate: DateTime(2025, 7, 4),
        endDate: DateTime(2025, 7, 4),
        budget: 100.0,
        currency: 'USD',
      );
      expect(dayTrip.startDate, equals(dayTrip.endDate));
    });

    test('end date is after start date for multi-day trip', () {
      expect(trip.endDate.isAfter(trip.startDate), isTrue);
    });

    // ── Expenses list mutation ────────────────────────────────────────────

    test('expenses list can be modified', () {
      final t = Trip(
        name: 'Mutable',
        destination: 'Rome',
        startDate: DateTime(2025, 8, 1),
        endDate: DateTime(2025, 8, 5),
        budget: 800.0,
        currency: 'EUR',
        expenses: [],
      );
      t.expenses.add({
        'id': 'e1',
        'title': 'Pizza',
        'amount': 15.0,
        'category': 'Food',
      });
      expect(t.expenses, hasLength(1));
    });
  });
}
