import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum BudgetAlertLevel { none, half, warning, exceeded }

class BudgetAlert {
  final BudgetAlertLevel level;
  final double percent;
  final String tripId;

  const BudgetAlert({
    required this.level,
    required this.percent,
    required this.tripId,
  });

  String get title {
    switch (level) {
      case BudgetAlertLevel.half:
        return 'Halfway through budget';
      case BudgetAlertLevel.warning:
        return 'Budget running low';
      case BudgetAlertLevel.exceeded:
        return 'Budget exceeded';
      case BudgetAlertLevel.none:
        return '';
    }
  }

  String get message {
    final pct = (percent * 100).toInt();
    switch (level) {
      case BudgetAlertLevel.half:
        return "You've used $pct% of your budget. Spend wisely for the rest of the trip.";
      case BudgetAlertLevel.warning:
        return "You've used $pct% of your budget. Only ${100 - pct}% remaining.";
      case BudgetAlertLevel.exceeded:
        return "You're ${pct - 100}% over budget. Consider adjusting your spending.";
      case BudgetAlertLevel.none:
        return '';
    }
  }
}

class BudgetAlertService extends ChangeNotifier {
  // Map of tripId → dismissed alert levels (persisted)
  final Map<String, Set<BudgetAlertLevel>> _dismissed = {};

  // Map of tripId → current active alert
  final Map<String, BudgetAlert?> _activeAlerts = {};

  static BudgetAlertService? _instance;
  static BudgetAlertService get instance {
    _instance ??= BudgetAlertService._();
    return _instance!;
  }

  BudgetAlertService._();

  BudgetAlert? alertFor(String tripId) => _activeAlerts[tripId];

  /// Called every time an expense is added or the screen is built.
  /// Returns the alert level that should be shown, if any.
  BudgetAlert? checkBudget({
    required String tripId,
    required double totalSpent,
    required double budget,
  }) {
    if (budget <= 0) {
      _activeAlerts[tripId] = null;
      return null;
    }

    final ratio = totalSpent / budget;
    BudgetAlertLevel level;

    if (ratio >= 1.0) {
      level = BudgetAlertLevel.exceeded;
    } else if (ratio >= 0.8) {
      level = BudgetAlertLevel.warning;
    } else if (ratio >= 0.5) {
      level = BudgetAlertLevel.half;
    } else {
      level = BudgetAlertLevel.none;
    }

    if (level == BudgetAlertLevel.none) {
      _activeAlerts[tripId] = null;
      return null;
    }

    final dismissed = _dismissed[tripId] ?? {};

    // If this exact level was dismissed, check if a higher level applies
    if (dismissed.contains(level)) {
      // Check if there's a higher undismissed level
      if (level != BudgetAlertLevel.exceeded &&
          ratio >= 1.0 &&
          !dismissed.contains(BudgetAlertLevel.exceeded)) {
        level = BudgetAlertLevel.exceeded;
      } else {
        _activeAlerts[tripId] = null;
        return null;
      }
    }

    final alert = BudgetAlert(level: level, percent: ratio, tripId: tripId);
    _activeAlerts[tripId] = alert;
    return alert;
  }

  /// Dismiss an alert for a trip at a given level
  Future<void> dismiss(String tripId, BudgetAlertLevel level) async {
    _dismissed.putIfAbsent(tripId, () => {}).add(level);
    _activeAlerts[tripId] = null;
    notifyListeners();
    await _persist(tripId);
  }

  /// Reset dismissed alerts when expenses are reset
  Future<void> resetForTrip(String tripId) async {
    _dismissed.remove(tripId);
    _activeAlerts.remove(tripId);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('alert_dismissed_$tripId');
  }

  /// Load dismissed alerts from storage
  Future<void> loadForTrip(String tripId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getStringList('alert_dismissed_$tripId') ?? [];
      _dismissed[tripId] = stored
          .map((s) => BudgetAlertLevel.values.firstWhere(
                (l) => l.name == s,
                orElse: () => BudgetAlertLevel.none,
              ))
          .where((l) => l != BudgetAlertLevel.none)
          .toSet();
    } catch (e) {
      debugPrint('BudgetAlertService: error loading for $tripId: $e');
    }
  }

  Future<void> _persist(String tripId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final levels = (_dismissed[tripId] ?? {})
          .map((l) => l.name)
          .toList();
      await prefs.setStringList('alert_dismissed_$tripId', levels);
    } catch (e) {
      debugPrint('BudgetAlertService: error persisting for $tripId: $e');
    }
  }
}
