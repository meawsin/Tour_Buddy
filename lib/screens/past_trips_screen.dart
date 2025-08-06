import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/trip_provider.dart';
import '../models/trip.dart';
import 'expense_screen.dart';
import '../theme_provider.dart';
import 'settings_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'start_screen.dart'; // Import start screen for navigation

class PastTripsScreen extends StatelessWidget {
  const PastTripsScreen({super.key}); // Added key for best practice

  // Helper function to format currency display
  String _formatCurrency(String currencyCode, double amount) {
    String symbol;
    switch (currencyCode) {
      case 'BDT':
        symbol = '৳';
        break;
      case 'USD':
        symbol = '\$';
        break;
      case 'EUR':
        symbol = '€';
        break;
      case 'GBP':
        symbol = '£';
        break;
      default:
        symbol = currencyCode; // Fallback to code if symbol not defined
    }
    return '$symbol ${amount.toStringAsFixed(2)}';
  }

  void _showDeleteConfirmationDialog(
      BuildContext context, TripProvider tripProvider, Trip trip) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Trip?'),
          content: Text(
              'Are you sure you want to delete "${trip.name}"? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                tripProvider.deleteTrip(trip.id);
                Navigator.of(context).pop();
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Tour Buddy',
      applicationVersion: '1.0.0',
      applicationIcon:
          Image.asset('assets/images/TourBuddylogo.png', width: 60, height: 60),
      children: <Widget>[
        const SizedBox(height: 10),
        const Text(
            'Tour Buddy helps you manage your travel expenses effortlessly.'),
        const Text(
            'Keep track of costs, set budgets, and share your financial journey.'),
        const SizedBox(height: 10),
        const Text('Developed with Flutter.'),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final tripProvider = Provider.of<TripProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    // appCurrency is now used for the overall app, but each trip has its own currency
    // final appCurrency = themeProvider.appCurrency;

    // Filter past trips (those that have already ended)
    final pastTrips = tripProvider.trips
        .where((trip) => trip.endDate.isBefore(DateTime.now()))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Past Trips'),
        centerTitle: true,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: const BoxDecoration(color: Colors.blue),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Tour Buddy',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Manage your adventures!',
                    style: GoogleFonts.poppins(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Home'),
              onTap: () {
                Navigator.of(context).pop(); // Close drawer
                Navigator.pushReplacement(
                  // Use replacement to go back to StartScreen
                  context,
                  MaterialPageRoute(
                      builder: (context) => const StartScreen()), // Use const
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('Past Trips'),
              onTap: () {
                Navigator.of(context).pop(); // Already on PastTripsScreen
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {
                Navigator.of(context).pop(); // Close drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SettingsScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('About Tour Buddy'),
              onTap: () {
                Navigator.of(context).pop();
                _showAboutDialog(context);
              },
            ),
          ],
        ),
      ),
      body: pastTrips.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.event_note, size: 80, color: Colors.grey),
                    const SizedBox(height: 20),
                    Text(
                      'No past trips recorded yet.',
                      style: GoogleFonts.poppins(
                          fontSize: 18, color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          : ListView.builder(
              itemCount: pastTrips.length,
              itemBuilder: (context, index) {
                final trip = pastTrips[index];
                double totalExpense =
                    trip.expenses.fold(0, (sum, item) => sum + item['amount']);
                double remainingBudget = trip.budget - totalExpense;

                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  elevation: 6,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15)),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(15),
                    onTap: () {
                      tripProvider.selectTrip(trip);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => ExpenseScreen(trip: trip)),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  trip.name,
                                  style: GoogleFonts.poppins(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete,
                                    color: Colors.redAccent),
                                onPressed: () {
                                  _showDeleteConfirmationDialog(
                                      context, tripProvider, trip);
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${trip.startDate.toLocal().toString().split(' ')[0]} - ${trip.endDate.toLocal().toString().split(' ')[0]}',
                            style: GoogleFonts.poppins(
                                fontSize: 14, color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  'Total: ${_formatCurrency(trip.currency, totalExpense)}',
                                  style: GoogleFonts.poppins(fontSize: 16),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  'Budget: ${_formatCurrency(trip.currency, trip.budget)}',
                                  style: GoogleFonts.poppins(fontSize: 16),
                                  textAlign: TextAlign.right,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (trip.budget > 0)
                            Column(
                              children: [
                                LinearProgressIndicator(
                                  value: totalExpense /
                                      trip.budget.clamp(0.001, double.infinity),
                                  backgroundColor: Colors.grey[300],
                                  color: totalExpense > trip.budget
                                      ? Colors.red
                                      : Colors.green,
                                  minHeight: 8,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  totalExpense > trip.budget
                                      ? 'Over Budget by: ${_formatCurrency(trip.currency, (totalExpense - trip.budget))}'
                                      : 'Remaining: ${_formatCurrency(trip.currency, remainingBudget)}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: totalExpense > trip.budget
                                        ? Colors.red
                                        : Colors.green,
                                  ),
                                ),
                              ],
                            )
                          else
                            Text(
                              'No budget set for this trip.',
                              style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontStyle: FontStyle.italic,
                                  color: Colors.grey[600]),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
