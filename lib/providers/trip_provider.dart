import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart'; // Import Google Sign-In
import 'package:tour_buddy/models/expense_model.dart';
import 'package:tour_buddy/models/trip.dart';

class TripProvider with ChangeNotifier {
  List<Trip> _trips = [];
  User? _currentUser; // To store the current authenticated user

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(); // Google Sign-In instance

  TripProvider() {
    // Listen for authentication state changes
    _auth.authStateChanges().listen((user) {
      _currentUser = user;
      if (user != null) {
        // User signed in or re-authenticated, load their trips
        _loadTrips();
      } else {
        // User signed out, clear trips
        _trips = [];
        notifyListeners();
      }
    });
    // Attempt anonymous sign-in on startup if no user is present
    // This is a fallback if no explicit sign-in is performed.
    _signInAnonymously();
  }

  List<Trip> get trips => _trips;
  User? get currentUser => _currentUser;

  // --- Authentication Methods ---

  // Anonymous sign-in (fallback or initial anonymous usage)
  Future<void> _signInAnonymously() async {
    try {
      if (_auth.currentUser == null) {
        await _auth.signInAnonymously();
      }
    } catch (e) {
      print("Error signing in anonymously: $e");
    }
  }

  // Google Sign-In
  Future<void> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // The user canceled the sign-in
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await _auth.signInWithCredential(credential);
      print("Signed in with Google: ${_auth.currentUser?.displayName}");
    } catch (e) {
      print("Error signing in with Google: $e");
    }
  }

  // Sign out method
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      await _googleSignIn.signOut(); // Also sign out from Google
      print("User signed out.");
    } catch (e) {
      print("Error signing out: $e");
    }
  }

  // This function will be called by the Canvas environment to sign in the user
  // with a custom token. If no token is provided, it signs in anonymously.
  Future<void> signInWithCanvasToken() async {
    try {
      final String? initialAuthToken =
          (const String.fromEnvironment('INITIAL_AUTH_TOKEN') == 'null' ||
                  const String.fromEnvironment('INITIAL_AUTH_TOKEN').isEmpty)
              ? null
              : const String.fromEnvironment('INITIAL_AUTH_TOKEN');

      if (initialAuthToken != null && initialAuthToken.isNotEmpty) {
        // Sign in with the provided custom token
        await _auth.signInWithCustomToken(initialAuthToken);
        print("Signed in with custom token.");
      } else {
        // If no custom token, sign in anonymously
        await _signInAnonymously();
      }
    } catch (e) {
      print("Error during Canvas token sign-in: $e");
      // Fallback to anonymous sign-in if custom token fails
      await _signInAnonymously();
    }
  }

  // --- Firestore Data Operations ---

  // Load trips from Firestore for the current user
  Future<void> _loadTrips() async {
    if (_currentUser == null) {
      print("No user logged in to load trips.");
      _trips = []; // Clear trips if no user
      notifyListeners();
      return;
    }

    try {
      // Listen for real-time updates to the user's trips
      _firestore
          .collection('trips')
          .doc(_currentUser!.uid) // Use current user's UID
          .collection('userTrips')
          .snapshots()
          .listen((snapshot) {
        _trips = snapshot.docs.map((doc) => Trip.fromFirestore(doc)).toList();
        notifyListeners();
        print(
            "Trips loaded/updated from Firestore for user: ${_currentUser!.uid}");
      }, onError: (error) {
        print("Error listening to trips: $error");
      });
    } catch (e) {
      print("Error loading trips: $e");
    }
  }

  // Add a new trip to Firestore
  Future<void> addTrip(Trip trip) async {
    if (_currentUser == null) {
      print("No user logged in. Cannot add trip.");
      return;
    }

    try {
      DocumentReference docRef = await _firestore
          .collection('trips')
          .doc(_currentUser!.uid)
          .collection('userTrips')
          .add(trip.toMap());
      trip.id = docRef.id; // Assign the Firestore generated ID
      notifyListeners(); // Notify listeners to update UI
      print("Trip added to Firestore: ${trip.name}");
    } catch (e) {
      print("Error adding trip: $e");
    }
  }

  // Update an existing trip in Firestore
  Future<void> updateTrip(Trip trip) async {
    if (_currentUser == null || trip.id == null) {
      print("No user logged in or trip ID missing. Cannot update trip.");
      return;
    }

    try {
      await _firestore
          .collection('trips')
          .doc(_currentUser!.uid)
          .collection('userTrips')
          .doc(trip.id)
          .update(trip.toMap());
      notifyListeners(); // Notify listeners to update UI
      print("Trip updated in Firestore: ${trip.name}");
    } catch (e) {
      print("Error updating trip: $e");
    }
  }

  // Update trip details (budget, currency, dates) for a specific trip
  Future<void> updateCurrentTrip({
    required Trip trip, // Requires a specific trip object
    double? budget,
    String? currency,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (_currentUser == null || trip.id == null) {
      print("No user logged in or trip ID missing. Cannot update trip.");
      return;
    }

    try {
      Map<String, dynamic> updates = {};
      if (budget != null) updates['budget'] = budget;
      if (currency != null) updates['currency'] = currency;
      if (startDate != null) {
        updates['startDate'] = Timestamp.fromDate(startDate);
      }
      if (endDate != null) updates['endDate'] = Timestamp.fromDate(endDate);

      if (updates.isNotEmpty) {
        await _firestore
            .collection('trips')
            .doc(_currentUser!.uid)
            .collection('userTrips')
            .doc(trip.id)
            .update(updates);
        print("Trip details updated in Firestore for trip: ${trip.name}.");
      }
    } catch (e) {
      print("Error updating trip details: $e");
    }
  }

  // Add expense to a specific trip
  Future<void> addExpenseToCurrentTrip(
      Trip trip, Map<String, dynamic> expense) async {
    if (_currentUser == null || trip.id == null) {
      print("No user logged in or trip ID missing. Cannot add expense.");
      return;
    }

    try {
      List<Map<String, dynamic>> updatedExpenses = List.from(trip.expenses);
      updatedExpenses.add(expense);

      await _firestore
          .collection('trips')
          .doc(_currentUser!.uid)
          .collection('userTrips')
          .doc(trip.id)
          .update({'expenses': updatedExpenses});
      print("Expense added to trip: ${trip.name} in Firestore.");
    } catch (e) {
      print("Error adding expense to trip: $e");
    }
  }

  // Reset expenses for a specific trip
  Future<void> resetCurrentTripExpenses(Trip trip) async {
    if (_currentUser == null || trip.id == null) {
      print("No user logged in or trip ID missing. Cannot reset expenses.");
      return;
    }

    try {
      await _firestore
          .collection('trips')
          .doc(_currentUser!.uid)
          .collection('userTrips')
          .doc(trip.id)
          .update({'expenses': []}); // Set expenses to an empty list
      print("Expenses reset for trip: ${trip.name} in Firestore.");
    } catch (e) {
      print("Error resetting expenses for trip: $e");
    }
  }

  // Selects a trip to be considered the "current" trip for immediate operations
  // This method is now primarily for UI state management.
  void selectTrip(Trip trip) {
    // In a multi-trip scenario, you might want to store the selected trip
    // in a provider state, but for now, it mostly triggers UI updates.
    print("Trip selected: ${trip.name}");
    notifyListeners(); // Notify listeners if this selection affects UI
  }

  // Delete a trip from Firestore
  Future<void> deleteTrip(String tripId) async {
    if (_currentUser == null) {
      print("No user logged in. Cannot delete trip.");
      return;
    }

    try {
      await _firestore
          .collection('trips')
          .doc(_currentUser!.uid)
          .collection('userTrips')
          .doc(tripId)
          .delete();
      notifyListeners(); // Notify listeners to update UI
      print("Trip deleted from Firestore: $tripId");
    } catch (e) {
      print("Error deleting trip: $e");
    }
  }


  // Logic to calculate trip financials
double calculateTotalSpent(List<Expense> expenses, String tripId) {
  return expenses
      .where((e) => e.tripId == tripId)
      .fold(0.0, (sum, item) => sum + item.amount);
}

double calculateRemainingBudget(double totalBudget, double totalSpent) {
  return totalBudget - totalSpent;
}

// Visual progress bar percentage (for UI) [5]
double getBudgetUtilization(double totalBudget, double totalSpent) {
  if (totalBudget <= 0) return 0.0;
  return (totalSpent / totalBudget).clamp(0.0, 1.0);
}
}
