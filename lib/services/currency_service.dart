import 'dart:convert';
import 'package:http/http.dart' as http;

class CurrencyService {
  final String _apiKey = '00cb5a6122f51697055a2f9a';
  final String _baseUrl = 'https://v6.exchangerate-api.com/v6/';

  Future<Map<String, double>> getExchangeRates(String baseCurrency) async {
    try {
      final response =
          await http.get(Uri.parse('$_baseUrl$_apiKey/latest/$baseCurrency'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['rates'] != null) {
          return Map<String, double>.from(data['rates']
              .map((key, value) => MapEntry(key, value.toDouble())));
        }
      }
      throw Exception('Failed to load exchange rates: ${response.statusCode}');
    } catch (e) {
      print('Error fetching exchange rates: $e');
      return {
        'USD': 1.0,
        'BDT': 120.0, // Example rate
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
