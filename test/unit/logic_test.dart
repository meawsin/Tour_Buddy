// test/unit/logic_test.dart
// Pure business logic tests — no device needed, run with: flutter test test/

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Expense total computation', () {
    test('total of empty list is 0', () {
      final List<Map<String, dynamic>> expenses = [];
      final total = expenses.fold<double>(
        0, (s, e) => s + (e['amount'] as num? ?? 0).toDouble());
      expect(total, 0.0);
    });

    test('total of multiple expenses is correct', () {
      final expenses = [
        {'amount': 10.0},
        {'amount': 25.50},
        {'amount': 7.25},
      ];
      final total = expenses.fold<double>(
        0, (s, e) => s + (e['amount'] as num? ?? 0).toDouble());
      expect(total, closeTo(42.75, 0.001));
    });

    test('null amounts are treated as 0', () {
      final expenses = [
        {'amount': null},
        {'amount': 50.0},
      ];
      final total = expenses.fold<double>(
        0, (s, e) => s + (e['amount'] as num? ?? 0).toDouble());
      expect(total, 50.0);
    });

    test('by-category grouping is correct', () {
      final expenses = [
        {'amount': 10.0, 'category': 'Food'},
        {'amount': 15.0, 'category': 'Food'},
        {'amount': 20.0, 'category': 'Transport'},
        {'amount': 5.0, 'category': 'Other'},
      ];
      final byCategory = <String, double>{};
      for (final e in expenses) {
        final cat = (e['category'] as String?) ?? 'Other';
        byCategory[cat] =
            (byCategory[cat] ?? 0) + (e['amount'] as num? ?? 0).toDouble();
      }
      expect(byCategory['Food'], 25.0);
      expect(byCategory['Transport'], 20.0);
      expect(byCategory['Other'], 5.0);
    });
  });

  group('Date range logic', () {
    test('trip duration in days is correct', () {
      final start = DateTime(2025, 3, 1);
      final end = DateTime(2025, 3, 10);
      expect(end.difference(start).inDays, 9);
    });

    test('single day trip has duration of 0', () {
      final date = DateTime(2025, 6, 15);
      expect(date.difference(date).inDays, 0);
    });

    test('expenses can be filtered by date range', () {
      final start = DateTime(2025, 3, 1);
      final end = DateTime(2025, 3, 5);
      final expenses = [
        {'date': '2025-03-02', 'amount': 10.0},
        {'date': '2025-03-04', 'amount': 20.0},
        {'date': '2025-03-07', 'amount': 30.0}, // out of range
      ];
      final inRange = expenses.where((e) {
        final d = DateTime.parse(e['date'] as String);
        return !d.isBefore(start) && !d.isAfter(end);
      }).toList();
      expect(inRange, hasLength(2));
    });
  });

  group('Sorting logic', () {
    test('expenses sort by amount descending', () {
      final expenses = [
        {'title': 'A', 'amount': 10.0},
        {'title': 'B', 'amount': 50.0},
        {'title': 'C', 'amount': 25.0},
      ];
      expenses.sort((a, b) =>
          (b['amount'] as double).compareTo(a['amount'] as double));
      expect(expenses.first['title'], 'B');
      expect(expenses.last['title'], 'A');
    });

    test('expenses sort by date descending', () {
      final expenses = [
        {'date': '2025-03-01', 'title': 'Old'},
        {'date': '2025-03-10', 'title': 'New'},
        {'date': '2025-03-05', 'title': 'Mid'},
      ];
      expenses.sort((a, b) =>
          (b['date'] as String).compareTo(a['date'] as String));
      expect(expenses.first['title'], 'New');
      expect(expenses.last['title'], 'Old');
    });
  });
}
