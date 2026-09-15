import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/trip_provider.dart';
import 'expense_screen.dart';
import 'start_screen.dart';
import 'settings_screen.dart';

class PastTripsScreen extends StatelessWidget {
  const PastTripsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tripProvider = Provider.of<TripProvider>(context);

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
      body: tripProvider.trips.isEmpty
          ? Center(
              child: Text(
                'No past trips recorded.',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
            )
          : ListView.builder(
              itemCount: tripProvider.trips.length,
              itemBuilder: (context, index) {
                final trip = tripProvider.trips[index];
                final totalSpent = trip.expenses.fold(0.0, (sum, e) => sum + e.amount);

                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    title: Text(
                      trip.name,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          'Destination: ${trip.destination}',
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                        Text(
                          'Dates: ${DateFormat('MMM d, yyyy').format(trip.startDate)} - ${DateFormat('MMM d, yyyy').format(trip.endDate)}',
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                        Text(
                          'Budget: ${trip.currency} ${trip.budget.toStringAsFixed(2)}',
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                        Text(
                          'Expenses: ${trip.currency} ${totalSpent.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: trip.budget > 0 && totalSpent > trip.budget
                                ? Colors.red
                                : Colors.grey[800],
                          ),
                        ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                      tooltip: 'Delete Trip',
                      onPressed: () {
                        if (trip.id != null) {
                          _showDeleteConfirmationDialog(
                              context, tripProvider, trip.id!, trip.name);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content:
                                    Text('Cannot delete trip: ID is missing.')),
                          );
                        }
                      },
                    ),
                    onTap: () {
                      tripProvider.selectTrip(trip);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ExpenseScreen(trip: trip),
                        ),
                      );
                    },
                  ),
                );
              },
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
              'Are you sure you want to delete "$tripName"? This action cannot be undone.'),
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
