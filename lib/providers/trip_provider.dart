import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/trip.dart';

class TripProvider extends ChangeNotifier {
  List<Trip> _trips = [];
  Trip? _currentTrip;

  List<Trip> get trips => _trips;
  Trip? get currentTrip => _currentTrip;

  TripProvider() {
    _loadTrips();
  }

  Future<void> _loadTrips() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedTripsJson = prefs.getString('all_trips');
    if (savedTripsJson != null) {
      List<dynamic> decodedTrips = json.decode(savedTripsJson);
      _trips = decodedTrips.map((json) => Trip.fromJson(json)).toList();
      if (_trips.isNotEmpty) {
        String? lastTripId = prefs.getString('last_selected_trip_id');
        _currentTrip = _trips.firstWhere(
          (trip) => trip.id == lastTripId,
          orElse: () => _trips.first,
        );
      }
    }
    notifyListeners();
  }

  Future<void> _saveTrips() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString(
        'all_trips', json.encode(_trips.map((trip) => trip.toJson()).toList()));
    if (_currentTrip != null) {
      prefs.setString('last_selected_trip_id', _currentTrip!.id);
    }
  }

  void addTrip(Trip newTrip) {
    _trips.add(newTrip);
    _currentTrip = newTrip;
    _saveTrips();
    notifyListeners();
  }

  void selectTrip(Trip trip) {
    _currentTrip = trip;
    _saveTrips();
    notifyListeners();
  }

  void updateCurrentTripExpenses(List<Map<String, dynamic>> newExpenses) {
    if (_currentTrip != null) {
      _currentTrip!.expenses = newExpenses;
      _saveTrips();
      notifyListeners();
    }
  }

  void updateCurrentTrip(
      {String? name,
      double? budget,
      String? currency,
      DateTime? startDate,
      DateTime? endDate}) {
    if (_currentTrip != null) {
      if (name != null) _currentTrip!.name = name;
      if (budget != null) _currentTrip!.budget = budget;
      if (currency != null) _currentTrip!.currency = currency;
      if (startDate != null) _currentTrip!.startDate = startDate;
      if (endDate != null) _currentTrip!.endDate = endDate;
      _saveTrips();
      notifyListeners();
    }
  }

  void deleteTrip(String tripId) {
    _trips.removeWhere((trip) => trip.id == tripId);
    if (_currentTrip?.id == tripId) {
      _currentTrip = _trips.isNotEmpty ? _trips.first : null;
    }
    _saveTrips();
    notifyListeners();
  }

  void addExpenseToCurrentTrip(Map<String, dynamic> expense) {
    if (_currentTrip != null) {
      _currentTrip!.expenses.add(expense);
      _saveTrips();
      notifyListeners();
    }
  }

  void resetCurrentTripExpenses() {
    if (_currentTrip != null) {
      _currentTrip!.expenses.clear();
      _saveTrips();
      notifyListeners();
    }
  }
}
