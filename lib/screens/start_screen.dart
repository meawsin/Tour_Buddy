import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../providers/trip_provider.dart';
import '../models/trip.dart';
import 'expense_screen.dart';
import 'past_trips_screen.dart';
import 'settings_screen.dart';

class StartScreen extends StatefulWidget {
  const StartScreen({super.key});

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {
  final TextEditingController _tripNameController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();
  final TextEditingController _budgetController = TextEditingController();

  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 7));
  String _selectedCurrency = 'BDT';

  @override
  void dispose() {
    _tripNameController.dispose();
    _destinationController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  void _showCreateTripDialog(BuildContext context, TripProvider tripProvider) {
    _tripNameController.clear();
    _destinationController.clear();
    _budgetController.clear();
    _startDate = DateTime.now();
    _endDate = DateTime.now().add(const Duration(days: 7));
    _selectedCurrency = 'BDT';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Create New Trip"),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setModalState) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _tripNameController,
                      decoration: InputDecoration(
                        labelText: 'Trip Name',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _destinationController,
                      decoration: InputDecoration(
                        labelText: 'Destination',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _budgetController,
                      decoration: InputDecoration(
                        labelText: 'Budget',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedCurrency,
                      decoration: InputDecoration(
                        labelText: 'Currency',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                      ),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setModalState(() {
                            _selectedCurrency = newValue;
                          });
                        }
                      },
                      items: <String>['BDT', 'USD', 'EUR', 'GBP', 'INR']
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Text(
                            'Start Date: ${DateFormat('yyyy-MM-dd').format(_startDate)}'),
                        const Spacer(),
                        ElevatedButton(
                          onPressed: () async {
                            final DateTime? picked = await showDatePicker(
                              context: context,
                              initialDate: _startDate,
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2101),
                            );
                            if (picked != null && picked != _startDate) {
                              setModalState(() {
                                _startDate = picked;
                                if (_endDate.isBefore(_startDate)) {
                                  _endDate =
                                      _startDate.add(const Duration(days: 7));
                                }
                              });
                            }
                          },
                          child: const Text('Change'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                            'End Date: ${DateFormat('yyyy-MM-dd').format(_endDate)}'),
                        const Spacer(),
                        ElevatedButton(
                          onPressed: () async {
                            final DateTime? picked = await showDatePicker(
                              context: context,
                              initialDate: _endDate,
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2101),
                            );
                            if (picked != null && picked != _endDate) {
                              setModalState(() {
                                _endDate = picked;
                                if (_startDate.isAfter(_endDate)) {
                                  _startDate = _endDate
                                      .subtract(const Duration(days: 7));
                                }
                              });
                            }
                          },
                          child: const Text('Change'),
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
            ElevatedButton(
              onPressed: () async {
                if (_tripNameController.text.trim().isEmpty ||
                    _destinationController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Please fill in all trip details.')),
                  );
                  return;
                }

                final newTrip = Trip(
                  id: const Uuid().v4(),
                  name: _tripNameController.text.trim(),
                  destination: _destinationController.text.trim(),
                  startDate: _startDate,
                  endDate: _endDate,
                  budget: double.tryParse(_budgetController.text) ?? 0.0,
                  currency: _selectedCurrency,
                  expenses: [],
                );

                await tripProvider.addTrip(newTrip);

                if (!context.mounted) return;
                tripProvider.selectTrip(newTrip);
                Navigator.of(context).pop();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => ExpenseScreen(trip: newTrip)),
                );
              },
              child: const Text("Create"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final tripProvider = Provider.of<TripProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tour Buddy'),
        actions: [
          if (tripProvider.currentUser != null)
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Sign Out',
              onPressed: () async {
                await tripProvider.signOut();
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Signed out successfully.')),
                );
              },
            ),
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Past Trips',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const PastTripsScreen()),
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (tripProvider.currentUser == null ||
                tripProvider.currentUser!.isAnonymous)
              Card(
                margin: const EdgeInsets.only(bottom: 20),
                elevation: 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                        'Cloud Backup & Sync',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Sign in to securely back up your trips and access them across devices.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 14),
                      ElevatedButton.icon(
                        onPressed: () async {
                          await tripProvider.signInWithGoogle();
                          if (!context.mounted) return;
                          if (tripProvider.currentUser != null &&
                              !tripProvider.currentUser!.isAnonymous) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text(
                                      'Signed in as ${tripProvider.currentUser!.displayName ?? "User"}')),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      'Google Sign-In was cancelled or failed.')),
                            );
                          }
                        },
                        icon: Image.asset(
                          'assets/images/google_logo.png',
                          height: 20.0,
                          width: 20.0,
                        ),
                        label: const Text('Sign in with Google'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black87,
                          minimumSize: const Size(double.infinity, 46),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: const BorderSide(color: Colors.grey),
                          ),
                          textStyle: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            Text(
              'Your Current Trips',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            tripProvider.trips.isEmpty
                ? Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.travel_explore_outlined,
                            size: 72, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'No trips yet. Start a new adventure.',
                          style:
                              TextStyle(fontSize: 16, color: Colors.grey[600]),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: () =>
                              _showCreateTripDialog(context, tripProvider),
                          icon: const Icon(Icons.add),
                          label: const Text('Create New Trip'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            textStyle: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                  )
                : Expanded(
                    child: ListView.builder(
                      itemCount: tripProvider.trips.length,
                      itemBuilder: (context, index) {
                        final trip = tripProvider.trips[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          elevation: 1.5,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            title: Text(
                              trip.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 17),
                            ),
                            subtitle: Text(
                              '${trip.destination} • ${DateFormat('MMM d').format(trip.startDate)} - ${DateFormat('MMM d, yyyy').format(trip.endDate)}',
                              style: TextStyle(color: Colors.grey[700]),
                            ),
                            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                            onTap: () {
                              tripProvider.selectTrip(trip);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        ExpenseScreen(trip: trip)),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),
            if (tripProvider.trips.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: ElevatedButton.icon(
                  onPressed: () => _showCreateTripDialog(context, tripProvider),
                  icon: const Icon(Icons.add),
                  label: const Text('Create New Trip'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    textStyle: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
