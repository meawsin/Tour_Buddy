import 'package:flutter_test/flutter_test.dart';
import 'package:tour_buddy/models/trip.dart';

// Pure logic extracted from BudgetAlertService for unit testing
// (the real service uses SharedPreferences which requires device)

enum AlertLevel { none, halfway, low, exceeded }

AlertLevel computeAlertLevel(Trip trip) {
  if (trip.budget <= 0) return AlertLevel.none;

  final total = trip.expenses.fold<double>(
    0,
    (sum, e) => sum + (e['amount'] as num? ?? 0).toDouble(),
  );

  final ratio = total / trip.budget;

  if (ratio >= 1.0) return AlertLevel.exceeded;
  if (ratio >= 0.8) return AlertLevel.low;
  if (ratio >= 0.5) return AlertLevel.halfway;
  return AlertLevel.none;
}

double computeTotalSpent(Trip trip) {
  return trip.expenses.fold<double>(
    0,
    (sum, e) => sum + (e['amount'] as num? ?? 0).toDouble(),
  );
}

void main() {
  Trip makeTrip(double budget, List<double> amounts) {
    return Trip(
      name: 'Test',
      destination: 'Somewhere',
      startDate: DateTime(2025, 1, 1),
      endDate: DateTime(2025, 1, 10),
      budget: budget,
      currency: 'USD',
      expenses: amounts
          .map((a) => {
                'id': 'e${amounts.indexOf(a)}',
                'title': 'Expense',
                'amount': a,
                'category': 'Other',
              })
          .toList(),
    );
  }

  group('Budget alert thresholds', () {
    test('no alert when under 50%', () {
      final trip = makeTrip(1000, [300, 100]); // 40% used
      expect(computeAlertLevel(trip), AlertLevel.none);
    });

    test('halfway alert at exactly 50%', () {
      final trip = makeTrip(1000, [500]); // 50%
      expect(computeAlertLevel(trip), AlertLevel.halfway);
    });

    test('halfway alert at 70% (50-79% range)', () {
      final trip = makeTrip(1000, [700]); // 70% — still in halfway zone
      expect(computeAlertLevel(trip), AlertLevel.halfway);
    });

    test('low alert at exactly 80%', () {
      final trip = makeTrip(1000, [800]); // 80%
      expect(computeAlertLevel(trip), AlertLevel.low);
    });

    test('exceeded alert at exactly 100%', () {
      final trip = makeTrip(1000, [1000]); // 100%
      expect(computeAlertLevel(trip), AlertLevel.exceeded);
    });

    test('exceeded alert over 100%', () {
      final trip = makeTrip(1000, [600, 600]); // 120%
      expect(computeAlertLevel(trip), AlertLevel.exceeded);
    });

    test('no alert when budget is zero (no budget set)', () {
      final trip = makeTrip(0, [500]);
      expect(computeAlertLevel(trip), AlertLevel.none);
    });

    test('no alert on empty expenses', () {
      final trip = makeTrip(1000, []);
      expect(computeAlertLevel(trip), AlertLevel.none);
    });
  });

  group('Total spent computation', () {
    test('sums all expense amounts correctly', () {
      final trip = makeTrip(500, [100.0, 50.0, 25.50]);
      expect(computeTotalSpent(trip), closeTo(175.50, 0.001));
    });

    test('returns 0 for empty expenses', () {
      final trip = makeTrip(500, []);
      expect(computeTotalSpent(trip), 0.0);
    });

    test('handles single expense', () {
      final trip = makeTrip(500, [99.99]);
      expect(computeTotalSpent(trip), closeTo(99.99, 0.001));
    });

    test('handles null amounts gracefully', () {
      final trip = Trip(
        name: 'Null Test',
        destination: 'Nowhere',
        startDate: DateTime(2025, 1, 1),
        endDate: DateTime(2025, 1, 5),
        budget: 500.0,
        currency: 'USD',
        expenses: [
          {'id': 'e1', 'title': 'Bad data', 'amount': null, 'category': 'Other'},
          {'id': 'e2', 'title': 'Good', 'amount': 50.0, 'category': 'Food'},
        ],
      );
      // Null amount should be treated as 0
      expect(computeTotalSpent(trip), closeTo(50.0, 0.001));
    });

    test('accumulates many small expenses', () {
      final amounts = List.generate(100, (i) => 1.0);
      final trip = makeTrip(200, amounts);
      expect(computeTotalSpent(trip), closeTo(100.0, 0.001));
    });
  });

  group('Edge cases', () {
    test('trip spanning year boundary is valid', () {
      final trip = Trip(
        name: 'NYE Trip',
        destination: 'NYC',
        startDate: DateTime(2024, 12, 28),
        endDate: DateTime(2025, 1, 3),
        budget: 2000.0,
        currency: 'USD',
        expenses: [
          {'id': 'e1', 'amount': 500.0, 'title': 'Hotel', 'category': 'Hotel'},
        ],
      );
      expect(computeTotalSpent(trip), 500.0);
      expect(computeAlertLevel(trip), AlertLevel.none); // 25%
    });

    test('very small amounts do not trigger false alerts', () {
      final trip = makeTrip(1000, [0.01, 0.01]); // negligible
      expect(computeAlertLevel(trip), AlertLevel.none);
    });

    test('exactly 49.9% does not trigger halfway alert', () {
      final trip = makeTrip(1000, [499.0]);
      expect(computeAlertLevel(trip), AlertLevel.none);
    });
  });
}
