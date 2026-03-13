// integration_test/expense_flow_test.dart
//
// ⚠️  Run ONLY with a connected device:
//     flutter test integration_test/expense_flow_test.dart
//
// Do NOT include in `flutter test test/` — Firebase requires a real device.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:tour_buddy/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('app launches and shows UI', (tester) async {
    app.main();
    // Give Firebase time to initialise
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(seconds: 3));
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
