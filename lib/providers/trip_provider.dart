import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:tour_buddy/models/expense_model.dart';
import 'package:tour_buddy/models/trip.dart';

class TripProvider with ChangeNotifier {
  List<Trip> _trips = [];
  User? _currentUser;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  TripProvider() {
    _auth.authStateChanges().listen((user) {
      _currentUser = user;
      if (user != null) {
        _loadTrips();
      } else {
        _trips = [];
        notifyListeners();
      }
    });
    _signInAnonymously();
  }

  List<Trip> get trips => _trips;
  User? get currentUser => _currentUser;

  // --- Authentication Methods ---

  Future<void> _signInAnonymously() async {
    try {
      if (_auth.currentUser == null) {
        await _auth.signInAnonymously();
      }
    } catch (e) {
      print("Error signing in anonymously: $e");
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return; // User cancelled

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication; // ✅ Fixed: removed extra !

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

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      await _googleSignIn.signOut();
      print("User signed out.");
    } catch (e) {
      print("Error signing out: $e");
    }
  }

  Future<void> signInWithCanvasToken() async {
    try {
      final String? initialAuthToken =
          (const String.fromEnvironment('INITIAL_AUTH_TOKEN') == 'null' ||
                  const String.fromEnvironment('INITIAL_AUTH_TOKEN').isEmpty)
              ? null
              : const String.fromEnvironment('INITIAL_AUTH_TOKEN');

      if (initialAuthToken != null && initialAuthToken.isNotEmpty) {
        await _auth.signInWithCustomToken(initialAuthToken);
        print("Signed in with custom token.");
      } else {
        await _signInAnonymously();
      }
    } catch (e) {
      print("Error during Canvas token sign-in: $e");
      await _signInAnonymously();
    }
  }

  // --- Firestore Data Operations ---

  Future<void> _loadTrips() async {
    if (_currentUser == null) {
      _trips = [];
      notifyListeners();
      return;
    }

    try {
      _firestore
          .collection('trips')
          .doc(_currentUser!.uid)
          .collection('userTrips')
          .snapshots()
          .listen((snapshot) {
        _trips = snapshot.docs.map((doc) => Trip.fromFirestore(doc)).toList();
        notifyListeners();
      }, onError: (error) {
        print("Error listening to trips: $error");
      });
    } catch (e) {
      print("Error loading trips: $e");
    }
  }

  Future<void> addTrip(Trip trip) async {
    if (_currentUser == null) return;

    try {
      DocumentReference docRef = await _firestore
          .collection('trips')
          .doc(_currentUser!.uid)
          .collection('userTrips')
          .add(trip.toMap());
      trip.id = docRef.id;
      notifyListeners();
      print("Trip added: ${trip.name}");
    } catch (e) {
      print("Error adding trip: $e");
    }
  }

  Future<void> updateTrip(Trip trip) async {
    if (_currentUser == null || trip.id == null) return;

    try {
      await _firestore
          .collection('trips')
          .doc(_currentUser!.uid)
          .collection('userTrips')
          .doc(trip.id)
          .update(trip.toMap());
      notifyListeners();
    } catch (e) {
      print("Error updating trip: $e");
    }
  }

  Future<void> updateCurrentTrip({
    required Trip trip,
    double? budget,
    String? currency,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (_currentUser == null || trip.id == null) return;

    try {
      Map<String, dynamic> updates = {};
      if (budget != null) updates['budget'] = budget;
      if (currency != null) updates['currency'] = currency;
      if (startDate != null) updates['startDate'] = Timestamp.fromDate(startDate);
      if (endDate != null) updates['endDate'] = Timestamp.fromDate(endDate);

      if (updates.isNotEmpty) {
        await _firestore
            .collection('trips')
            .doc(_currentUser!.uid)
            .collection('userTrips')
            .doc(trip.id)
            .update(updates);
      }
    } catch (e) {
      print("Error updating trip details: $e");
    }
  }

  Future<void> addExpenseToCurrentTrip(
      Trip trip, Map<String, dynamic> expense) async {
    if (_currentUser == null || trip.id == null) return;

    try {
      List<Map<String, dynamic>> updatedExpenses = List.from(trip.expenses);
      updatedExpenses.add(expense);

      await _firestore
          .collection('trips')
          .doc(_currentUser!.uid)
          .collection('userTrips')
          .doc(trip.id)
          .update({'expenses': updatedExpenses});
    } catch (e) {
      print("Error adding expense: $e");
    }
  }

  Future<void> resetCurrentTripExpenses(Trip trip) async {
    if (_currentUser == null || trip.id == null) return;

    try {
      await _firestore
          .collection('trips')
          .doc(_currentUser!.uid)
          .collection('userTrips')
          .doc(trip.id)
          .update({'expenses': []});
    } catch (e) {
      print("Error resetting expenses: $e");
    }
  }

  void selectTrip(Trip trip) {
    notifyListeners();
  }

  Future<void> deleteTrip(String tripId) async {
    if (_currentUser == null) return;

    try {
      await _firestore
          .collection('trips')
          .doc(_currentUser!.uid)
          .collection('userTrips')
          .doc(tripId)
          .delete();
      notifyListeners();
    } catch (e) {
      print("Error deleting trip: $e");
    }
  }

  // --- Financial Calculations ---

  double calculateTotalSpent(List<Expense> expenses, String tripId) {
    return expenses
        .where((e) => e.tripId == tripId)
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  double calculateRemainingBudget(double totalBudget, double totalSpent) {
    return totalBudget - totalSpent;
  }

  double getBudgetUtilization(double totalBudget, double totalSpent) {
    if (totalBudget <= 0) return 0.0;
    return (totalSpent / totalBudget).clamp(0.0, 1.0);
  }
}