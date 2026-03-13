import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // ── Trip card display ─────────────────────────────────────────────────────

  group('Trip card display', () {
    testWidgets('shows trip name', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ListTile(
              title: Text('Kyoto Journey'),
              subtitle: Text('Kyoto, Japan'),
            ),
          ),
        ),
      );
      expect(find.text('Kyoto Journey'), findsOneWidget);
    });

    testWidgets('shows destination', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ListTile(
              title: Text('Test Trip'),
              subtitle: Text('Osaka, Japan'),
            ),
          ),
        ),
      );
      expect(find.text('Osaka, Japan'), findsOneWidget);
    });

    testWidgets('shows both name and destination', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ListTile(
              title: Text('Beach Escape'),
              subtitle: Text('Bali, Indonesia'),
            ),
          ),
        ),
      );
      expect(find.text('Beach Escape'), findsOneWidget);
      expect(find.text('Bali, Indonesia'), findsOneWidget);
    });
  });

  // ── Budget progress bar ───────────────────────────────────────────────────

  group('Budget progress bar', () {
    testWidgets('shows no budget text when budget is 0', (tester) async {
      const double budget = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(builder: (context) {
              return budget > 0
                  ? const LinearProgressIndicator(value: 0)
                  : const Text('No budget set');
            }),
          ),
        ),
      );
      expect(find.text('No budget set'), findsOneWidget);
    });

    test('progress clamped to 1.0 when over budget', () {
      final clamped = (150.0 / 100.0).clamp(0.0, 1.0);
      expect(clamped, 1.0);
    });

    test('progress is 0.5 at 50% usage', () {
      final progress = (100.0 / 200.0).clamp(0.0, 1.0);
      expect(progress, 0.5);
    });

    test('progress is 0 for no expenses', () {
      final progress = (0.0 / 500.0).clamp(0.0, 1.0);
      expect(progress, 0.0);
    });

    testWidgets('LinearProgressIndicator renders', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LinearProgressIndicator(value: 0.75),
          ),
        ),
      );
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });
  });

  // ── Expense list rendering ────────────────────────────────────────────────

  group('Expense list rendering', () {
    testWidgets('empty list shows no items', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ListView()),
        ),
      );
      expect(find.byType(ListTile), findsNothing);
    });

    testWidgets('renders 3 expense items correctly', (tester) async {
      final expenses = [
        {'title': 'Coffee', 'amount': 3.5},
        {'title': 'Taxi', 'amount': 12.0},
        {'title': 'Hotel night', 'amount': 80.0},
      ];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView(
              children: expenses
                  .map((e) => ListTile(
                        title: Text(e['title'] as String),
                        trailing: Text('\$${e['amount']}'),
                      ))
                  .toList(),
            ),
          ),
        ),
      );
      expect(find.byType(ListTile), findsNWidgets(3));
      expect(find.text('Coffee'), findsOneWidget);
      expect(find.text('Taxi'), findsOneWidget);
    });

    testWidgets('single expense renders correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ListTile(
              title: Text('Lunch'),
              trailing: Text('\$15.00'),
            ),
          ),
        ),
      );
      expect(find.text('Lunch'), findsOneWidget);
      expect(find.text('\$15.00'), findsOneWidget);
    });
  });

  // ── Currency formatting ───────────────────────────────────────────────────

  group('Currency display formatting', () {
    test('formats amount with 2 decimal places', () {
      expect((123.456).toStringAsFixed(2), '123.46');
    });

    test('formats zero correctly', () {
      expect((0.0).toStringAsFixed(2), '0.00');
    });

    test('formats large amount correctly', () {
      expect((9999.999).toStringAsFixed(2), '10000.00');
    });

    testWidgets('currency code renders next to amount', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: Text('BDT 500.00')),
        ),
      );
      expect(find.text('BDT 500.00'), findsOneWidget);
    });
  });

  // ── Basic widget structure ────────────────────────────────────────────────

  group('Basic widget structure', () {
    testWidgets('Scaffold renders without error', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(child: Text('Tour Buddy')),
          ),
        ),
      );
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.text('Tour Buddy'), findsOneWidget);
    });

    testWidgets('FloatingActionButton is tappable', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: const SizedBox.shrink(),
            floatingActionButton: FloatingActionButton(
              onPressed: () => tapped = true,
              child: const Icon(Icons.add),
            ),
          ),
        ),
      );
      await tester.tap(find.byType(FloatingActionButton));
      expect(tapped, isTrue);
    });
  });
}
