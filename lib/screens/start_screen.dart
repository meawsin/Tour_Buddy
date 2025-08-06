import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/trip_provider.dart';
import '../models/trip.dart';
import 'expense_screen.dart';
import '../theme_provider.dart';
import 'settings_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'past_trips_screen.dart'; // Import the new PastTripsScreen

class StartScreen extends StatefulWidget {
  const StartScreen({super.key}); // Added key for best practice

  @override
  _StartScreenState createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {
  final TextEditingController _tripNameController = TextEditingController();
  final TextEditingController _tripBudgetController = TextEditingController();
  DateTime _selectedStartDate = DateTime.now();
  DateTime _selectedEndDate = DateTime.now().add(const Duration(days: 7));

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
      case 'INR':
        symbol = '₹';
        break;
      default:
        symbol = currencyCode; // Fallback to code if symbol not defined
    }
    return '$symbol ${amount.toStringAsFixed(2)}';
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _selectedStartDate : _selectedEndDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _selectedStartDate = picked;
          if (_selectedEndDate.isBefore(_selectedStartDate)) {
            _selectedEndDate = _selectedStartDate.add(const Duration(days: 7));
          }
        } else {
          _selectedEndDate = picked;
          if (_selectedStartDate.isAfter(_selectedEndDate)) {
            _selectedStartDate =
                _selectedEndDate.subtract(const Duration(days: 7));
          }
        }
      });
    }
  }

  // Function to calculate total spending per category across all trips
  Map<String, double> _calculateAllTimeCategorySpending(List<Trip> trips) {
    Map<String, double> allTimeCategoryTotals = {};
    for (var trip in trips) {
      for (var expense in trip.expenses) {
        String category = expense['category'] ?? 'Other';
        double amount = expense['amount'] ?? 0.0;
        allTimeCategoryTotals.update(category, (value) => value + amount,
            ifAbsent: () => amount);
      }
    }
    return allTimeCategoryTotals;
  }

  @override
  Widget build(BuildContext context) {
    final tripProvider = Provider.of<TripProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final allTimeCategorySpending =
        _calculateAllTimeCategorySpending(tripProvider.trips);
    final appCurrency = themeProvider.appCurrency; // Get app-wide currency

    // Filter current trips (those not yet ended)
    final currentTrips = tripProvider.trips
        .where((trip) => trip.endDate
            .isAfter(DateTime.now().subtract(const Duration(days: 1))))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tour Buddy'), // Simplified title
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
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('Past Trips'),
              onTap: () {
                Navigator.of(context).pop(); // Close drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const PastTripsScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {
                Navigator.of(context).pop();
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
      body: SingleChildScrollView(
        // Make the entire body scrollable
        child: Padding(
          padding:
              const EdgeInsets.only(bottom: 16.0), // Adjusted padding for FAB
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'My Current Trips',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              currentTrips.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.travel_explore,
                                size: 80, color: Colors.grey),
                            const SizedBox(height: 20),
                            Text(
                              'No active trips planned! Tap the "+" button to start your first adventure.',
                              style: GoogleFonts.poppins(
                                  fontSize: 18, color: Colors.grey[600]),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap:
                          true, // Use shrinkWrap when inside SingleChildScrollView
                      physics:
                          const NeverScrollableScrollPhysics(), // Disable internal scrolling
                      itemCount: currentTrips.length,
                      itemBuilder: (context, index) {
                        final trip = currentTrips[index];
                        double totalExpense = trip.expenses
                            .fold(0, (sum, item) => sum + item['amount']);
                        double remainingBudget = trip.budget - totalExpense;

                        return Card(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
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
                                    builder: (context) =>
                                        ExpenseScreen(trip: trip)),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        // Wrap in Expanded to prevent overflow
                                        child: Text(
                                          trip.name,
                                          style: GoogleFonts.poppins(
                                              fontSize: 22,
                                              fontWeight: FontWeight.bold),
                                          overflow: TextOverflow
                                              .ellipsis, // Added ellipsis
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
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        // Added Expanded to prevent overflow
                                        child: Text(
                                          'Total: ${_formatCurrency(trip.currency, totalExpense)}',
                                          style:
                                              GoogleFonts.poppins(fontSize: 16),
                                          overflow: TextOverflow
                                              .ellipsis, // Added ellipsis
                                        ),
                                      ),
                                      Expanded(
                                        // Added Expanded to prevent overflow
                                        child: Text(
                                          'Budget: ${_formatCurrency(trip.currency, trip.budget)}',
                                          style:
                                              GoogleFonts.poppins(fontSize: 16),
                                          textAlign: TextAlign
                                              .right, // Align right for budget
                                          overflow: TextOverflow
                                              .ellipsis, // Added ellipsis
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
                                              trip.budget.clamp(
                                                  0.001, double.infinity),
                                          backgroundColor: Colors.grey[300],
                                          color: totalExpense > trip.budget
                                              ? Colors.red
                                              : Colors.green,
                                          minHeight: 8,
                                          borderRadius:
                                              BorderRadius.circular(4),
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
              const Divider(height: 30, thickness: 1),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Text(
                  'All-Time Spending by Category',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              allTimeCategorySpending.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 10.0),
                      child: Text(
                        'No spending recorded across all trips yet.',
                        style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                            color: Colors.grey[600]),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics:
                          const NeverScrollableScrollPhysics(), // To prevent nested scrolling issues
                      itemCount: allTimeCategorySpending.length,
                      itemBuilder: (context, index) {
                        final category =
                            allTimeCategorySpending.keys.elementAt(index);
                        final totalAmount = allTimeCategorySpending[category]!;
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16.0, vertical: 4.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                // Wrap category text in Expanded
                                child: Text(
                                  category,
                                  style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500),
                                  overflow:
                                      TextOverflow.ellipsis, // Added ellipsis
                                ),
                              ),
                              Text(
                                _formatCurrency(appCurrency,
                                    totalAmount), // Use appCurrency for all-time spending
                                style: GoogleFonts.poppins(
                                    fontSize: 16, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        // Moved outside body
        onPressed: () => _showAddTripDialog(context, tripProvider),
        label: const Text('Add New Trip'),
        icon: const Icon(Icons.add),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
      floatingActionButtonLocation:
          FloatingActionButtonLocation.centerFloat, // Moved outside body
    );
  }

  void _showAddTripDialog(BuildContext context, TripProvider tripProvider) {
    _tripNameController.clear();
    _tripBudgetController.clear();
    _selectedStartDate = DateTime.now();
    _selectedEndDate = DateTime.now().add(const Duration(days: 7));

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Create New Trip"),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _tripNameController,
                      decoration: const InputDecoration(labelText: 'Trip Name'),
                    ),
                    TextField(
                      controller: _tripBudgetController,
                      decoration:
                          const InputDecoration(labelText: 'Budget (Optional)'),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Text(
                            'Start Date: ${_selectedStartDate.toLocal().toString().split(' ')[0]}'),
                        const Spacer(),
                        ElevatedButton(
                          onPressed: () async {
                            await _selectDate(context, true);
                            setState(() {});
                          },
                          child: const Text('Select'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                            'End Date: ${_selectedEndDate.toLocal().toString().split(' ')[0]}'),
                        const Spacer(),
                        ElevatedButton(
                          onPressed: () async {
                            await _selectDate(context, false);
                            setState(() {});
                          },
                          child: const Text('Select'),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                if (_tripNameController.text.isNotEmpty) {
                  final newTrip = Trip(
                    name: _tripNameController.text,
                    budget: double.tryParse(_tripBudgetController.text) ?? 0.0,
                    startDate: _selectedStartDate,
                    endDate: _selectedEndDate,
                  );
                  tripProvider.addTrip(newTrip);
                  Navigator.of(context).pop();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => ExpenseScreen(trip: newTrip)),
                  );
                }
              },
              child: const Text("Create"),
            ),
          ],
        );
      },
    );
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
}
