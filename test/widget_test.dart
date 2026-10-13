import 'package:flutter_test/flutter_test.dart';
import 'package:tour_buddy/models/expense.dart';
import 'package:tour_buddy/models/expense_category.dart';
import 'package:tour_buddy/models/trip.dart';
import 'package:tour_buddy/services/currency_service.dart';

void main() {
  group('Expense Model Tests', () {
    test('Expense converts to and from Map accurately', () {
      final now = DateTime(2026, 5, 10, 14, 30);
      final expense = Expense(
        id: 'exp-123',
        title: 'Dinner at Beach',
        amount: 45.50,
        category: 'Food',
        date: now,
        foreignAmount: 40.0,
        foreignCurrency: 'EUR',
      );

      final map = expense.toMap();
      expect(map['id'], 'exp-123');
      expect(map['title'], 'Dinner at Beach');
      expect(map['amount'], 45.50);
      expect(map['category'], 'Food');
      expect(map['date'], '2026-05-10 14:30');
      expect(map['foreignAmount'], 40.0);
      expect(map['foreignCurrency'], 'EUR');

      final parsed = Expense.fromMap(map);
      expect(parsed.id, 'exp-123');
      expect(parsed.title, 'Dinner at Beach');
      expect(parsed.amount, 45.50);
      expect(parsed.category, 'Food');
      expect(parsed.foreignAmount, 40.0);
      expect(parsed.foreignCurrency, 'EUR');
    });

    test('Expense handles null/missing fields gracefully', () {
      final parsed = Expense.fromMap({
        'title': 'Coffee',
        'amount': 5, // int instead of double
      });

      expect(parsed.title, 'Coffee');
      expect(parsed.amount, 5.0);
      expect(parsed.category, 'Other');
      expect(parsed.id.isNotEmpty, true);
    });

    test('Expense copyWith updates target fields and retains others', () {
      final original = Expense(
        id: 'e1',
        title: 'Taxi',
        amount: 15.0,
        category: 'Transport',
        date: DateTime(2026, 6, 1),
      );

      final updated = original.copyWith(
        amount: 20.0,
        title: 'Airport Taxi',
      );

      expect(updated.id, 'e1');
      expect(updated.title, 'Airport Taxi');
      expect(updated.amount, 20.0);
      expect(updated.category, 'Transport');
      expect(updated.date, DateTime(2026, 6, 1));
    });
  });

  group('Trip Model & Calculation Tests', () {
    test('Trip serialization handles expenses list', () {
      final trip = Trip(
        id: 'trip-1',
        name: 'Sylhet Tour',
        destination: 'Sylhet',
        startDate: DateTime(2026, 6, 1),
        endDate: DateTime(2026, 6, 5),
        budget: 15000.0,
        currency: 'BDT',
        expenses: [
          Expense(
            id: 'e1',
            title: 'Bus Ticket',
            amount: 1200.0,
            category: 'Transport',
            date: DateTime(2026, 6, 1),
          ),
        ],
        notes: 'Hotel: Grand Sylhet\nDay 1: Ratargul',
      );

      final map = trip.toMap();
      expect(map['name'], 'Sylhet Tour');
      expect(map['budget'], 15000.0);
      expect(map['notes'], 'Hotel: Grand Sylhet\nDay 1: Ratargul');
      expect(map['expenses'], isA<List>());
      expect((map['expenses'] as List).length, 1);
    });

    test('Calculates total expenses and remaining budget accurately', () {
      final trip = Trip(
        id: 'trip-2',
        name: 'Cox\'s Bazar',
        destination: 'Cox\'s Bazar',
        startDate: DateTime(2026, 7, 1),
        endDate: DateTime(2026, 7, 4),
        budget: 20000.0,
        currency: 'BDT',
        expenses: [
          Expense(
            id: 'e1',
            title: 'Hotel',
            amount: 8000.0,
            category: 'Accommodation',
            date: DateTime(2026, 7, 1),
          ),
          Expense(
            id: 'e2',
            title: 'Dinner',
            amount: 2500.0,
            category: 'Food',
            date: DateTime(2026, 7, 1),
          ),
        ],
      );

      final totalExpense = trip.expenses.fold(0.0, (sum, e) => sum + e.amount);
      final remaining = trip.budget - totalExpense;
      final isOverBudget = totalExpense > trip.budget;

      expect(totalExpense, 10500.0);
      expect(remaining, 9500.0);
      expect(isOverBudget, false);
    });

    test('Detects over-budget threshold correctly', () {
      final trip = Trip(
        id: 'trip-3',
        name: 'Quick Weekend',
        destination: 'Sajek',
        startDate: DateTime(2026, 8, 1),
        endDate: DateTime(2026, 8, 2),
        budget: 5000.0,
        currency: 'BDT',
        expenses: [
          Expense(
            id: 'e1',
            title: 'Jeep Ride',
            amount: 3500.0,
            category: 'Transport',
            date: DateTime(2026, 8, 1),
          ),
          Expense(
            id: 'e2',
            title: 'Resort',
            amount: 3000.0,
            category: 'Accommodation',
            date: DateTime(2026, 8, 1),
          ),
        ],
      );

      final totalExpense = trip.expenses.fold(0.0, (sum, e) => sum + e.amount);
      final isOverBudget = totalExpense > trip.budget;
      final overAmount = totalExpense - trip.budget;

      expect(totalExpense, 6500.0);
      expect(isOverBudget, true);
      expect(overAmount, 1500.0);
    });

    test('Computes daily average burn rate correctly', () {
      final startDate = DateTime(2026, 6, 1);
      final endDate = DateTime(2026, 6, 4); // 4 days inclusive
      final tripDays = endDate.difference(startDate).inDays + 1;
      expect(tripDays, 4);

      const totalExpense = 12000.0;
      final dailyAvg = totalExpense / tripDays;
      expect(dailyAvg, 3000.0);
    });
  });

  group('ExpenseCategory Tests', () {
    test('Resolves standard category names correctly', () {
      expect(ExpenseCategory.getCategory('Food').name, 'Food');
      expect(ExpenseCategory.getCategory('Transport').name, 'Transport');
      expect(ExpenseCategory.getCategory('Accommodation').name, 'Accommodation');
      expect(ExpenseCategory.getCategory('Shopping').name, 'Shopping');
      expect(ExpenseCategory.getCategory('Activities').name, 'Activities');
      expect(ExpenseCategory.getCategory('Other').name, 'Other');
    });

    test('Resolves Stay and Hotel aliases to Accommodation', () {
      expect(ExpenseCategory.getCategory('Stay').name, 'Accommodation');
      expect(ExpenseCategory.getCategory('stay').name, 'Accommodation');
      expect(ExpenseCategory.getCategory('Hotel').name, 'Accommodation');
    });

    test('Falls back to Other for unrecognized categories or null', () {
      expect(ExpenseCategory.getCategory('Unicorn').name, 'Other');
      expect(ExpenseCategory.getCategory(null).name, 'Other');
    });
  });

  group('CurrencyService Tests', () {
    test('convertCurrency returns same amount when currencies match', () async {
      final service = CurrencyService();
      final result = await service.convertCurrency(100.0, 'USD', 'USD');
      expect(result, 100.0);
    });
  });

  group('Expense Sorting Logic Tests', () {
    final e1 = Expense(
      id: '1',
      title: 'B',
      amount: 100.0,
      category: 'Food',
      date: DateTime(2026, 1, 1),
    );
    final e2 = Expense(
      id: '2',
      title: 'A',
      amount: 50.0,
      category: 'Transport',
      date: DateTime(2026, 1, 2),
    );
    final e3 = Expense(
      id: '3',
      title: 'C',
      amount: 200.0,
      category: 'Accommodation',
      date: DateTime(2026, 1, 3),
    );

    final list = [e1, e2, e3];

    test('Sorts by amount descending', () {
      final sorted = List<Expense>.from(list)..sort((a, b) => b.amount.compareTo(a.amount));
      expect(sorted.map((e) => e.amount).toList(), [200.0, 100.0, 50.0]);
    });

    test('Sorts by amount ascending', () {
      final sorted = List<Expense>.from(list)..sort((a, b) => a.amount.compareTo(b.amount));
      expect(sorted.map((e) => e.amount).toList(), [50.0, 100.0, 200.0]);
    });

    test('Sorts by date descending (newest first)', () {
      final sorted = List<Expense>.from(list)..sort((a, b) => b.date.compareTo(a.date));
      expect(sorted.map((e) => e.id).toList(), ['3', '2', '1']);
    });

    test('Sorts by date ascending (oldest first)', () {
      final sorted = List<Expense>.from(list)..sort((a, b) => a.date.compareTo(b.date));
      expect(sorted.map((e) => e.id).toList(), ['1', '2', '3']);
    });

    test('Sorts by category ascending', () {
      final sorted = List<Expense>.from(list)..sort((a, b) => a.category.compareTo(b.category));
      expect(sorted.map((e) => e.category).toList(), ['Accommodation', 'Food', 'Transport']);
    });
  });
}
