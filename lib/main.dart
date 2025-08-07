import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // Import Firebase Core
import 'package:provider/provider.dart';
import 'package:tour_buddy/firebase_options.dart'; // Import the generated Firebase options
import 'package:tour_buddy/providers/trip_provider.dart';
import 'package:tour_buddy/screens/start_screen.dart';
import 'package:tour_buddy/theme_provider.dart'; // Ensure this import is correct

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Ensure Firebase is initialized before accessing any Firebase services
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Create an instance of TripProvider
  final tripProvider = TripProvider();
  // Call the sign-in method to ensure a user is authenticated
  await tripProvider.signInWithCanvasToken();

  runApp(
    MultiProvider(
      providers: [
        // Provide the existing instance of TripProvider
        ChangeNotifierProvider.value(value: tripProvider),
        ChangeNotifierProvider(
            create: (context) => ThemeProvider(ThemeData.light(), 1.0, 'BDT')),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Access ThemeProvider from the widget tree
    final themeProvider = Provider.of<ThemeProvider>(context);
    return MaterialApp(
      title: 'Tour Buddy',
      theme: themeProvider.currentTheme,
      home: const StartScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
