import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart'; // Import google_fonts

class ThemeProvider extends ChangeNotifier {
  ThemeData _themeData;
  double _fontSizeMultiplier = 1.0; // Default font size multiplier
  String _appCurrency = 'BDT'; // Default app-wide currency

  ThemeProvider(this._themeData, this._fontSizeMultiplier, this._appCurrency);

  ThemeData get themeData => _themeData;
  double get fontSizeMultiplier => _fontSizeMultiplier;
  String get appCurrency => _appCurrency;

  Null get currentTheme => null;

  void toggleTheme() async {
    if (_themeData.brightness == Brightness.dark) {
      _themeData = _buildTheme(Brightness.light, _fontSizeMultiplier);
    } else {
      _themeData = _buildTheme(Brightness.dark, _fontSizeMultiplier);
    }
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('isDarkTheme', _themeData.brightness == Brightness.dark);
    notifyListeners();
  }

  void setFontSizeMultiplier(double multiplier) async {
    _fontSizeMultiplier = multiplier;
    _themeData = _buildTheme(_themeData.brightness, _fontSizeMultiplier);
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setDouble('fontSizeMultiplier', multiplier);
    notifyListeners();
  }

  void setAppCurrency(String currency) async {
    _appCurrency = currency;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('appCurrency', currency);
    notifyListeners();
  }

  // Helper function to ensure fontSize is not null and then scale it
  static TextStyle? _ensureFontSizeAndScale(
      TextStyle? style, double multiplier) {
    if (style == null) return null;
    // Provide a default fontSize (e.g., 14.0) if it's null, then scale.
    // This prevents the assertion error if GoogleFonts or Flutter's defaults
    // ever provide a null fontSize for a specific TextStyle.
    double baseFontSize =
        style.fontSize ?? 14.0; // Use a sensible default if fontSize is null
    return style.copyWith(fontSize: baseFontSize * multiplier);
  }

  // Helper to build theme with selected font and size
  static ThemeData _buildTheme(
      Brightness brightness, double fontSizeMultiplier) {
    final baseTheme =
        brightness == Brightness.dark ? ThemeData.dark() : ThemeData.light();

    // Get a base TextTheme from GoogleFonts.
    TextTheme poppinsTextTheme = GoogleFonts.poppinsTextTheme();

    // Create a new TextTheme by explicitly copying each TextStyle and ensuring fontSize is not null.
    // Then apply the fontSizeMultiplier.
    TextTheme scaledTextTheme = poppinsTextTheme.copyWith(
      displayLarge: _ensureFontSizeAndScale(
          poppinsTextTheme.displayLarge, fontSizeMultiplier),
      displayMedium: _ensureFontSizeAndScale(
          poppinsTextTheme.displayMedium, fontSizeMultiplier),
      displaySmall: _ensureFontSizeAndScale(
          poppinsTextTheme.displaySmall, fontSizeMultiplier),
      headlineLarge: _ensureFontSizeAndScale(
          poppinsTextTheme.headlineLarge, fontSizeMultiplier),
      headlineMedium: _ensureFontSizeAndScale(
          poppinsTextTheme.headlineMedium, fontSizeMultiplier),
      headlineSmall: _ensureFontSizeAndScale(
          poppinsTextTheme.headlineSmall, fontSizeMultiplier),
      titleLarge: _ensureFontSizeAndScale(
          poppinsTextTheme.titleLarge, fontSizeMultiplier),
      titleMedium: _ensureFontSizeAndScale(
          poppinsTextTheme.titleMedium, fontSizeMultiplier),
      titleSmall: _ensureFontSizeAndScale(
          poppinsTextTheme.titleSmall, fontSizeMultiplier),
      bodyLarge: _ensureFontSizeAndScale(
          poppinsTextTheme.bodyLarge, fontSizeMultiplier),
      bodyMedium: _ensureFontSizeAndScale(
          poppinsTextTheme.bodyMedium, fontSizeMultiplier),
      bodySmall: _ensureFontSizeAndScale(
          poppinsTextTheme.bodySmall, fontSizeMultiplier),
      labelLarge: _ensureFontSizeAndScale(
          poppinsTextTheme.labelLarge, fontSizeMultiplier),
      labelMedium: _ensureFontSizeAndScale(
          poppinsTextTheme.labelMedium, fontSizeMultiplier),
      labelSmall: _ensureFontSizeAndScale(
          poppinsTextTheme.labelSmall, fontSizeMultiplier),
    );

    // Apply colors from the base theme's textTheme to the scaled text theme.
    // This ensures that the text colors match the overall theme (light/dark).
    TextTheme finalColoredTextTheme = scaledTextTheme.copyWith(
      displayLarge: scaledTextTheme.displayLarge
          ?.copyWith(color: baseTheme.textTheme.displayLarge?.color),
      displayMedium: scaledTextTheme.displayMedium
          ?.copyWith(color: baseTheme.textTheme.displayMedium?.color),
      displaySmall: scaledTextTheme.displaySmall
          ?.copyWith(color: baseTheme.textTheme.displaySmall?.color),
      headlineLarge: scaledTextTheme.headlineLarge
          ?.copyWith(color: baseTheme.textTheme.headlineLarge?.color),
      headlineMedium: scaledTextTheme.headlineMedium
          ?.copyWith(color: baseTheme.textTheme.headlineMedium?.color),
      headlineSmall: scaledTextTheme.headlineSmall
          ?.copyWith(color: baseTheme.textTheme.headlineSmall?.color),
      titleLarge: scaledTextTheme.titleLarge
          ?.copyWith(color: baseTheme.textTheme.titleLarge?.color),
      titleMedium: scaledTextTheme.titleMedium
          ?.copyWith(color: baseTheme.textTheme.titleMedium?.color),
      titleSmall: scaledTextTheme.titleSmall
          ?.copyWith(color: baseTheme.textTheme.titleSmall?.color),
      bodyLarge: scaledTextTheme.bodyLarge
          ?.copyWith(color: baseTheme.textTheme.bodyLarge?.color),
      bodyMedium: scaledTextTheme.bodyMedium
          ?.copyWith(color: baseTheme.textTheme.bodyMedium?.color),
      bodySmall: scaledTextTheme.bodySmall
          ?.copyWith(color: baseTheme.textTheme.bodySmall?.color),
      labelLarge: scaledTextTheme.labelLarge
          ?.copyWith(color: baseTheme.textTheme.labelLarge?.color),
      labelMedium: scaledTextTheme.labelMedium
          ?.copyWith(color: baseTheme.textTheme.labelMedium?.color),
      labelSmall: scaledTextTheme.labelSmall
          ?.copyWith(color: baseTheme.textTheme.labelSmall?.color),
    );

    return baseTheme.copyWith(
      textTheme: finalColoredTextTheme, // Use the final textTheme
      appBarTheme: baseTheme.appBarTheme.copyWith(
        backgroundColor:
            brightness == Brightness.dark ? Colors.grey[850] : Colors.blue,
        foregroundColor: Colors.white,
      ),
      floatingActionButtonTheme: baseTheme.floatingActionButtonTheme.copyWith(
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blueAccent, // Consistent button color
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      cardTheme: baseTheme.cardTheme.copyWith(
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
    );
  }

  static Future<ThemeProvider> init() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isDarkTheme = prefs.getBool('isDarkTheme') ?? false;
    double fontSizeMultiplier = prefs.getDouble('fontSizeMultiplier') ?? 1.0;
    String appCurrency =
        prefs.getString('appCurrency') ?? 'BDT'; // Load app currency

    return ThemeProvider(
      _buildTheme(
          isDarkTheme ? Brightness.dark : Brightness.light, fontSizeMultiplier),
      fontSizeMultiplier,
      appCurrency,
    );
  }
}
