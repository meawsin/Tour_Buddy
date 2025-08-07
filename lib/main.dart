import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:tour_buddy/firebase_options.dart';
import 'package:tour_buddy/providers/trip_provider.dart';
import 'package:tour_buddy/screens/start_screen.dart';
import 'package:tour_buddy/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final tripProvider = TripProvider();
  await tripProvider
      .signInWithCanvasToken(); // Handle initial anonymous/canvas token sign-in

  final themeProvider =
      await ThemeProvider.init(); // Initialize ThemeProvider asynchronously

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: tripProvider),
        ChangeNotifierProvider.value(
            value: themeProvider), // Provide the initialized ThemeProvider
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return MaterialApp(
      title: 'Tour Buddy',
      theme: themeProvider.themeData, // Use themeData from the provider
      home: const StartScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
