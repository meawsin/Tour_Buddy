import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:tour_buddy/screens/past_trips_screen.dart';
import '../providers/trip_provider.dart';
import '../models/trip.dart';
import '../models/expense.dart';
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

  const ExpenseScreen({super.key, required this.trip});

  @override
  State<ExpenseScreen> createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends State<ExpenseScreen> {
  final TextEditingController _expenseTitleController = TextEditingController();
  final TextEditingController _expenseAmountController = TextEditingController();
  final TextEditingController _foreignAmountController = TextEditingController();

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
  ExpenseSortOption _currentSortOption = ExpenseSortOption.dateDesc;

  @override
  void dispose() {
    _expenseTitleController.dispose();
    _expenseAmountController.dispose();
    _foreignAmountController.dispose();
    super.dispose();
  }

  List<Expense> _getSortedExpenses(List<Expense> expenses) {
    List<Expense> sortedList = List.from(expenses);

    switch (_currentSortOption) {
      case ExpenseSortOption.dateAsc:
        sortedList.sort((a, b) => a.date.compareTo(b.date));
        break;
      case ExpenseSortOption.dateDesc:
        sortedList.sort((a, b) => b.date.compareTo(a.date));
        break;
      case ExpenseSortOption.amountAsc:
        sortedList.sort((a, b) => a.amount.compareTo(b.amount));
        break;
      case ExpenseSortOption.amountDesc:
        sortedList.sort((a, b) => b.amount.compareTo(a.amount));
        break;
      case ExpenseSortOption.categoryAsc:
        sortedList.sort((a, b) => a.category.compareTo(b.category));
        break;
    }
    return sortedList;
  }

  @override
  Widget build(BuildContext context) {
    final tripProvider = Provider.of<TripProvider>(context);
    final currentTrip = tripProvider.trips.firstWhere(
      (t) => t.id == widget.trip.id,
      orElse: () => widget.trip,
    );

    double totalExpense =
        currentTrip.expenses.fold(0.0, (sum, item) => sum + item.amount);
    List<Expense> sortedExpenses = _getSortedExpenses(currentTrip.expenses);

    return Scaffold(
      appBar: AppBar(
        title: Text(currentTrip.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics_outlined),
            tooltip: 'Trip Insights',
            onPressed: () {
              _showTripInsightsDialog(context, currentTrip);
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
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Share Trip',
            onPressed: () {
              _shareTrip(context, currentTrip);
            },
          ),
          IconButton(
            icon: const Icon(Icons.tune),
            tooltip: 'Trip Settings',
            onPressed: () {
              _showTripSettingsDialog(context, currentTrip);
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
                    'Tour Buddy',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    currentTrip.name,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home_outlined),
              title: const Text('Home'),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const StartScreen()),
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
                  MaterialPageRoute(builder: (context) => const PastTripsScreen()),
                  (route) => false,
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('Settings'),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsScreen()),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
              title: const Text('Reset Trip Expenses',
                  style: TextStyle(color: Colors.redAccent)),
              onTap: () {
                Navigator.of(context).pop();
                _showResetConfirmationDialog(context, tripProvider, currentTrip);
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
                  'Total Expenses: ${currentTrip.currency} ${totalExpense.toStringAsFixed(2)}',
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                if (currentTrip.budget > 0) ...[
                  Text(
                    'Budget: ${currentTrip.currency} ${currentTrip.budget.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: (totalExpense /
                            currentTrip.budget.clamp(0.001, double.infinity))
                        .clamp(0.0, 1.0),
                    backgroundColor: Colors.grey[300],
                    color: totalExpense > currentTrip.budget
                        ? Colors.red
                        : Colors.green,
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    totalExpense > currentTrip.budget
                        ? 'Over Budget by: ${currentTrip.currency} ${(totalExpense - currentTrip.budget).toStringAsFixed(2)}'
                        : 'Remaining Budget: ${currentTrip.currency} ${(currentTrip.budget - totalExpense).toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: totalExpense > currentTrip.budget
                          ? Colors.red
                          : Colors.green[700],
                    ),
                  ),
                ] else ...[
                  const Text(
                    'No budget set for this trip.',
                    style: TextStyle(
                        fontSize: 15,
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
                      'No expenses recorded yet. Add your first expense.',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                  )
                : ListView.builder(
                    itemCount: sortedExpenses.length,
                    itemBuilder: (context, index) {
                      final expense = sortedExpenses[index];
                      return Dismissible(
                        key: Key(expense.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          color: Colors.redAccent,
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        onDismissed: (_) {
                          tripProvider.deleteExpenseFromCurrentTrip(
                              currentTrip, expense.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Removed "${expense.title}"')),
                          );
                        },
                        child: Card(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 4),
                          elevation: 1,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            title: Text(
                              expense.title,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              '${DateFormat('yyyy-MM-dd HH:mm').format(expense.date)} • ${expense.category}',
                              style: TextStyle(
                                  fontSize: 13, color: Colors.grey[600]),
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: Text(
                              '${currentTrip.currency} ${expense.amount.toStringAsFixed(2)}',
                              style: const TextStyle(
                                  fontSize: 17, fontWeight: FontWeight.bold),
                            ),
                          ),
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
                    context, tripProvider, currentTrip);
              },
              icon: const Icon(Icons.add),
              label: const Text("Add New Expense"),
              style: ElevatedButton.styleFrom(
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
      BuildContext context, TripProvider tripProvider, Trip trip) {
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
            builder: (BuildContext context, StateSetter setModalState) {
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
                        labelText: 'Amount (${trip.currency})',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          ),
                        ),
                        const SizedBox(width: 8),
                        DropdownButton<String>(
                          value: _foreignCurrency,
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              setModalState(() {
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
                      initialValue: selectedCategory,
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
                          setModalState(() {
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
                  if (foreignAmount != null && _foreignCurrency != trip.currency) {
                    CurrencyService currencyService = CurrencyService();
                    try {
                      finalAmount += await currencyService.convertCurrency(
                          foreignAmount, _foreignCurrency, trip.currency);
                    } catch (e) {
                      debugPrint('Error during currency conversion: $e');
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text(
                                'Currency conversion failed. Using entered amount directly.')),
                      );
                    }
                  } else if (foreignAmount != null &&
                      _foreignCurrency == trip.currency) {
                    finalAmount += foreignAmount;
                  }

                  final newExpense = Expense(
                    id: const Uuid().v4(),
                    title: _expenseTitleController.text.trim(),
                    amount: finalAmount,
                    category: selectedCategory,
                    date: DateTime.now(),
                    foreignAmount: foreignAmount,
                    foreignCurrency:
                        foreignAmount != null ? _foreignCurrency : null,
                  );

                  await tripProvider.addExpenseToCurrentTrip(trip, newExpense);

                  if (!context.mounted) return;
                  _expenseTitleController.clear();
                  _expenseAmountController.clear();
                  _foreignAmountController.clear();
                  Navigator.of(context).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text(
                            'Please enter an expense title and an amount.')),
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
    String tripDetails = "Tour Buddy: ${trip.name}\n\n";
    tripDetails +=
        "Dates: ${DateFormat('yyyy-MM-dd').format(trip.startDate)} - ${DateFormat('yyyy-MM-dd').format(trip.endDate)}\n";
    tripDetails +=
        "Budget: ${trip.currency} ${trip.budget.toStringAsFixed(2)}\n\n";

    double total = trip.expenses.fold(0.0, (sum, item) => sum + item.amount);
    tripDetails +=
        "Total Expenses: ${trip.currency} ${total.toStringAsFixed(2)}\n\n";

    if (trip.expenses.isNotEmpty) {
      tripDetails += "Expenses Breakdown:\n";
      for (var expense in trip.expenses) {
        tripDetails +=
            "- ${expense.title} (${expense.category}): ${trip.currency} ${expense.amount.toStringAsFixed(2)}\n";
      }
    } else {
      tripDetails += "No expenses recorded for this trip yet.";
    }

    Share.share(tripDetails, subject: 'Trip Summary: ${trip.name}');
  }

  void _showTripSettingsDialog(BuildContext context, Trip trip) {
    final tripProvider = Provider.of<TripProvider>(context, listen: false);
    final budgetController =
        TextEditingController(text: trip.budget.toStringAsFixed(2));
    String selectedCurrency = trip.currency;
    DateTime tempStartDate = trip.startDate;
    DateTime tempEndDate = trip.endDate;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Trip Settings - ${trip.name}'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setModalState) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: budgetController,
                      decoration:
                          const InputDecoration(labelText: 'Trip Budget'),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: selectedCurrency,
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
                          setModalState(() {
                            selectedCurrency = newValue;
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
                            'Start: ${DateFormat('yyyy-MM-dd').format(tempStartDate)}'),
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
                              setModalState(() {
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
                            'End: ${DateFormat('yyyy-MM-dd').format(tempEndDate)}'),
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
                              setModalState(() {
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
            ElevatedButton(
              onPressed: () async {
                await tripProvider.updateCurrentTrip(
                  trip: trip,
                  budget: double.tryParse(budgetController.text),
                  currency: selectedCurrency,
                  startDate: tempStartDate,
                  endDate: tempEndDate,
                );
                if (!context.mounted) return;
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
      BuildContext context, TripProvider tripProvider, Trip trip) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Reset Expenses'),
          content: const Text(
              'Are you sure you want to clear all expenses for this trip? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                await tripProvider.resetCurrentTripExpenses(trip);
                if (!context.mounted) return;
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
      String category = expense.category;
      categoryTotals.update(category, (value) => value + expense.amount,
          ifAbsent: () => expense.amount);
    }

    double totalExpense =
        trip.expenses.fold(0.0, (sum, item) => sum + item.amount);

    String insights = '';
    if (totalExpense == 0) {
      insights = 'No expenses recorded yet to provide insights.';
    } else {
      insights +=
          'Total Spending: ${trip.currency} ${totalExpense.toStringAsFixed(2)}\n\n';

      if (trip.budget > 0) {
        if (totalExpense > trip.budget) {
          insights +=
              'Notice: You are ${trip.currency} ${(totalExpense - trip.budget).toStringAsFixed(2)} over your planned budget.\n\n';
        } else {
          insights +=
              'Status: You have ${trip.currency} ${(trip.budget - totalExpense).toStringAsFixed(2)} remaining under your budget.\n\n';
        }
      } else {
        insights +=
            'Tip: Set a budget in Trip Settings to track your target spending.\n\n';
      }

      if (categoryTotals.isNotEmpty) {
        insights += 'Category Breakdown:\n';
        var sortedCategories = categoryTotals.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        for (var entry in sortedCategories) {
          final pct = (entry.value / totalExpense * 100).toStringAsFixed(1);
          insights +=
              '• ${entry.key}: ${trip.currency} ${entry.value.toStringAsFixed(2)} ($pct%)\n';
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
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}
