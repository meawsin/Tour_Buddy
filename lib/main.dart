import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme_provider.dart';
import 'expense_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  ThemeProvider themeProvider = await ThemeProvider.init();

  runApp(
    ChangeNotifierProvider(
      create: (_) => themeProvider,
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Tour Buddy',
      theme: Provider.of<ThemeProvider>(context).themeData,
      home: ExpenseScreen(),
    );
  }
}
