import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart'; // Import for DateFormat
import 'package:uuid/uuid.dart'; // For generating unique IDs
import '../providers/trip_provider.dart';
import '../models/trip.dart';
import 'expense_screen.dart';
import 'past_trips_screen.dart';
import 'settings_screen.dart';
import '../theme_provider.dart'; // Import ThemeProvider

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
  String _selectedCurrency = 'BDT'; // Default currency

  @override
  void dispose() {
    _tripNameController.dispose();
    _destinationController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tripProvider = Provider.of<TripProvider>(context);
    final themeProvider =
        Provider.of<ThemeProvider>(context); // Keep if used for theme access

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tour Buddy'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const PastTripsScreen()),
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
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/TourBuddylogo.png',
                height: 150,
              ),
              const SizedBox(height: 24),
              const Text(
                'Plan Your Next Adventure!',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _tripNameController,
                decoration: InputDecoration(
                  labelText: 'Trip Name',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.card_travel),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _destinationController,
                decoration: InputDecoration(
                  labelText: 'Destination',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.location_on),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _budgetController,
                decoration: InputDecoration(
                  labelText: 'Budget',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.attach_money),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedCurrency,
                decoration: InputDecoration(
                  labelText: 'Currency',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  prefixIcon: const Icon(Icons.currency_exchange),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedCurrency = newValue!;
                  });
                },
                items: <String>['BDT', 'USD', 'EUR', 'GBP', 'INR']
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: _startDate,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2101),
                        );
                        if (picked != null && picked != _startDate) {
                          setState(() {
                            _startDate = picked;
                            if (_endDate.isBefore(_startDate)) {
                              _endDate =
                                  _startDate.add(const Duration(days: 7));
                            }
                          });
                        }
                      },
                      icon: const Icon(Icons.calendar_today),
                      label: Text(
                          'Start Date: ${DateFormat('MMM d, yyyy').format(_startDate)}'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: _endDate,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2101),
                        );
                        if (picked != null && picked != _endDate) {
                          setState(() {
                            _endDate = picked;
                            if (_startDate.isAfter(_endDate)) {
                              _startDate =
                                  _endDate.subtract(const Duration(days: 7));
                            }
                          });
                        }
                      },
                      icon: const Icon(Icons.calendar_today),
                      label: Text(
                          'End Date: ${DateFormat('MMM d, yyyy').format(_endDate)}'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () async {
                  if (_tripNameController.text.isEmpty ||
                      _destinationController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Please fill in all trip details.')),
                    );
                    return;
                  }

                  final newTrip = Trip(
                    id: const Uuid().v4(), // Generate a unique ID
                    name: _tripNameController.text,
                    destination: _destinationController.text,
                    startDate: _startDate,
                    endDate: _endDate,
                    budget: double.tryParse(_budgetController.text) ?? 0.0,
                    currency: _selectedCurrency,
                    expenses: [],
                  );

                  await tripProvider.addTrip(newTrip); // Await the addTrip call

                  // Select the newly created trip
                  tripProvider.selectTrip(newTrip);

                  _tripNameController.clear();
                  _destinationController.clear();
                  _budgetController.clear();
                  setState(() {
                    _startDate = DateTime.now();
                    _endDate = DateTime.now().add(const Duration(days: 7));
                    _selectedCurrency = 'BDT';
                  });

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => ExpenseScreen(trip: newTrip)),
                  );
                },
                icon: const Icon(Icons.check),
                label: const Text('Start New Trip'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  minimumSize: const Size(double.infinity, 60),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15)),
                  textStyle: const TextStyle(fontSize: 20),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
