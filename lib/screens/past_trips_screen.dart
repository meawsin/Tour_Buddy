import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../providers/trip_provider.dart';
import '../models/trip.dart';
import 'expense_screen.dart';
import 'start_screen.dart';
import 'settings_screen.dart';

class PastTripsScreen extends StatelessWidget {
  const PastTripsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tripProvider = Provider.of<TripProvider>(context);
    final primary = Theme.of(context).colorScheme.primary;
    final tertiary = Theme.of(context).colorScheme.tertiary;

    // Show all trips here (history view)
    final trips = tripProvider.trips;

    return Scaffold(
      appBar: AppBar(
        title: Text('Trip History',
            style: GoogleFonts.syne(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.home_rounded),
            onPressed: () => Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const StartScreen()),
              (route) => false,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: trips.isEmpty
          ? _buildEmpty(context)
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
              itemCount: trips.length,
              itemBuilder: (context, index) =>
                  _buildTripCard(context, trips[index], tripProvider),
            ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(Icons.history_rounded,
                size: 44,
                color: Theme.of(context).colorScheme.primary.withOpacity(0.6)),
          ),
          const SizedBox(height: 20),
          Text('No trips recorded yet',
              style: GoogleFonts.syne(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface,
              )),
          const SizedBox(height: 8),
          Text('Your completed trips will appear here',
              style: TextStyle(
                fontSize: 14,
                color:
                    Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              )),
        ],
      ),
    );
  }

  Widget _buildTripCard(
      BuildContext context, Trip trip, TripProvider tripProvider) {
    final primary = Theme.of(context).colorScheme.primary;
    final tertiary = Theme.of(context).colorScheme.tertiary;
    final totalSpent = trip.expenses
        .fold<double>(0, (sum, e) => sum + (e['amount'] as num).toDouble());
    final budget = trip.budget;
    final progress =
        budget > 0 ? (totalSpent / budget).clamp(0.0, 1.0) : 0.0;
    final isOver = totalSpent > budget && budget > 0;
    final daysTotal =
        trip.endDate.difference(trip.startDate).inDays + 1;

    return GestureDetector(
      onTap: () {
        tripProvider.selectTrip(trip);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ExpenseScreen(trip: trip)),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [primary.withOpacity(0.7), primary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: const Icon(Icons.flight_rounded,
                        color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          trip.name,
                          style: GoogleFonts.syne(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Icon(Icons.location_on_rounded,
                                size: 12,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withOpacity(0.45)),
                            const SizedBox(width: 3),
                            Text(
                              trip.destination,
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withOpacity(0.5),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(Icons.calendar_today_rounded,
                                size: 11,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withOpacity(0.45)),
                            const SizedBox(width: 3),
                            Text(
                              '$daysTotal days',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withOpacity(0.5),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Delete button
                  IconButton(
                    icon: Icon(Icons.delete_outline_rounded,
                        size: 20, color: tertiary.withOpacity(0.7)),
                    onPressed: () => _confirmDelete(context, tripProvider, trip),
                    style: IconButton.styleFrom(
                      backgroundColor: tertiary.withOpacity(0.08),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
            ),

            // Stats chips
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
              child: Row(
                children: [
                  _statChip(context,
                      label: 'Spent',
                      value: '${trip.currency} ${totalSpent.toStringAsFixed(0)}',
                      color: isOver ? tertiary : primary),
                  const SizedBox(width: 8),
                  _statChip(context,
                      label: 'Budget',
                      value: budget > 0
                          ? '${trip.currency} ${budget.toStringAsFixed(0)}'
                          : 'No budget',
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.4)),
                  const SizedBox(width: 8),
                  _statChip(context,
                      label: 'Entries',
                      value: '${trip.expenses.length}',
                      color: Theme.of(context).colorScheme.secondary),
                ],
              ),
            ),

            // Budget bar
            if (budget > 0)
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 5,
                    backgroundColor: Theme.of(context)
                        .colorScheme
                        .outline
                        .withOpacity(0.15),
                    valueColor: AlwaysStoppedAnimation(
                        isOver ? tertiary : primary),
                  ),
                ),
              )
            else
              const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }

  Widget _statChip(BuildContext context,
      {required String label, required String value, required Color color}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 10,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.45))),
            const SizedBox(height: 2),
            Text(value,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: color),
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(
      BuildContext context, TripProvider tripProvider, Trip trip) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete Trip?',
            style:
                GoogleFonts.syne(fontWeight: FontWeight.w700, fontSize: 18)),
        content: Text(
            'This will permanently delete "${trip.name}" and all its expenses.',
            style: const TextStyle(fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (trip.id != null) tripProvider.deleteTrip(trip.id!);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.tertiary,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
