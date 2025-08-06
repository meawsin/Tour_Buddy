import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../theme_provider.dart';
import '../providers/trip_provider.dart';
import '../models/trip.dart';
import '../services/currency_service.dart'; // Import the currency service
import 'compare_trips_screen.dart'; // Import CompareTripsScreen

class ExpenseScreen extends StatelessWidget {
  final Trip trip; // Pass the trip to display

  ExpenseScreen({super.key, required this.trip}); // Constructor to receive trip

  final TextEditingController _expenseTitleController = TextEditingController();
  final TextEditingController _expenseAmountController =
      TextEditingController();
  final TextEditingController _foreignAmountController =
      TextEditingController();

  // Categories and selectedCategory are now instance variables
  final List<String> categories = [
    'Food',
    'Transport',
    'Accommodation',
    'Shopping',
    'Activities',
    'Other'
  ];
  String selectedCategory = 'Food'; // Default category

  String _foreignCurrency =
      'USD'; // Default foreign currency for conversion input

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final tripProvider =
        Provider.of<TripProvider>(context); // Access TripProvider

    // Use the expenses from the passed trip object
    double totalExpense =
        trip.expenses.fold(0, (sum, item) => sum + item['amount']);

    return Scaffold(
      appBar: AppBar(
        title: Text(trip.name), // Display current trip name
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              _shareTrip(trip);
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Text(
                'Tour Buddy',
                style: TextStyle(
                    color: Colors.black,
                    fontSize: 30,
                    fontFamily: 'Comin Sans',
                    fontWeight: FontWeight.bold),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.toggle_on),
              title: const Text('Switch Theme'),
              onTap: () {
                themeProvider.toggleTheme();
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text('Reset Trip Expenses'),
              onTap: () {
                tripProvider
                    .resetCurrentTripExpenses(); // Reset only current trip's expenses
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              leading: const Icon(Icons.compare_arrows),
              title: const Text('Compare Trips'),
              onTap: () {
                Navigator.of(context).pop(); // Close drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CompareTripsScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Trip Settings'),
              onTap: () {
                Navigator.of(context).pop(); // Close drawer
                _showTripSettingsDialog(context, trip);
              },
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Text(
                  'Total Expenses: ${trip.currency}${totalExpense.toStringAsFixed(2)}',
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Budget: ${trip.currency}${trip.budget.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: trip.budget > 0 ? totalExpense / trip.budget : 0,
                  backgroundColor: Colors.grey[300],
                  color: totalExpense > trip.budget
                      ? Colors.red
                      : Colors.green, // Red if over budget
                  minHeight: 10,
                  borderRadius: BorderRadius.circular(5),
                ),
                const SizedBox(height: 8),
                Text(
                  totalExpense > trip.budget
                      ? 'Over Budget by: ${trip.currency}${(totalExpense - trip.budget).toStringAsFixed(2)}'
                      : 'Remaining Budget: ${trip.currency}${(trip.budget - totalExpense).toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 16,
                    color:
                        totalExpense > trip.budget ? Colors.red : Colors.green,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: trip.expenses.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text('${trip.expenses[index]['title']}'),
                  subtitle: Text(
                      '${trip.expenses[index]['date']} - ${trip.expenses[index]['category']}'),
                  trailing: Text(
                      '${trip.currency}${trip.expenses[index]['amount'].toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 20)),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () {
                _showAddExpenseDialog(context, tripProvider,
                    trip.currency); // Pass tripProvider and current trip's currency
              },
              child: const Text("Add Expense"),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddExpenseDialog(
      BuildContext context, TripProvider tripProvider, String tripCurrency) {
    _expenseTitleController.clear();
    _expenseAmountController.clear();
    _foreignAmountController.clear(); // Clear foreign amount controller
    selectedCategory = categories.first; // Reset selected category

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Add Expense"),
          content: StatefulBuilder(
            // Use StatefulBuilder to update dropdown and foreign currency
            builder: (BuildContext context, StateSetter setState) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _expenseTitleController,
                      decoration:
                          const InputDecoration(labelText: 'Expense Title'),
                    ),
                    TextField(
                      controller: _expenseAmountController,
                      decoration:
                          InputDecoration(labelText: 'Amount ($tripCurrency)'),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _foreignAmountController,
                            decoration: const InputDecoration(
                                labelText: 'Amount (Foreign)'),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 8),
                        DropdownButton<String>(
                          value: _foreignCurrency,
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              setState(() {
                                _foreignCurrency = newValue;
                              });
                            }
                          },
                          items: <String>[
                            'USD',
                            'EUR',
                            'GBP',
                            'INR',
                            'BDT'
                          ] // Example foreign currencies
                              .map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedCategory,
                      decoration: InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                      ),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            selectedCategory = newValue;
                          });
                        }
                      },
                      items: categories
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
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
              onPressed: () async {
                // Make this async for currency conversion
                double? amount = double.tryParse(_expenseAmountController.text);
                double? foreignAmount =
                    double.tryParse(_foreignAmountController.text);

                if (_expenseTitleController.text.isNotEmpty &&
                    (amount != null || foreignAmount != null)) {
                  double finalAmount = amount ?? 0.0;
                  if (foreignAmount != null &&
                      _foreignCurrency != tripCurrency) {
                    // Perform currency conversion if foreign amount is entered and different currency
                    CurrencyService currencyService = CurrencyService();
                    try {
                      finalAmount += await currencyService.convertCurrency(
                          foreignAmount, _foreignCurrency, tripCurrency);
                    } catch (e) {
                      print('Error during currency conversion: $e');
                      // Optionally show an error message to the user
                    }
                  } else if (foreignAmount != null &&
                      _foreignCurrency == tripCurrency) {
                    finalAmount += foreignAmount;
                  }

                  tripProvider.addExpenseToCurrentTrip({
                    'title': _expenseTitleController.text,
                    'amount': finalAmount,
                    'date':
                        "${DateTime.now().year}-${DateTime.now().month}-${DateTime.now().day} ${DateTime.now().hour}:${DateTime.now().minute}",
                    'category': selectedCategory,
                  });
                  _expenseTitleController.clear();
                  _expenseAmountController.clear();
                  _foreignAmountController.clear(); // Clear foreign amount
                  Navigator.of(context).pop();
                }
              },
              child: const Text("Add"),
            ),
          ],
        );
      },
    );
  }

  void _shareTrip(Trip trip) {
    String tripDetails = "🌟 Tour Buddy Trip: ${trip.name} 🌟\n\n";
    tripDetails +=
        "🗓️ Dates: ${trip.startDate.toLocal().toString().split(' ')[0]} to ${trip.endDate.toLocal().toString().split(' ')[0]}\n";
    tripDetails +=
        "💰 Budget: ${trip.currency}${trip.budget.toStringAsFixed(2)}\n\n";

    double total = trip.expenses.fold(0, (sum, item) => sum + item['amount']);
    tripDetails +=
        "📊 Total Expenses: ${trip.currency}${total.toStringAsFixed(2)}\n\n";

    if (trip.expenses.isNotEmpty) {
      tripDetails += "Detailed Expenses:\n";
      for (var expense in trip.expenses) {
        tripDetails +=
            "  - ${expense['title']} (${expense['category']}): ${trip.currency}${expense['amount'].toStringAsFixed(2)}\n";
      }
    } else {
      tripDetails += "No expenses recorded for this trip yet! 📝";
    }

    Share.share(tripDetails, subject: 'My Trip: ${trip.name}');
  }

  void _showTripSettingsDialog(BuildContext context, Trip trip) {
    final tripProvider = Provider.of<TripProvider>(context, listen: false);
    final TextEditingController currentBudgetController =
        TextEditingController(text: trip.budget.toStringAsFixed(2));
    String selectedCurrency = trip.currency;
    DateTime tempStartDate = trip.startDate;
    DateTime tempEndDate = trip.endDate;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Trip Settings for ${trip.name}'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: currentBudgetController,
                      decoration:
                          const InputDecoration(labelText: 'Trip Budget'),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedCurrency,
                      decoration: InputDecoration(
                        labelText: 'Trip Currency',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                      ),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            selectedCurrency = newValue;
                          });
                        }
                      },
                      items: <String>[
                        'BDT',
                        'USD',
                        'EUR',
                        'GBP',
                        'INR'
                      ] // Example currencies
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
                        Text(
                            'Start Date: ${tempStartDate.toLocal().toString().split(' ')[0]}'),
                        const Spacer(),
                        ElevatedButton(
                          onPressed: () async {
                            final DateTime? picked = await showDatePicker(
                              context: context,
                              initialDate: tempStartDate,
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2101),
                            );
                            if (picked != null && picked != tempStartDate) {
                              setState(() {
                                tempStartDate = picked;
                                if (tempEndDate.isBefore(tempStartDate)) {
                                  tempEndDate = tempStartDate
                                      .add(const Duration(days: 7));
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
                            'End Date: ${tempEndDate.toLocal().toString().split(' ')[0]}'),
                        const Spacer(),
                        ElevatedButton(
                          onPressed: () async {
                            final DateTime? picked = await showDatePicker(
                              context: context,
                              initialDate: tempEndDate,
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2101),
                            );
                            if (picked != null && picked != tempEndDate) {
                              setState(() {
                                tempEndDate = picked;
                                if (tempStartDate.isAfter(tempEndDate)) {
                                  tempStartDate = tempEndDate
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
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                tripProvider.updateCurrentTrip(
                  budget: double.tryParse(currentBudgetController.text),
                  currency: selectedCurrency,
                  startDate: tempStartDate,
                  endDate: tempEndDate,
                );
                Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
}
