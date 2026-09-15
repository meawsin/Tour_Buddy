import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/trip_provider.dart';
import 'expense_screen.dart';
import 'start_screen.dart';
import 'settings_screen.dart';

class PastTripsScreen extends StatefulWidget {
  const PastTripsScreen({super.key});

  @override
  State<PastTripsScreen> createState() => _PastTripsScreenState();
}

class _PastTripsScreenState extends State<PastTripsScreen> {
  bool _showAll = false;

  @override
  Widget build(BuildContext context) {
    final tripProvider = Provider.of<TripProvider>(context);
    final today = DateTime.now();
    final todayDateOnly = DateTime(today.year, today.month, today.day);

    final completedTrips = tripProvider.trips.where((t) {
      final tripEndDate =
          DateTime(t.endDate.year, t.endDate.month, t.endDate.day);
      return tripEndDate.isBefore(todayDateOnly);
    }).toList();

    final displayedTrips = _showAll ? tripProvider.trips : completedTrips;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Past Trips'),
        actions: [
          IconButton(
            icon: const Icon(Icons.home_outlined),
            tooltip: 'Home',
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const StartScreen()),
                (route) => false,
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (tripProvider.trips.isNotEmpty && completedTrips.isEmpty && !_showAll)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.blue, size: 20),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'All your trips are currently active or upcoming.',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _showAll = true;
                      });
                    },
                    child: const Text('Show All'),
                  ),
                ],
              ),
            ),
          Expanded(
            child: displayedTrips.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history_rounded,
                            size: 64, color: Colors.grey[350]),
                        const SizedBox(height: 16),
                        Text(
                          'No completed trips yet.',
                          style:
                              TextStyle(fontSize: 17, color: Colors.grey[700]),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Trips whose end dates have passed will appear here.',
                          style:
                              TextStyle(fontSize: 13, color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: displayedTrips.length,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemBuilder: (context, index) {
                      final trip = displayedTrips[index];
                      final totalSpent =
                          trip.expenses.fold(0.0, (sum, e) => sum + e.amount);

                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 6),
                        child: InkWell(
                          onTap: () {
                            tripProvider.selectTrip(trip);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ExpenseScreen(trip: trip),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.grey.withValues(alpha: 0.12),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        trip.name,
                                        style: const TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline,
                                          color: Colors.redAccent, size: 20),
                                      tooltip: 'Delete Trip',
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      onPressed: () {
                                        if (trip.id != null) {
                                          _showDeleteConfirmationDialog(
                                              context,
                                              tripProvider,
                                              trip.id!,
                                              trip.name);
                                        }
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(Icons.location_on_outlined,
                                        size: 15, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Text(
                                      trip.destination,
                                      style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey[700]),
                                    ),
                                    const SizedBox(width: 12),
                                    const Icon(Icons.calendar_today_outlined,
                                        size: 14, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${DateFormat('MMM d').format(trip.startDate)} - ${DateFormat('MMM d, yyyy').format(trip.endDate)}',
                                      style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey[700]),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Total Spent: ${trip.currency} ${totalSpent.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: trip.budget > 0 &&
                                                totalSpent > trip.budget
                                            ? Colors.red
                                            : null,
                                      ),
                                    ),
                                    if (trip.budget > 0)
                                      Text(
                                        'Budget: ${trip.currency} ${trip.budget.toStringAsFixed(0)}',
                                        style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey[600]),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmationDialog(
      BuildContext context, TripProvider tripProvider, String tripId, String tripName) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Trip'),
          content: Text(
              'Are you sure you want to delete "$tripName"? All recorded expenses for this trip will also be deleted.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                await tripProvider.deleteTrip(tripId);
                if (!context.mounted) return;
                Navigator.of(context).pop();
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}
