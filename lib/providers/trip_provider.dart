import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:tour_buddy/models/trip.dart';
import 'package:tour_buddy/models/expense.dart';

class TripProvider with ChangeNotifier {
  List<Trip> _trips = [];
  User? _currentUser;
  StreamSubscription<QuerySnapshot>? _tripsSubscription;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  TripProvider() {
    _auth.authStateChanges().listen((user) {
      _currentUser = user;
      if (user != null) {
        _loadTrips();
      } else {
        _tripsSubscription?.cancel();
        _tripsSubscription = null;
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
      debugPrint("Error signing in anonymously: $e");
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await _auth.signInWithCredential(credential);
      debugPrint("Signed in with Google: ${_auth.currentUser?.displayName}");
    } catch (e) {
      debugPrint("Error signing in with Google: $e");
    }
  }

  Future<void> signOut() async {
    try {
      await _tripsSubscription?.cancel();
      _tripsSubscription = null;
      await _auth.signOut();
      await _googleSignIn.signOut();
      _trips = [];
      notifyListeners();
      debugPrint("User signed out.");
    } catch (e) {
      debugPrint("Error signing out: $e");
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
        debugPrint("Signed in with custom token.");
      } else {
        await _signInAnonymously();
      }
    } catch (e) {
      debugPrint("Error during Canvas token sign-in: $e");
      await _signInAnonymously();
    }
  }

  // --- Firestore Data Operations ---

  Future<void> _loadTrips() async {
    if (_currentUser == null) {
      debugPrint("No user logged in to load trips.");
      _trips = [];
      notifyListeners();
      return;
    }

    try {
      await _tripsSubscription?.cancel();
      _tripsSubscription = _firestore
          .collection('trips')
          .doc(_currentUser!.uid)
          .collection('userTrips')
          .snapshots()
          .listen((snapshot) {
        _trips = snapshot.docs.map((doc) => Trip.fromFirestore(doc)).toList();
        notifyListeners();
        debugPrint("Trips loaded/updated from Firestore for user: ${_currentUser!.uid}");
      }, onError: (error) {
        debugPrint("Error listening to trips: $error");
      });
    } catch (e) {
      debugPrint("Error loading trips: $e");
    }
  }

  Future<void> addTrip(Trip trip) async {
    if (_currentUser == null) {
      debugPrint("No user logged in. Cannot add trip.");
      return;
    }

    try {
      DocumentReference docRef = await _firestore
          .collection('trips')
          .doc(_currentUser!.uid)
          .collection('userTrips')
          .add(trip.toMap());
      trip.id = docRef.id;
      if (!_trips.any((t) => t.id == trip.id)) {
        _trips.add(trip);
      }
      notifyListeners();
      debugPrint("Trip added to Firestore: ${trip.name}");
    } catch (e) {
      debugPrint("Error adding trip: $e");
    }
  }

  Future<void> updateTrip(Trip trip) async {
    if (_currentUser == null || trip.id == null) {
      debugPrint("No user logged in or trip ID missing. Cannot update trip.");
      return;
    }

    try {
      await _firestore
          .collection('trips')
          .doc(_currentUser!.uid)
          .collection('userTrips')
          .doc(trip.id)
          .update(trip.toMap());
      final index = _trips.indexWhere((t) => t.id == trip.id);
      if (index != -1) {
        _trips[index] = trip;
      }
      notifyListeners();
      debugPrint("Trip updated in Firestore: ${trip.name}");
    } catch (e) {
      debugPrint("Error updating trip: $e");
    }
  }

  Future<void> updateCurrentTrip({
    required Trip trip,
    double? budget,
    String? currency,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (_currentUser == null || trip.id == null) {
      debugPrint("No user logged in or trip ID missing. Cannot update trip.");
      return;
    }

    try {
      Map<String, dynamic> updates = {};
      if (budget != null) {
        updates['budget'] = budget;
        trip.budget = budget;
      }
      if (currency != null) {
        updates['currency'] = currency;
        trip.currency = currency;
      }
      if (startDate != null) {
        updates['startDate'] = Timestamp.fromDate(startDate);
        trip.startDate = startDate;
      }
      if (endDate != null) {
        updates['endDate'] = Timestamp.fromDate(endDate);
        trip.endDate = endDate;
      }

      if (updates.isNotEmpty) {
        notifyListeners();
        await _firestore
            .collection('trips')
            .doc(_currentUser!.uid)
            .collection('userTrips')
            .doc(trip.id)
            .update(updates);
        debugPrint("Trip details updated in Firestore for trip: ${trip.name}.");
      }
    } catch (e) {
      debugPrint("Error updating trip details: $e");
    }
  }

  Future<void> addExpenseToCurrentTrip(Trip trip, Expense expense) async {
    if (_currentUser == null || trip.id == null) {
      debugPrint("No user logged in or trip ID missing. Cannot add expense.");
      return;
    }

    try {
      trip.expenses.add(expense);
      notifyListeners();

      await _firestore
          .collection('trips')
          .doc(_currentUser!.uid)
          .collection('userTrips')
          .doc(trip.id)
          .update({
        'expenses': trip.expenses.map((e) => e.toMap()).toList(),
      });
      debugPrint("Expense added to trip: ${trip.name} in Firestore.");
    } catch (e) {
      debugPrint("Error adding expense to trip: $e");
    }
  }

  Future<void> updateExpenseInCurrentTrip(Trip trip, Expense updatedExpense) async {
    if (_currentUser == null || trip.id == null) {
      debugPrint("No user logged in or trip ID missing. Cannot update expense.");
      return;
    }

    try {
      final index = trip.expenses.indexWhere((e) => e.id == updatedExpense.id);
      if (index != -1) {
        trip.expenses[index] = updatedExpense;
        notifyListeners();

        await _firestore
            .collection('trips')
            .doc(_currentUser!.uid)
            .collection('userTrips')
            .doc(trip.id)
            .update({
          'expenses': trip.expenses.map((e) => e.toMap()).toList(),
        });
        debugPrint("Expense updated for trip: ${trip.name} in Firestore.");
      }
    } catch (e) {
      debugPrint("Error updating expense in trip: $e");
    }
  }

  Future<void> deleteExpenseFromCurrentTrip(Trip trip, String expenseId) async {
    if (_currentUser == null || trip.id == null) {
      debugPrint("No user logged in or trip ID missing. Cannot delete expense.");
      return;
    }

    try {
      trip.expenses.removeWhere((e) => e.id == expenseId);
      notifyListeners();

      await _firestore
          .collection('trips')
          .doc(_currentUser!.uid)
          .collection('userTrips')
          .doc(trip.id)
          .update({
        'expenses': trip.expenses.map((e) => e.toMap()).toList(),
      });
      debugPrint("Expense deleted from trip: ${trip.name} in Firestore.");
    } catch (e) {
      debugPrint("Error deleting expense from trip: $e");
    }
  }

  Future<void> updateTripNotes(Trip trip, String notes) async {
    if (_currentUser == null || trip.id == null) {
      debugPrint("No user logged in or trip ID missing.");
      return;
    }

    try {
      trip.notes = notes;
      notifyListeners();

      await _firestore
          .collection('trips')
          .doc(_currentUser!.uid)
          .collection('userTrips')
          .doc(trip.id)
          .update({'notes': notes});
      debugPrint("Notes updated for trip: ${trip.name}");
    } catch (e) {
      debugPrint("Error updating trip notes: $e");
    }
  }

  Future<void> resetCurrentTripExpenses(Trip trip) async {
    if (_currentUser == null || trip.id == null) {
      debugPrint("No user logged in or trip ID missing. Cannot reset expenses.");
      return;
    }

    try {
      trip.expenses.clear();
      notifyListeners();

      await _firestore
          .collection('trips')
          .doc(_currentUser!.uid)
          .collection('userTrips')
          .doc(trip.id)
          .update({'expenses': []});
      debugPrint("Expenses reset for trip: ${trip.name} in Firestore.");
    } catch (e) {
      debugPrint("Error resetting expenses for trip: $e");
    }
  }

  void selectTrip(Trip trip) {
    debugPrint("Trip selected: ${trip.name}");
    notifyListeners();
  }

  Future<void> deleteTrip(String tripId) async {
    if (_currentUser == null) {
      debugPrint("No user logged in. Cannot delete trip.");
      return;
    }

    try {
      _trips.removeWhere((t) => t.id == tripId);
      notifyListeners();

      await _firestore
          .collection('trips')
          .doc(_currentUser!.uid)
          .collection('userTrips')
          .doc(tripId)
          .delete();
      debugPrint("Trip deleted from Firestore: $tripId");
    } catch (e) {
      debugPrint("Error deleting trip: $e");
    }
  }

  @override
  void dispose() {
    _tripsSubscription?.cancel();
    super.dispose();
  }
}
