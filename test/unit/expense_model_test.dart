import 'package:flutter_test/flutter_test.dart';
import 'package:tour_buddy/models/expense_model.dart';

void main() {
  group('Expense model', () {
    late Expense expense;

    setUp(() {
      expense = Expense(
        id: 'exp_001',
        tripId: 'trip_001',
        title: 'Pad Thai',
        amount: 8.50,
        date: DateTime(2025, 3, 3),
        category: 'Food',
        notes: 'Amazing street food',
      );
    });

    // ── Construction ─────────────────────────────────────────────────────

    test('creates expense with all fields', () {
      expect(expense.id, 'exp_001');
      expect(expense.tripId, 'trip_001');
      expect(expense.title, 'Pad Thai');
      expect(expense.amount, 8.50);
      expect(expense.category, 'Food');
      expect(expense.notes, 'Amazing street food');
    });

    test('notes is optional and defaults to null', () {
      final noNotes = Expense(
        id: 'exp_002',
        tripId: 'trip_001',
        title: 'Bus ticket',
        amount: 2.0,
        date: DateTime(2025, 3, 4),
        category: 'Transport',
      );
      expect(noNotes.notes, isNull);
    });

    test('amount can be zero', () {
      final freeEntry = Expense(
        id: 'exp_003',
        tripId: 'trip_001',
        title: 'Free museum',
        amount: 0.0,
        date: DateTime(2025, 3, 5),
        category: 'Other',
      );
      expect(freeEntry.amount, 0.0);
    });

    test('amount can be a large value', () {
      final bigExpense = Expense(
        id: 'exp_004',
        tripId: 'trip_001',
        title: 'Flight',
        amount: 1250.99,
        date: DateTime(2025, 3, 1),
        category: 'Transport',
      );
      expect(bigExpense.amount, 1250.99);
    });

    // ── toMap ─────────────────────────────────────────────────────────────

    test('toMap contains all expected keys', () {
      final map = expense.toMap();
      expect(map.containsKey('id'), isTrue);
      expect(map.containsKey('tripId'), isTrue);
      expect(map.containsKey('title'), isTrue);
      expect(map.containsKey('amount'), isTrue);
      expect(map.containsKey('date'), isTrue);
      expect(map.containsKey('category'), isTrue);
      expect(map.containsKey('notes'), isTrue);
    });

    test('toMap encodes date as ISO 8601 string', () {
      final map = expense.toMap();
      expect(map['date'], isA<String>());
      expect(() => DateTime.parse(map['date'] as String), returnsNormally);
    });

    test('toMap date round-trips correctly', () {
      final map = expense.toMap();
      final parsed = DateTime.parse(map['date'] as String);
      expect(parsed.year, expense.date.year);
      expect(parsed.month, expense.date.month);
      expect(parsed.day, expense.date.day);
    });

    test('toMap preserves amount precision', () {
      final map = expense.toMap();
      expect(map['amount'], 8.50);
    });

    test('toMap includes null notes', () {
      final noNotes = Expense(
        id: 'e1',
        tripId: 't1',
        title: 'Taxi',
        amount: 5.0,
        date: DateTime.now(),
        category: 'Transport',
      );
      final map = noNotes.toMap();
      expect(map['notes'], isNull);
    });

    // ── Categories ────────────────────────────────────────────────────────

    test('expense can belong to Food category', () {
      expect(expense.category, 'Food');
    });

    test('expense can belong to any category string', () {
      final categories = ['Food', 'Transport', 'Hotel', 'Shopping', 'Other'];
      for (final cat in categories) {
        final e = Expense(
          id: 'e',
          tripId: 't',
          title: 'Test',
          amount: 10.0,
          date: DateTime.now(),
          category: cat,
        );
        expect(e.category, cat);
      }
    });
  });
}
