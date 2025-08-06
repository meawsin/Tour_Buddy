import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme_provider.dart';
import 'package:google_fonts/google_fonts.dart'; // Import GoogleFonts

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key}); // Added key for best practice

  // Helper function to format currency display (copied from other screens)
  String _formatCurrency(String currencyCode, double amount) {
    String symbol;
    switch (currencyCode) {
      case 'BDT':
        symbol = '৳';
        break;
      case 'USD':
        symbol = '\$';
        break;
      case 'EUR':
        symbol = '€';
        break;
      case 'GBP':
        symbol = '£';
        break;
      case 'INR':
        symbol = '₹';
        break;
      default:
        symbol = currencyCode; // Fallback to code if symbol not defined
    }
    return '$symbol ${amount.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            elevation: 4,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Theme',
                    style: GoogleFonts.poppins(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  ListTile(
                    title: const Text('Dark Mode'),
                    trailing: Switch(
                      value:
                          themeProvider.themeData.brightness == Brightness.dark,
                      onChanged: (value) {
                        themeProvider.toggleTheme();
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            elevation: 4,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Font Size',
                    style: GoogleFonts.poppins(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Slider(
                    value: themeProvider.fontSizeMultiplier,
                    min: 0.8,
                    max: 1.2,
                    divisions: 4,
                    label: themeProvider.fontSizeMultiplier.toStringAsFixed(1),
                    onChanged: (newValue) {
                      themeProvider.setFontSizeMultiplier(newValue);
                    },
                  ),
                  Center(
                    child: Text(
                      'Example Text Size',
                      style: GoogleFonts.poppins(
                          fontSize: 16 * themeProvider.fontSizeMultiplier),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            elevation: 4,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'App Currency',
                    style: GoogleFonts.poppins(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: themeProvider.appCurrency,
                    decoration: InputDecoration(
                      labelText: 'Select Default Currency',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                    ),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        themeProvider.setAppCurrency(newValue);
                      }
                    },
                    items: <String>['BDT', 'USD', 'EUR', 'GBP', 'INR']
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Current App Currency: ${_formatCurrency(themeProvider.appCurrency, 100.0)} (Example)', // Example usage
                    style: GoogleFonts.poppins(
                        fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
