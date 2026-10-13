import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../providers/trip_provider.dart';
import '../models/trip.dart';
import '../theme_provider.dart';
import 'expense_screen.dart';
import 'past_trips_screen.dart';
import 'settings_screen.dart';

class StartScreen extends StatefulWidget {
  const StartScreen({super.key});

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {
  void _showCreateTripSheet(BuildContext context, TripProvider tripProvider,
      {String defaultCurrency = 'BDT'}) {
    final tripNameController = TextEditingController();
    final destinationController = TextEditingController();
    final budgetController = TextEditingController();

    DateTime startDate = DateTime.now();
    DateTime endDate = DateTime.now().add(const Duration(days: 7));
    String selectedCurrency = defaultCurrency;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext sheetContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 12,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const Text(
                      'Plan a New Trip',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Trip Name
                    TextField(
                      controller: tripNameController,
                      autofocus: true,
                      decoration: InputDecoration(
                        labelText: 'Trip Name',
                        hintText: 'e.g. Summer in Cox\'s Bazar',
                        prefixIcon: const Icon(Icons.flight_takeoff_rounded),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Destination
                    TextField(
                      controller: destinationController,
                      decoration: InputDecoration(
                        labelText: 'Destination',
                        hintText: 'e.g. Cox\'s Bazar, Bangladesh',
                        prefixIcon: const Icon(Icons.location_on_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Budget & Currency Row
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextField(
                            controller: budgetController,
                            decoration: InputDecoration(
                              labelText: 'Budget',
                              prefixIcon:
                                  const Icon(Icons.account_balance_wallet_outlined),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: DropdownButtonFormField<String>(
                            initialValue: selectedCurrency,
                            decoration: InputDecoration(
                              labelText: 'Currency',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onChanged: (val) {
                              if (val != null) {
                                setSheetState(() {
                                  selectedCurrency = val;
                                });
                              }
                            },
                            items: ['BDT', 'USD', 'EUR', 'GBP', 'INR']
                                .map((c) =>
                                    DropdownMenuItem(value: c, child: Text(c)))
                                .toList(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Date Range Selector Tile
                    InkWell(
                      onTap: () async {
                        final picked = await showDateRangePicker(
                          context: context,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2101),
                          initialDateRange: DateTimeRange(
                            start: startDate,
                            end: endDate.isBefore(startDate)
                                ? startDate.add(const Duration(days: 1))
                                : endDate,
                          ),
                        );
                        if (picked != null) {
                          setSheetState(() {
                            startDate = picked.start;
                            endDate = picked.end;
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_month_outlined),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Travel Dates',
                                      style: TextStyle(
                                          fontSize: 12, color: Colors.grey)),
                                  Text(
                                    '${DateFormat('MMM d, yyyy').format(startDate)} – ${DateFormat('MMM d, yyyy').format(endDate)}',
                                    style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.edit, size: 18),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Submit Button
                    ElevatedButton(
                      onPressed: () async {
                        final name = tripNameController.text.trim();
                        final dest = destinationController.text.trim();

                        if (name.isEmpty || dest.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Please enter a trip name and destination.')),
                          );
                          return;
                        }

                        final budget = double.tryParse(budgetController.text.trim()) ?? 0.0;
                        if (budget < 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Budget cannot be negative.')),
                          );
                          return;
                        }

                        final newTrip = Trip(
                          id: const Uuid().v4(),
                          name: name,
                          destination: dest,
                          startDate: startDate,
                          endDate: endDate,
                          budget: budget,
                          currency: selectedCurrency,
                          expenses: [],
                        );

                        await tripProvider.addTrip(newTrip);

                        if (!sheetContext.mounted) return;
                        tripProvider.selectTrip(newTrip);
                        Navigator.of(sheetContext).pop();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  ExpenseScreen(trip: newTrip)),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('Create Trip',
                          style: TextStyle(fontSize: 16)),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final tripProvider = Provider.of<TripProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final today = DateTime.now();
    final todayDateOnly = DateTime(today.year, today.month, today.day);

    // Filter active & upcoming trips (endDate is today or in future)
    final activeTrips = tripProvider.trips.where((t) {
      final tripEndDate =
          DateTime(t.endDate.year, t.endDate.month, t.endDate.day);
      return !tripEndDate.isBefore(todayDateOnly);
    }).toList();

    // Past completed trips
    final pastTrips = tripProvider.trips.where((t) {
      final tripEndDate =
          DateTime(t.endDate.year, t.endDate.month, t.endDate.day);
      return tripEndDate.isBefore(todayDateOnly);
    }).toList();

    final user = tripProvider.currentUser;
    final isGoogleUser = user != null && !user.isAnonymous;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tour Buddy'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
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
          PopupMenuButton<String>(
            tooltip: isGoogleUser ? (user.displayName ?? 'Account') : 'More options',
            onSelected: (val) async {
              if (val == 'demo') {
                await tripProvider.seedSampleTrips(force: true);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Demo trips loaded successfully!')),
                );
              } else if (val == 'signout') {
                await tripProvider.signOut();
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Signed out.')),
                );
              }
            },
            itemBuilder: (context) => [
              if (isGoogleUser) ...[
                PopupMenuItem(
                  enabled: false,
                  child: Text(
                    user.displayName ?? user.email ?? 'User',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const PopupMenuDivider(),
              ],
              const PopupMenuItem(
                value: 'demo',
                child: Row(
                  children: [
                    Icon(Icons.auto_awesome_outlined, size: 18),
                    SizedBox(width: 10),
                    Text('Load Demo Trips'),
                  ],
                ),
              ),
              if (isGoogleUser)
                const PopupMenuItem(
                  value: 'signout',
                  child: Row(
                    children: [
                      Icon(Icons.logout, size: 18, color: Colors.redAccent),
                      SizedBox(width: 10),
                      Text('Sign Out', style: TextStyle(color: Colors.redAccent)),
                    ],
                  ),
                ),
            ],
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: isGoogleUser
                  ? CircleAvatar(
                      radius: 14,
                      backgroundColor: Colors.white,
                      child: Text(
                        (user.displayName ?? 'U')
                            .substring(0, 1)
                            .toUpperCase(),
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue),
                      ),
                    )
                  : const Icon(Icons.more_vert),
            ),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // Non-intrusive Cloud Sync Banner when not signed in
          if (!isGoogleUser)
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
                ),
                child: Row(
                  children: [
                    Image.asset(
                      'assets/images/google_logo.png',
                      height: 22,
                      width: 22,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Enable Cloud Backup',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'Sync trips across all your devices',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        final error = await tripProvider.signInWithGoogle();
                        if (!context.mounted) return;
                        if (error != null && error != 'Sign-in cancelled') {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                error.contains('10') || error.contains('ApiException')
                                    ? 'Google Sign-in requires SHA-1 certificate in Firebase Console.'
                                    : 'Sign-in note: $error',
                              ),
                              duration: const Duration(seconds: 4),
                            ),
                          );
                        } else if (tripProvider.currentUser != null &&
                            !tripProvider.currentUser!.isAnonymous) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(
                                    'Signed in as ${tripProvider.currentUser!.displayName ?? "User"}')),
                          );
                        }
                      },
                      child: const Text('Sign In'),
                    ),
                  ],
                ),
              ),
            ),

          // Section Title
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Active & Upcoming',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (pastTrips.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const PastTripsScreen()),
                        );
                      },
                      child: Text(
                        'Past Trips (${pastTrips.length})',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Trip List or Empty State
          if (activeTrips.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.travel_explore_outlined,
                          size: 64, color: Colors.grey[350]),
                      const SizedBox(height: 16),
                      Text(
                        pastTrips.isNotEmpty
                            ? 'No active or upcoming trips.'
                            : 'No trips planned yet.',
                        style: TextStyle(fontSize: 17, color: Colors.grey[700]),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Start a new journey by creating a trip.',
                        style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                      ),
                      const SizedBox(height: 20),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 12,
                        runSpacing: 10,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () => _showCreateTripSheet(
                                context, tripProvider,
                                defaultCurrency: themeProvider.appCurrency),
                            icon: const Icon(Icons.add),
                            label: const Text('Create New Trip'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: () async {
                              await tripProvider.seedSampleTrips(force: true);
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Demo trips loaded!')),
                              );
                            },
                            icon: const Icon(Icons.auto_awesome_outlined),
                            label: const Text('Load Demo Trips'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final trip = activeTrips[index];
                  final totalSpent =
                      trip.expenses.fold(0.0, (sum, e) => sum + e.amount);

                  return Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: InkWell(
                      onTap: () {
                        tripProvider.selectTrip(trip);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => ExpenseScreen(trip: trip)),
                        );
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.grey.withValues(alpha: 0.12),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    trip.name,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    trip.currency,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 12,
                              runSpacing: 4,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.location_on_outlined,
                                        size: 15, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    ConstrainedBox(
                                      constraints:
                                          const BoxConstraints(maxWidth: 160),
                                      child: Text(
                                        trip.destination,
                                        style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey[700]),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.calendar_today_outlined,
                                        size: 14, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    ConstrainedBox(
                                      constraints:
                                          const BoxConstraints(maxWidth: 180),
                                      child: Text(
                                        '${DateFormat('MMM d').format(trip.startDate)} - ${DateFormat('MMM d, yyyy').format(trip.endDate)}',
                                        style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey[700]),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            if (trip.budget > 0) ...[
                              const SizedBox(height: 14),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(3),
                                child: LinearProgressIndicator(
                                  value: (totalSpent /
                                          trip.budget
                                              .clamp(0.01, double.infinity))
                                      .clamp(0.0, 1.0),
                                  minHeight: 5,
                                  backgroundColor: Colors.grey[200],
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    totalSpent > trip.budget
                                        ? Colors.redAccent
                                        : Colors.teal,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Flexible(
                                    child: Text(
                                      'Spent: ${trip.currency} ${totalSpent.toStringAsFixed(0)}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: totalSpent > trip.budget
                                            ? Colors.red
                                            : Colors.grey[800],
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      'Budget: ${trip.currency} ${trip.budget.toStringAsFixed(0)}',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600]),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ] else ...[
                              const SizedBox(height: 10),
                              Text(
                                'Total Spent: ${trip.currency} ${totalSpent.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                },
                childCount: activeTrips.length,
              ),
            ),
          const SliverToBoxAdapter(
            child: SizedBox(height: 80),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateTripSheet(context, tripProvider,
            defaultCurrency: themeProvider.appCurrency),
        icon: const Icon(Icons.add),
        label: const Text('New Trip'),
      ),
    );
  }
}
