import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class CurrencyService {
  static const String _defaultApiKey = '00cb5a6122f51697055a2f9a';
  final String _apiKey;
  final String _baseUrl = 'https://v6.exchangerate-api.com/v6/';

  CurrencyService({String? apiKey})
      : _apiKey = apiKey ??
            const String.fromEnvironment('EXCHANGE_RATE_API_KEY',
                defaultValue: _defaultApiKey);

  Future<Map<String, double>> getExchangeRates(String baseCurrency) async {
    // 1. Attempt to fetch live rates from API
    try {
      final response =
          await http.get(Uri.parse('$_baseUrl$_apiKey/latest/$baseCurrency'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final ratesMap = data['conversion_rates'] ?? data['rates'];
        if (ratesMap != null && ratesMap is Map) {
          final rates = Map<String, double>.from(ratesMap.map((key, value) =>
              MapEntry(key.toString(), (value as num).toDouble())));

          // Cache live rates for offline use
          try {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString(
                'cached_rates_$baseCurrency', json.encode(rates));
          } catch (cacheErr) {
            debugPrint('Failed to save exchange rates to cache: $cacheErr');
          }

          return rates;
        }
      }
      throw Exception('Server responded with status: ${response.statusCode}');
    } catch (e) {
      debugPrint(
          'Network fetch for exchange rates failed ($e). Checking offline cache.');

      // 2. Fallback to cached offline rates
      try {
        final prefs = await SharedPreferences.getInstance();
        final cachedString = prefs.getString('cached_rates_$baseCurrency');
        if (cachedString != null) {
          final decoded = json.decode(cachedString) as Map<String, dynamic>;
          return decoded
              .map((k, v) => MapEntry(k, (v as num).toDouble()));
        }
      } catch (offlineErr) {
        debugPrint('Failed reading offline rates cache: $offlineErr');
      }

      // 3. Fallback to built-in default rates
      return {
        'USD': 1.0,
        'BDT': 120.0,
        'EUR': 0.92,
        'GBP': 0.79,
        'INR': 83.0,
      };
    }
  }

  Future<double> convertCurrency(
      double amount, String fromCurrency, String toCurrency) async {
    if (fromCurrency == toCurrency) {
      return amount;
    }
    Map<String, double> rates = await getExchangeRates(fromCurrency);
    if (rates.containsKey(toCurrency)) {
      return amount * rates[toCurrency]!;
    }
    return amount;
  }
}
