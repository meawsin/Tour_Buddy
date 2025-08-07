import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/trip_provider.dart';
import 'package:intl/intl.dart';
import 'expense_screen.dart'; // Import ExpenseScreen
import 'start_screen.dart'; // Import StartScreen
import 'settings_screen.dart'; // Import SettingsScreen
import '../theme_provider.dart'; // Import ThemeProvider

class PastTripsScreen extends StatelessWidget {
  const PastTripsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tripProvider = Provider.of<TripProvider>(context);
    final themeProvider =
        Provider.of<ThemeProvider>(context); // Keep if used for theme access

    return Scaffold(
      appBar: AppBar(
        title: const Text('Past Trips'),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const StartScreen()),
                (route) => false,
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: tripProvider.trips.isEmpty
          ? Center(
              child: Text(
                'No past trips recorded. Start a new trip!',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
            )
          : ListView.builder(
              itemCount: tripProvider.trips.length,
              itemBuilder: (context, index) {
                final trip = tripProvider.trips[index];
                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    title: Text(
                      trip.name, // Access 'name' property
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold),
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
                          'Expenses: ${trip.currency} ${trip.expenses.fold(0.0, (sum, item) => sum + (item['amount'] as double)).toStringAsFixed(2)}',
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.redAccent),
                      onPressed: () {
                        // Ensure trip.id is not null before passing
                        if (trip.id != null) {
                          _showDeleteConfirmationDialog(
                              context, tripProvider, trip.id!);
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
                      // Select the trip and navigate to ExpenseScreen
                      tripProvider.selectTrip(trip); // Call selectTrip
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
      BuildContext context, TripProvider tripProvider, String tripId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Trip?'),
          content: const Text(
              'Are you sure you want to delete this trip? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                tripProvider.deleteTrip(tripId);
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
