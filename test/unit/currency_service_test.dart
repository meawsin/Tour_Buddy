import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'dart:convert';
import 'package:tour_buddy/services/currency_service.dart';

// A testable version of CurrencyService that accepts a custom http client
class TestableCurrencyService extends CurrencyService {
  final http.Client client;
  TestableCurrencyService(this.client);

  @override
  Future<Map<String, double>> getExchangeRates(String baseCurrency) async {
    try {
      final response = await client.get(
        Uri.parse(
            'https://v6.exchangerate-api.com/v6/TEST_KEY/latest/$baseCurrency'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['rates'] != null) {
          return Map<String, double>.from(
            data['rates'].map(
              (key, value) => MapEntry(key, (value as num).toDouble()),
            ),
          );
        }
      }
      throw Exception('Failed: ${response.statusCode}');
    } catch (e) {
      return {
        'USD': 1.0,
        'BDT': 120.0,
        'EUR': 0.92,
        'GBP': 0.79,
        'INR': 83.0,
      };
    }
  }
}

void main() {
  group('CurrencyService', () {
    // ── Fallback rates ────────────────────────────────────────────────────

    test('returns fallback rates on network error', () async {
      final mockClient = MockClient((_) async => http.Response('error', 500));
      final service = TestableCurrencyService(mockClient);

      final rates = await service.getExchangeRates('USD');
      expect(rates, isNotEmpty);
      expect(rates.containsKey('USD'), isTrue);
      expect(rates.containsKey('BDT'), isTrue);
    });

    test('fallback USD rate is 1.0', () async {
      final mockClient = MockClient((_) async => http.Response('', 503));
      final service = TestableCurrencyService(mockClient);

      final rates = await service.getExchangeRates('USD');
      expect(rates['USD'], 1.0);
    });

    test('fallback BDT rate is 120.0', () async {
      final mockClient = MockClient((_) async => http.Response('', 503));
      final service = TestableCurrencyService(mockClient);

      final rates = await service.getExchangeRates('USD');
      expect(rates['BDT'], 120.0);
    });

    // ── Successful API response ───────────────────────────────────────────

    test('parses rates from successful API response', () async {
      final fakeResponse = json.encode({
        'result': 'success',
        'base_code': 'USD',
        'rates': {
          'USD': 1.0,
          'EUR': 0.91,
          'GBP': 0.78,
          'BDT': 121.5,
          'JPY': 149.5,
        },
      });

      final mockClient =
          MockClient((_) async => http.Response(fakeResponse, 200));
      final service = TestableCurrencyService(mockClient);

      final rates = await service.getExchangeRates('USD');
      expect(rates['EUR'], closeTo(0.91, 0.001));
      expect(rates['JPY'], closeTo(149.5, 0.001));
    });

    test('all rate values are doubles', () async {
      final fakeResponse = json.encode({
        'rates': {'USD': 1, 'EUR': 0.91},
      });
      final mockClient =
          MockClient((_) async => http.Response(fakeResponse, 200));
      final service = TestableCurrencyService(mockClient);

      final rates = await service.getExchangeRates('USD');
      for (final val in rates.values) {
        expect(val, isA<double>());
      }
    });

    // ── convertCurrency ───────────────────────────────────────────────────

    test('same currency conversion returns same amount', () async {
      final service = CurrencyService();
      final result = await service.convertCurrency(100.0, 'USD', 'USD');
      expect(result, 100.0);
    });

    test('conversion uses rate correctly', () async {
      final fakeResponse = json.encode({
        'rates': {'BDT': 120.0},
      });
      final mockClient =
          MockClient((_) async => http.Response(fakeResponse, 200));
      final service = TestableCurrencyService(mockClient);

      final result = await service.convertCurrency(10.0, 'USD', 'BDT');
      expect(result, closeTo(1200.0, 0.01));
    });

    test('returns original amount if target currency not in rates', () async {
      final fakeResponse = json.encode({
        'rates': {'EUR': 0.91},
      });
      final mockClient =
          MockClient((_) async => http.Response(fakeResponse, 200));
      final service = TestableCurrencyService(mockClient);

      // XYZ is not in rates — should return original amount
      final result = await service.convertCurrency(50.0, 'USD', 'XYZ');
      expect(result, 50.0);
    });

    test('zero amount converts to zero', () async {
      final service = CurrencyService();
      final result = await service.convertCurrency(0.0, 'USD', 'USD');
      expect(result, 0.0);
    });
  });
}
