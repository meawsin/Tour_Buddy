import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/trip_provider.dart';
import '../models/trip.dart';
import 'expense_screen.dart';

class StartScreen extends StatefulWidget {
  @override
  _StartScreenState createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {
  final TextEditingController _tripNameController = TextEditingController();
  final TextEditingController _tripBudgetController = TextEditingController();
  DateTime _selectedStartDate = DateTime.now();
  DateTime _selectedEndDate = DateTime.now().add(Duration(days: 7));

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
            _selectedEndDate = _selectedStartDate.add(Duration(days: 7));
          }
        } else {
          _selectedEndDate = picked;
          if (_selectedStartDate.isAfter(_selectedEndDate)) {
            _selectedStartDate = _selectedEndDate.subtract(Duration(days: 7));
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tripProvider = Provider.of<TripProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Tour Buddy - Your Trips'),
        centerTitle: true,
      ),
      body: tripProvider.trips.isEmpty
          ? Center(
              child: Text(
                'No trips yet! Start by adding a new trip below.',
                style: TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),
            )
          : ListView.builder(
              itemCount: tripProvider.trips.length,
              itemBuilder: (context, index) {
                final trip = tripProvider.trips[index];
                double totalExpense =
                    trip.expenses.fold(0, (sum, item) => sum + item['amount']);
                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    contentPadding: EdgeInsets.all(16),
                    title: Text(
                      trip.name,
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 4),
                        Text(
                            'Dates: ${trip.startDate.toLocal().toString().split(' ')[0]} to ${trip.endDate.toLocal().toString().split(' ')[0]}'),
                        Text(
                            'Total Expenses: ${trip.currency}${totalExpense.toStringAsFixed(2)}'),
                        Text(
                            'Budget: ${trip.currency}${trip.budget.toStringAsFixed(2)}'),
                      ],
                    ),
                    trailing: IconButton(
                      icon: Icon(Icons.delete, color: Colors.redAccent),
                      onPressed: () {
                        _showDeleteConfirmationDialog(
                            context, tripProvider, trip);
                      },
                    ),
                    onTap: () {
                      tripProvider.selectTrip(trip);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => ExpenseScreen(trip: trip)),
                      );
                    },
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddTripDialog(context, tripProvider),
        label: Text('Add New Trip'),
        icon: Icon(Icons.add),
      ),
    );
  }

  void _showAddTripDialog(BuildContext context, TripProvider tripProvider) {
    _tripNameController.clear();
    _tripBudgetController.clear();
    _selectedStartDate = DateTime.now();
    _selectedEndDate = DateTime.now().add(Duration(days: 7));

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Create New Trip"),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _tripNameController,
                      decoration: InputDecoration(labelText: 'Trip Name'),
                    ),
                    TextField(
                      controller: _tripBudgetController,
                      decoration:
                          InputDecoration(labelText: 'Budget (Optional)'),
                      keyboardType: TextInputType.number,
                    ),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Text(
                            'Start Date: ${_selectedStartDate.toLocal().toString().split(' ')[0]}'),
                        Spacer(),
                        ElevatedButton(
                          onPressed: () async {
                            await _selectDate(context, true);
                            setState(() {}); // Update dialog state
                          },
                          child: Text('Select'),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                            'End Date: ${_selectedEndDate.toLocal().toString().split(' ')[0]}'),
                        Spacer(),
                        ElevatedButton(
                          onPressed: () async {
                            await _selectDate(context, false);
                            setState(() {}); // Update dialog state
                          },
                          child: Text('Select'),
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
              child: Text("Cancel"),
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
              child: Text("Create"),
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
          title: Text('Delete Trip?'),
          content: Text(
              'Are you sure you want to delete "${trip.name}"? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                tripProvider.deleteTrip(trip.id);
                Navigator.of(context).pop();
              },
              child: Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}
