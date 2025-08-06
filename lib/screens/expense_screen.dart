import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart'; // Import the intl package for DateFormat
import 'package:tour_buddy/screens/past_trips_screen.dart';
import '../theme_provider.dart';
import '../providers/trip_provider.dart';
import '../models/trip.dart';
import '../services/currency_service.dart';
import 'settings_screen.dart';
import 'start_screen.dart';

enum ExpenseSortOption {
  dateAsc,
  dateDesc,
  amountAsc,
  amountDesc,
  categoryAsc,
}

class ExpenseScreen extends StatefulWidget {
  final Trip trip;

  const ExpenseScreen(
      {super.key, required this.trip}); // Added key for best practice

  @override
  _ExpenseScreenState createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends State<ExpenseScreen> {
  final TextEditingController _expenseTitleController = TextEditingController();
  final TextEditingController _expenseAmountController =
      TextEditingController();
  final TextEditingController _foreignAmountController =
      TextEditingController();

  final List<String> categories = [
    'Food',
    'Transport',
    'Accommodation',
    'Shopping',
    'Activities',
    'Other'
  ];
  String selectedCategory = 'Food';

  String _foreignCurrency = 'USD';
  ExpenseSortOption _currentSortOption =
      ExpenseSortOption.dateDesc; // Default sort

  List<Map<String, dynamic>> _getSortedExpenses(
      List<Map<String, dynamic>> expenses) {
    List<Map<String, dynamic>> sortedList = List.from(expenses);
    // Define a consistent date format for parsing
    final dateFormat =
        DateFormat("yyyy-MM-dd HH:mm"); // Matches the new storage format

    switch (_currentSortOption) {
      case ExpenseSortOption.dateAsc:
        sortedList.sort((a, b) {
          // Parse date strings using the consistent format
          final dateA = dateFormat.parse(a['date']);
          final dateB = dateFormat.parse(b['date']);
          return dateA.compareTo(dateB);
        });
        break;
      case ExpenseSortOption.dateDesc:
        sortedList.sort((a, b) {
          // Parse date strings using the consistent format
          final dateA = dateFormat.parse(a['date']);
          final dateB = dateFormat.parse(b['date']);
          return dateB.compareTo(dateA);
        });
        break;
      case ExpenseSortOption.amountAsc:
        sortedList.sort(
            (a, b) => (a['amount'] as double).compareTo(b['amount'] as double));
        break;
      case ExpenseSortOption.amountDesc:
        sortedList.sort(
            (a, b) => (b['amount'] as double).compareTo(a['amount'] as double));
        break;
      case ExpenseSortOption.categoryAsc:
        sortedList.sort((a, b) =>
            (a['category'] as String).compareTo(b['category'] as String));
        break;
    }
    return sortedList;
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final tripProvider = Provider.of<TripProvider>(context);

    double totalExpense =
        widget.trip.expenses.fold(0, (sum, item) => sum + item['amount']);
    List<Map<String, dynamic>> sortedExpenses =
        _getSortedExpenses(widget.trip.expenses);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.trip.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics_outlined),
            tooltip: 'Trip Insights',
            onPressed: () {
              _showTripInsightsDialog(context, widget.trip);
            },
          ),
          PopupMenuButton<ExpenseSortOption>(
            onSelected: (ExpenseSortOption result) {
              setState(() {
                _currentSortOption = result;
              });
            },
            itemBuilder: (BuildContext context) =>
                <PopupMenuEntry<ExpenseSortOption>>[
              const PopupMenuItem<ExpenseSortOption>(
                value: ExpenseSortOption.dateDesc,
                child: Text('Sort by Date (Newest)'),
              ),
              const PopupMenuItem<ExpenseSortOption>(
                value: ExpenseSortOption.dateAsc,
                child: Text('Sort by Date (Oldest)'),
              ),
              const PopupMenuItem<ExpenseSortOption>(
                value: ExpenseSortOption.amountDesc,
                child: Text('Sort by Amount (High to Low)'),
              ),
              const PopupMenuItem<ExpenseSortOption>(
                value: ExpenseSortOption.amountAsc,
                child: Text('Sort by Amount (Low to High)'),
              ),
              const PopupMenuItem<ExpenseSortOption>(
                value: ExpenseSortOption.categoryAsc,
                child: Text('Sort by Category'),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Share Trip',
            onPressed: () {
              _shareTrip(context, widget.trip);
            },
          ),
        ],
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
                  const Text(
                    'Trip Options',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'For ${widget.trip.name}',
                    style: const TextStyle(
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
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const StartScreen()), // Use const
                  (route) => false,
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('Past Trips'),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => PastTripsScreen()),
                  (route) => false,
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
              leading: const Icon(Icons.delete),
              title: const Text('Reset Trip Expenses'),
              onTap: () {
                Navigator.of(context).pop();
                _showResetConfirmationDialog(context, tripProvider);
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
                  'Total Expenses: ${widget.trip.currency} ${totalExpense.toStringAsFixed(2)}',
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                if (widget.trip.budget > 0) ...[
                  Text(
                    'Budget: ${widget.trip.currency} ${widget.trip.budget.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: totalExpense /
                        widget.trip.budget.clamp(0.001, double.infinity),
                    backgroundColor: Colors.grey[300],
                    color: totalExpense > widget.trip.budget
                        ? Colors.red
                        : Colors.green,
                    minHeight: 10,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    totalExpense > widget.trip.budget
                        ? 'Over Budget by: ${widget.trip.currency} ${(totalExpense - widget.trip.budget).toStringAsFixed(2)}'
                        : 'Remaining Budget: ${widget.trip.currency} ${(widget.trip.budget - totalExpense).toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 16,
                      color: totalExpense > widget.trip.budget
                          ? Colors.red
                          : Colors.green,
                    ),
                  ),
                ] else ...[
                  const Text(
                    'No budget set for this trip.',
                    style: TextStyle(
                        fontSize: 16,
                        fontStyle: FontStyle.italic,
                        color: Colors.grey),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: sortedExpenses.isEmpty
                ? Center(
                    child: Text(
                      'No expenses recorded yet. Add your first expense!',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                  )
                : ListView.builder(
                    itemCount: sortedExpenses.length,
                    itemBuilder: (context, index) {
                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          title: Text(
                            '${sortedExpenses[index]['title']}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis, // Added ellipsis
                          ),
                          subtitle: Text(
                            '${sortedExpenses[index]['date']} - ${sortedExpenses[index]['category']}',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[600]),
                            overflow: TextOverflow.ellipsis, // Added ellipsis
                          ),
                          trailing: Text(
                              '${widget.trip.currency}${sortedExpenses[index]['amount'].toStringAsFixed(2)}',
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                        ),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              onPressed: () {
                _showAddExpenseDialog(
                    context, tripProvider, widget.trip.currency);
              },
              icon: const Icon(Icons.add),
              label: const Text("Add New Expense"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.secondary,
                foregroundColor: Theme.of(context).colorScheme.onSecondary,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
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
    _foreignAmountController.clear();
    selectedCategory = categories.first;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Add Expense"),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _expenseTitleController,
                      decoration: InputDecoration(
                        labelText: 'Expense Title',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _expenseAmountController,
                      decoration: InputDecoration(
                        labelText: 'Amount (${tripCurrency})',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    const Text('Or convert from foreign currency:',
                        style: TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _foreignAmountController,
                            decoration: InputDecoration(
                              labelText: 'Foreign Amount',
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
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
                          items: <String>['USD', 'EUR', 'GBP', 'INR', 'BDT']
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
            ElevatedButton(
              onPressed: () async {
                double? amount = double.tryParse(_expenseAmountController.text);
                double? foreignAmount =
                    double.tryParse(_foreignAmountController.text);

                if (_expenseTitleController.text.isNotEmpty &&
                    (amount != null || foreignAmount != null)) {
                  double finalAmount = amount ?? 0.0;
                  if (foreignAmount != null &&
                      _foreignCurrency != tripCurrency) {
                    CurrencyService currencyService = CurrencyService();
                    try {
                      finalAmount += await currencyService.convertCurrency(
                          foreignAmount, _foreignCurrency, tripCurrency);
                    } catch (e) {
                      debugPrint(
                          'Error during currency conversion: $e'); // Use debugPrint
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text(
                                'Currency conversion failed. Using entered amount directly.')),
                      );
                    }
                  } else if (foreignAmount != null &&
                      _foreignCurrency == tripCurrency) {
                    finalAmount += foreignAmount;
                  }

                  tripProvider.addExpenseToCurrentTrip({
                    'title': _expenseTitleController.text,
                    'amount': finalAmount,
                    // Format date consistently with leading zeros
                    'date':
                        DateFormat("yyyy-MM-dd HH:mm").format(DateTime.now()),
                    'category': selectedCategory,
                  });
                  _expenseTitleController.clear();
                  _expenseAmountController.clear();
                  _foreignAmountController.clear();
                  Navigator.of(context).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text(
                            'Please enter an expense title and at least one amount.')),
                  );
                }
              },
              child: const Text("Add"),
            ),
          ],
        );
      },
    );
  }

  void _shareTrip(BuildContext context, Trip trip) {
    String tripDetails = "🌟 Tour Buddy Trip: ${trip.name} 🌟\n\n";
    tripDetails +=
        "🗓️ Dates: ${DateFormat('yyyy-MM-dd').format(trip.startDate)} - ${DateFormat('yyyy-MM-dd').format(trip.endDate)}\n";
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

    Share.share(tripDetails, subject: 'My Trip: ${trip.name}').then((result) {
      if (result.status == ShareResultStatus.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Trip details shared successfully!')),
        );
      } else if (result.status == ShareResultStatus.dismissed) {
        // User dismissed the share sheet
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to share trip details.')),
        );
      }
    });
  }

  void _showTripSettingsDialog(BuildContext context, Trip trip) {
    final tripProvider = Provider.of<TripProvider>(context, listen: false);
    final TextEditingController _currentBudgetController =
        TextEditingController(text: trip.budget.toStringAsFixed(2));
    String _selectedCurrency = trip.currency;
    DateTime _tempStartDate = trip.startDate;
    DateTime _tempEndDate = trip.endDate;

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
                      controller: _currentBudgetController,
                      decoration:
                          const InputDecoration(labelText: 'Trip Budget'),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedCurrency,
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
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Text(
                            'Start Date: ${DateFormat('yyyy-MM-dd').format(_tempStartDate)}'),
                        const Spacer(),
                        ElevatedButton(
                          onPressed: () async {
                            final DateTime? picked = await showDatePicker(
                              context: context,
                              initialDate: _tempStartDate,
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2101),
                            );
                            if (picked != null && picked != _tempStartDate) {
                              setState(() {
                                _tempStartDate = picked;
                                if (_tempEndDate.isBefore(_tempStartDate)) {
                                  _tempEndDate = _tempStartDate
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
                            'End Date: ${DateFormat('yyyy-MM-dd').format(_tempEndDate)}'),
                        const Spacer(),
                        ElevatedButton(
                          onPressed: () async {
                            final DateTime? picked = await showDatePicker(
                              context: context,
                              initialDate: _tempEndDate,
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2101),
                            );
                            if (picked != null && picked != _tempEndDate) {
                              setState(() {
                                _tempEndDate = picked;
                                if (_tempStartDate.isAfter(_tempEndDate)) {
                                  _tempStartDate = _tempEndDate
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
            ElevatedButton(
              onPressed: () {
                tripProvider.updateCurrentTrip(
                  budget: double.tryParse(_currentBudgetController.text),
                  currency: _selectedCurrency,
                  startDate: _tempStartDate,
                  endDate: _tempEndDate,
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

  void _showResetConfirmationDialog(
      BuildContext context, TripProvider tripProvider) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Reset Expenses?'),
          content: const Text(
              'Are you sure you want to clear all expenses for this trip? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                tripProvider.resetCurrentTripExpenses();
                Navigator.of(context).pop();
              },
              child: const Text('Reset', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _showTripInsightsDialog(BuildContext context, Trip trip) {
    Map<String, double> categoryTotals = {};
    for (var expense in trip.expenses) {
      String category = expense['category'] ?? 'Uncategorized';
      double amount = expense['amount'] ?? 0.0;
      categoryTotals.update(category, (value) => value + amount,
          ifAbsent: () => amount);
    }

    double totalExpense =
        trip.expenses.fold(0, (sum, item) => sum + item['amount']);

    String insights = '';
    if (totalExpense == 0) {
      insights = 'No expenses recorded yet to provide insights.';
    } else {
      insights +=
          'Total spending: ${trip.currency}${totalExpense.toStringAsFixed(2)}\n\n';

      if (trip.budget > 0) {
        if (totalExpense > trip.budget) {
          insights +=
              '🚨 You are **${trip.currency}${(totalExpense - trip.budget).toStringAsFixed(2)}** over your budget! Consider cutting down on non-essential spending.\n\n';
        } else {
          insights +=
              '✅ You are **${trip.currency}${(trip.budget - totalExpense).toStringAsFixed(2)}** under your budget. Great job!\n\n';
        }
      } else {
        insights +=
            '💡 Set a budget in Trip Settings to get more detailed budget insights!\n\n';
      }

      if (categoryTotals.isNotEmpty) {
        insights += 'Spending by Category:\n';
        var sortedCategories = categoryTotals.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        for (var entry in sortedCategories) {
          insights +=
              '- ${entry.key}: ${trip.currency}${entry.value.toStringAsFixed(2)} (${(entry.value / totalExpense * 100).toStringAsFixed(1)}%)\n';
        }

        if (sortedCategories.isNotEmpty &&
            sortedCategories.first.value / totalExpense > 0.3) {
          insights +=
              '\nConsider reviewing your **${sortedCategories.first.key}** expenses, as they account for a significant portion of your spending.';
        }
      }
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Trip Insights'),
          content: SingleChildScrollView(
            child: Text(insights),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}
