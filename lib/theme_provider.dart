import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeData _themeData;

  ThemeProvider(this._themeData);

  ThemeData get themeData => _themeData;

  void toggleTheme() async {
    if (_themeData.brightness == Brightness.dark) {
      _themeData = ThemeData.light();
    } else {
      _themeData = ThemeData.dark();
    }

    // Save the theme preference
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('isDarkTheme', _themeData.brightness == Brightness.dark);

    notifyListeners();
  }

  static Future<ThemeProvider> init() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isDarkTheme = prefs.getBool('isDarkTheme') ?? false;
    return ThemeProvider(isDarkTheme ? ThemeData.dark() : ThemeData.light());
  }
}
