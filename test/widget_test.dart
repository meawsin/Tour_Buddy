import 'package:flutter_test/flutter_test.dart';
import 'package:tour_buddy/models/expense.dart';
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
  });

  group('Trip Model Tests', () {
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
      );

      final map = trip.toMap();
      expect(map['name'], 'Sylhet Tour');
      expect(map['budget'], 15000.0);
      expect(map['expenses'], isA<List>());
      expect((map['expenses'] as List).length, 1);
    });
  });

  group('CurrencyService Tests', () {
    test('convertCurrency returns same amount when currencies match', () async {
      final service = CurrencyService();
      final result = await service.convertCurrency(100.0, 'USD', 'USD');
      expect(result, 100.0);
    });
  });
}
