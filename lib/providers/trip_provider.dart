import 'package:flutter/foundation.dart';
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
      debugPrint("Error signing in anonymously: $e");
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return; // User cancelled

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final currentUser = _auth.currentUser;

      if (currentUser != null && currentUser.isAnonymous) {
        // Link anonymous account to Google — preserves all existing trip data
        try {
          await currentUser.linkWithCredential(credential);
          debugPrint("Linked anonymous account to Google: ${_auth.currentUser?.displayName}");
        } on FirebaseAuthException catch (e) {
          if (e.code == 'credential-already-in-use') {
            // Google account already exists — migrate trips then sign in
            debugPrint("Google account exists, migrating trips...");
            await _migrateTripsToGoogle(credential);
          } else {
            rethrow;
          }
        }
      } else {
        // Already signed in with Google or no user — just sign in normally
        await _auth.signInWithCredential(credential);
        debugPrint("Signed in with Google: ${_auth.currentUser?.displayName}");
      }
    } catch (e) {
      debugPrint("Error signing in with Google: $e");
    }
  }

  /// Copies trips from the anonymous account to the Google account
  Future<void> _migrateTripsToGoogle(AuthCredential credential) async {
    final anonymousUid = _auth.currentUser?.uid;

    // Fetch anonymous trips before signing out
    List<Map<String, dynamic>> tripsToMigrate = [];
    if (anonymousUid != null) {
      try {
        final snapshot = await _firestore
            .collection('trips')
            .doc(anonymousUid)
            .collection('userTrips')
            .get();
        tripsToMigrate = snapshot.docs.map((d) => d.data()).toList();
      } catch (e) {
        debugPrint("Could not fetch anonymous trips: $e");
      }
    }

    // Sign in with Google credential
    await _auth.signInWithCredential(credential);
    final googleUid = _auth.currentUser?.uid;
    debugPrint("Migrating ${tripsToMigrate.length} trips to Google account ($googleUid)");

    // Write trips to new Google account
    for (final trip in tripsToMigrate) {
      try {
        await _firestore
            .collection('trips')
            .doc(googleUid)
            .collection('userTrips')
            .add(trip);
      } catch (e) {
        debugPrint("Error migrating trip: $e");
      }
    }

    // Clean up old anonymous data
    if (anonymousUid != null && anonymousUid != googleUid) {
      try {
        final oldDocs = await _firestore
            .collection('trips')
            .doc(anonymousUid)
            .collection('userTrips')
            .get();
        for (final doc in oldDocs.docs) {
          await doc.reference.delete();
        }
      } catch (e) {
        debugPrint("Could not clean up anonymous trips: $e");
      }
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      await _googleSignIn.signOut();
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
        debugPrint("Error listening to trips: $error");
      });
    } catch (e) {
      debugPrint("Error loading trips: $e");
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
      debugPrint("Trip added: ${trip.name}");
    } catch (e) {
      debugPrint("Error adding trip: $e");
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
      debugPrint("Error updating trip details: $e");
    }
  }

  Future<void> addExpenseToCurrentTrip(
      Trip trip, Map<String, dynamic> expense) async {
    if (_currentUser == null || trip.id == null) return;

    try {
      // arrayUnion appends atomically server-side — prevents stale overwrites
      await _firestore
          .collection('trips')
          .doc(_currentUser!.uid)
          .collection('userTrips')
          .doc(trip.id)
          .update({'expenses': FieldValue.arrayUnion([expense])});
    } catch (e) {
      debugPrint("Error adding expense: $e");
    }
  }

  Future<void> deleteExpenseFromTrip(
      Trip trip, Map<String, dynamic> expense) async {
    if (_currentUser == null || trip.id == null) return;

    try {
      await _firestore
          .collection('trips')
          .doc(_currentUser!.uid)
          .collection('userTrips')
          .doc(trip.id)
          .update({'expenses': FieldValue.arrayRemove([expense])});
    } catch (e) {
      debugPrint("Error deleting expense: $e");
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
      debugPrint("Error resetting expenses: $e");
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
      debugPrint("Error deleting trip: $e");
    }
  }

  // --- Financial Calculations ---

  double calculateTotalSpent(List<Expense> expenses, String tripId) {
    return expenses
        .where((e) => e.tripId == tripId)
        .fold(0.0, (acc, item) => acc + item.amount);
  }

  double calculateRemainingBudget(double totalBudget, double totalSpent) {
    return totalBudget - totalSpent;
  }

  double getBudgetUtilization(double totalBudget, double totalSpent) {
    if (totalBudget <= 0) return 0.0;
    return (totalSpent / totalBudget).clamp(0.0, 1.0);
  }
}
