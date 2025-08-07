import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tour_buddy/models/trip.dart';

class TripProvider with ChangeNotifier {
  List<Trip> _trips = [];
  User? _currentUser; // To store the current authenticated user

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  TripProvider() {
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
    _signInAnonymously(); // Attempt anonymous sign-in on startup
  }

  List<Trip> get trips => _trips;

  // --- Authentication Methods ---
  Future<void> _signInAnonymously() async {
    try {
      if (_auth.currentUser == null) {
        // Only sign in anonymously if no user is currently signed in
        await _auth.signInAnonymously();
        print("Signed in anonymously.");
      }
    } catch (e) {
      print("Error signing in anonymously: $e");
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
      return;
    }

    try {
      // Listen for real-time updates to the user's trips
      _firestore
          .collection('trips')
          .doc(_currentUser!.uid)
          .collection('userTrips')
          .snapshots()
          .listen((snapshot) {
        _trips = snapshot.docs.map((doc) => Trip.fromFirestore(doc)).toList();
        notifyListeners();
        print("Trips loaded/updated from Firestore.");
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
      // _trips.add(trip); // No need to add to local list, snapshot listener will update
      notifyListeners();
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
      // No need to update local list, snapshot listener will update
      notifyListeners();
      print("Trip updated in Firestore: ${trip.name}");
    } catch (e) {
      print("Error updating trip: $e");
    }
  }

  // New method to update trip details (budget, currency, dates) for a specific trip
  Future<void> updateCurrentTrip({
    required Trip trip, // Now requires a specific trip object
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
      if (startDate != null)
        updates['startDate'] = Timestamp.fromDate(startDate);
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

  // New method to add expense to a specific trip
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

  // New method to reset expenses for a specific trip
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
  // Note: This is a simplified approach. For a more robust solution,
  // you might store the selected trip ID in a state variable or pass it explicitly.
  void selectTrip(Trip trip) {
    // In this simplified setup, we don't need to do much here
    // as operations now take a 'trip' object directly.
    // However, if you had a concept of a single "active" trip globally,
    // you would set it here.
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
      // No need to remove from local list, snapshot listener will update
      notifyListeners();
      print("Trip deleted from Firestore: $tripId");
    } catch (e) {
      print("Error deleting trip: $e");
    }
  }
}
