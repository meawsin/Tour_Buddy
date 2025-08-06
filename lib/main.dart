import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme_provider.dart';
import 'screens/start_screen.dart';
import 'providers/trip_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  ThemeProvider themeProvider = await ThemeProvider.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => themeProvider),
        ChangeNotifierProvider(
            create: (_) => TripProvider()), // Provide TripProvider
      ],
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
      home: StartScreen(), // Set StartScreen as the home
    );
  }
}
