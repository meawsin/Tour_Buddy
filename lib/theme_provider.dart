import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  bool _isDarkMode;
  double _fontSizeScale;
  String _currency;

  ThemeProvider({
    bool isDarkMode = true,
    double fontSizeScale = 1.0,
    String currency = 'BDT',
  })  : _isDarkMode = isDarkMode,
        _fontSizeScale = fontSizeScale,
        _currency = currency;

  bool get isDarkMode => _isDarkMode;
  double get fontSizeScale => _fontSizeScale;
  String get currency => _currency;

  static Future<ThemeProvider> init() async {
    final prefs = await SharedPreferences.getInstance();
    return ThemeProvider(
      isDarkMode: prefs.getBool('isDarkMode') ?? true,
      fontSizeScale: prefs.getDouble('fontSizeScale') ?? 1.0,
      currency: prefs.getString('currency') ?? 'BDT',
    );
  }

  void toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', _isDarkMode);
    notifyListeners();
  }

  void setFontSizeScale(double scale) async {
    _fontSizeScale = scale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('fontSizeScale', scale);
    notifyListeners();
  }

  void setCurrency(String currency) async {
    _currency = currency;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('currency', currency);
    notifyListeners();
  }

  ThemeData get themeData {
    final base = _isDarkMode ? _darkTheme : _lightTheme;
    return base.copyWith(
      textTheme: base.textTheme.apply(fontSizeFactor: _fontSizeScale),
    );
  }

  static final _darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.dark(
      primary: const Color(0xFF7C6AFF),
      secondary: const Color(0xFF6AFFD4),
      tertiary: const Color(0xFFFF6A9B),
      surface: const Color(0xFF12121A),
      onSurface: const Color(0xFFF0EEFF),
      surfaceContainerHighest: const Color(0xFF1A1A26),
      outline: const Color(0xFF2A2A3A),
    ),
    scaffoldBackgroundColor: const Color(0xFF0A0A0F),
    cardColor: const Color(0xFF12121A),
    textTheme: GoogleFonts.dmSansTextTheme(ThemeData.dark().textTheme).copyWith(
      displayLarge: GoogleFonts.syne(
          fontWeight: FontWeight.w700, color: const Color(0xFFF0EEFF)),
      displayMedium: GoogleFonts.syne(
          fontWeight: FontWeight.w600, color: const Color(0xFFF0EEFF)),
      titleLarge: GoogleFonts.syne(
          fontWeight: FontWeight.w600, color: const Color(0xFFF0EEFF)),
      titleMedium: GoogleFonts.syne(
          fontWeight: FontWeight.w500, color: const Color(0xFFF0EEFF)),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: const Color(0xFF0A0A0F),
      elevation: 0,
      centerTitle: false,
      titleTextStyle: GoogleFonts.syne(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: const Color(0xFFF0EEFF),
      ),
      iconTheme: const IconThemeData(color: Color(0xFFF0EEFF)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF7C6AFF),
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: GoogleFonts.syne(fontWeight: FontWeight.w600, fontSize: 15),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF1A1A26),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF2A2A3A)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF2A2A3A)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF7C6AFF), width: 1.5),
      ),
      labelStyle: const TextStyle(color: Color(0xFF8888AA)),
      hintStyle: const TextStyle(color: Color(0xFF8888AA)),
    ),
    cardTheme: CardThemeData(
      color: const Color(0xFF12121A),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFF2A2A3A)),
      ),
    ),
    dividerColor: const Color(0xFF2A2A3A),
  );

  static final _lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.light(
      primary: const Color(0xFF5B4AE8),
      secondary: const Color(0xFF00C9A7),
      tertiary: const Color(0xFFE8446A),
      surface: const Color(0xFFFFFFFF),
      onSurface: const Color(0xFF1A1A2E),
      surfaceContainerHighest: const Color(0xFFF4F3FF),
      outline: const Color(0xFFE0DFFF),
    ),
    scaffoldBackgroundColor: const Color(0xFFF7F6FF),
    cardColor: const Color(0xFFFFFFFF),
    textTheme:
        GoogleFonts.dmSansTextTheme(ThemeData.light().textTheme).copyWith(
      displayLarge: GoogleFonts.syne(
          fontWeight: FontWeight.w700, color: const Color(0xFF1A1A2E)),
      displayMedium: GoogleFonts.syne(
          fontWeight: FontWeight.w600, color: const Color(0xFF1A1A2E)),
      titleLarge: GoogleFonts.syne(
          fontWeight: FontWeight.w600, color: const Color(0xFF1A1A2E)),
      titleMedium: GoogleFonts.syne(
          fontWeight: FontWeight.w500, color: const Color(0xFF1A1A2E)),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: const Color(0xFFF7F6FF),
      elevation: 0,
      centerTitle: false,
      titleTextStyle: GoogleFonts.syne(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF1A1A2E),
      ),
      iconTheme: const IconThemeData(color: Color(0xFF1A1A2E)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF5B4AE8),
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: GoogleFonts.syne(fontWeight: FontWeight.w600, fontSize: 15),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFF4F3FF),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE0DFFF)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE0DFFF)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF5B4AE8), width: 1.5),
      ),
      labelStyle: const TextStyle(color: Color(0xFF8888AA)),
      hintStyle: const TextStyle(color: Color(0xFF8888AA)),
    ),
    cardTheme: CardThemeData(
      color: const Color(0xFFFFFFFF),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE0DFFF)),
      ),
    ),
    dividerColor: const Color(0xFFE0DFFF),
  );
}
