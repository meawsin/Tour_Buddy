import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/trip_provider.dart';
import '../models/trip.dart';

class CompareTripsScreen extends StatelessWidget {
  const CompareTripsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tripProvider = Provider.of<TripProvider>(context);
    final allTrips = tripProvider.trips;

    // Filter out trips with no expenses for cleaner comparison if desired
    final tripsWithExpenses =
        allTrips.where((trip) => trip.expenses.isNotEmpty).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Compare Trips'),
        centerTitle: true,
      ),
      body: tripsWithExpenses.isEmpty
          ? const Center(
              child: Text(
                'No trips with expenses to compare yet!',
                style: TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),
            )
          : ListView.builder(
              itemCount: tripsWithExpenses.length,
              itemBuilder: (context, index) {
                final trip = tripsWithExpenses[index];
                double totalExpense =
                    trip.expenses.fold(0, (sum, item) => sum + item['amount']);
                double remainingBudget = trip.budget - totalExpense;

                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          trip.name,
                          style: const TextStyle(
                              fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                            'Total Expenses: ${trip.currency}${totalExpense.toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 16)),
                        Text(
                            'Budget: ${trip.currency}${trip.budget.toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 16)),
                        Text(
                          'Remaining Budget: ${trip.currency}${remainingBudget.toStringAsFixed(2)}',
                          style: TextStyle(
                              fontSize: 16,
                              color: remainingBudget >= 0
                                  ? Colors.green
                                  : Colors.red),
                        ),
                        const SizedBox(height: 12),
                        // Optional: Display expenses by category for this trip
                        const Text('Expense Breakdown:',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        ..._buildCategoryBreakdown(trip),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  List<Widget> _buildCategoryBreakdown(Trip trip) {
    Map<String, double> categoryTotals = {};
    for (var expense in trip.expenses) {
      String category = expense['category'] ?? 'Uncategorized';
      double amount = expense['amount'] ?? 0.0;
      categoryTotals.update(category, (value) => value + amount,
          ifAbsent: () => amount);
    }

    return categoryTotals.entries.map((entry) {
      return Padding(
        padding: const EdgeInsets.only(left: 8.0, top: 4.0),
        child: Text(
            '${entry.key}: ${trip.currency}${entry.value.toStringAsFixed(2)}'),
      );
    }).toList();
  }
}
