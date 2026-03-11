import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:google_fonts/google_fonts.dart';
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

class _StartScreenState extends State<StartScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _tripNameController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();
  final TextEditingController _budgetController = TextEditingController();

  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 7));
  String _selectedCurrency = 'BDT';

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _tripNameController.dispose();
    _destinationController.dispose();
    _budgetController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Color get _primaryColor => Theme.of(context).colorScheme.primary;
  Color get _secondaryColor => Theme.of(context).colorScheme.secondary;
  Color get _tertiaryColor => Theme.of(context).colorScheme.tertiary;

  void _showCreateTripDialog(BuildContext context, TripProvider tripProvider) {
    _tripNameController.clear();
    _destinationController.clear();
    _budgetController.clear();
    _startDate = DateTime.now();
    _endDate = DateTime.now().add(const Duration(days: 7));
    _selectedCurrency = 'BDT';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CreateTripSheet(
        tripNameController: _tripNameController,
        destinationController: _destinationController,
        budgetController: _budgetController,
        initialStartDate: _startDate,
        initialEndDate: _endDate,
        initialCurrency: _selectedCurrency,
        onCreateTrip: (trip) async {
          await tripProvider.addTrip(trip);
          tripProvider.selectTrip(trip);
          if (context.mounted) {
            Navigator.of(context).pop();
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => ExpenseScreen(trip: trip)),
            );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tripProvider = Provider.of<TripProvider>(context);

    return Scaffold(
      body: FadeTransition(
        opacity: _fadeAnim,
        child: CustomScrollView(
          slivers: [
            // ── Hero App Bar ──────────────────────────────────────────
            SliverAppBar(
              expandedHeight: 120,
              floating: false,
              pinned: true,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              flexibleSpace: FlexibleSpaceBar(
                titlePadding:
                    const EdgeInsets.only(left: 20, bottom: 16, right: 60),
                title: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [_primaryColor, _tertiaryColor],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.map_outlined,
                          color: Colors.white, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Tour Buddy',
                      style: GoogleFonts.syne(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                if (tripProvider.currentUser != null &&
                    !tripProvider.currentUser!.isAnonymous)
                  IconButton(
                    icon: const Icon(Icons.logout_rounded),
                    onPressed: () async {
                      await tripProvider.signOut();
                      if (context.mounted) {
                        _showSnack(context, 'Signed out successfully');
                      }
                    },
                  ),
                IconButton(
                  icon: const Icon(Icons.history_rounded),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const PastTripsScreen()),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.settings_rounded),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const SettingsScreen()),
                  ),
                ),
                const SizedBox(width: 4),
              ],
            ),

            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // ── Sign-In Card (only for anonymous) ─────────────
                  if (tripProvider.currentUser == null ||
                      tripProvider.currentUser!.isAnonymous)
                    _buildSignInCard(context, tripProvider),

                  // ── Stats Row ─────────────────────────────────────
                  if (tripProvider.trips.isNotEmpty)
                    _buildStatsRow(context, tripProvider),

                  // ── Section Header ────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 16),
                    child: Row(
                      children: [
                        Text(
                          'Your Trips',
                          style: GoogleFonts.syne(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const Spacer(),
                        if (tripProvider.trips.isNotEmpty)
                          Text(
                            '${tripProvider.trips.length} active',
                            style: TextStyle(
                              fontSize: 13,
                              color: _primaryColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                      ],
                    ),
                  ),

                  // ── Trip List or Empty ────────────────────────────
                  if (tripProvider.trips.isEmpty)
                    _buildEmptyState(context, tripProvider)
                  else
                    ...tripProvider.trips
                        .map((trip) => _buildTripCard(context, trip, tripProvider))
                        ,
                ]),
              ),
            ),
          ],
        ),
      ),

      // ── FAB ────────────────────────────────────────────────────────
      floatingActionButton: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 20),
        child: FloatingActionButton.extended(
          onPressed: () => _showCreateTripDialog(context, tripProvider),
          backgroundColor: _primaryColor,
          foregroundColor: Colors.white,
          elevation: 8,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          icon: const Icon(Icons.add_rounded, size: 22),
          label: Text(
            'New Trip',
            style: GoogleFonts.syne(fontWeight: FontWeight.w600, fontSize: 15),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildSignInCard(BuildContext context, TripProvider tripProvider) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _primaryColor.withValues(alpha: 0.15),
            _secondaryColor.withValues(alpha: 0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _primaryColor.withValues(alpha: 0.25),
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _primaryColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.cloud_sync_rounded,
                    color: _primaryColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cloud Backup & Sync',
                      style: GoogleFonts.syne(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      'Access your trips from any device',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                await tripProvider.signInWithGoogle();
                if (!mounted) return;
                final user = tripProvider.currentUser;
                if (user != null && !user.isAnonymous) {
                  _showSnack(context,
                      'Signed in as ${user.displayName ?? "Google User"}');
                } else {
                  _showSnack(context, 'Sign-in cancelled');
                }
              },
              icon: Image.asset('assets/images/google_logo.png',
                  height: 20, width: 20),
              label: Text(
                'Continue with Google',
                style: GoogleFonts.syne(
                    fontWeight: FontWeight.w600, fontSize: 14),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                side: BorderSide(color: _primaryColor.withValues(alpha: 0.4)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                foregroundColor: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(BuildContext context, TripProvider tripProvider) {
    final totalTrips = tripProvider.trips.length;
    final totalBudget = tripProvider.trips
        .fold<double>(0, (sum, t) => sum + t.budget);
    final currency = tripProvider.trips.first.currency;

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Row(
        children: [
          _buildStatChip(context, Icons.flight_rounded, '$totalTrips', 'Trips'),
          const SizedBox(width: 10),
          _buildStatChip(context, Icons.account_balance_wallet_rounded,
              '$currency ${totalBudget.toStringAsFixed(0)}', 'Total Budget'),
          const SizedBox(width: 10),
          _buildStatChip(context, Icons.location_on_rounded,
              '${tripProvider.trips.map((t) => t.destination).toSet().length}',
              'Destinations'),
        ],
      ),
    );
  }

  Widget _buildStatChip(
      BuildContext context, IconData icon, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 4),
            Text(
              value,
              style: GoogleFonts.syne(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, TripProvider tripProvider) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _primaryColor.withValues(alpha: 0.2),
                  _tertiaryColor.withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Icon(Icons.travel_explore_rounded,
                size: 48, color: _primaryColor),
          ),
          const SizedBox(height: 24),
          Text(
            'No trips yet',
            style: GoogleFonts.syne(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the button below to plan\nyour first adventure',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color:
                  Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTripCard(
      BuildContext context, Trip trip, TripProvider tripProvider) {
    final isActive = DateTime.now().isBefore(trip.endDate) &&
        DateTime.now().isAfter(trip.startDate.subtract(const Duration(days: 1)));
    final totalSpent = (trip.expenses as List)
        .fold<double>(0, (sum, e) => sum + (e['amount'] as num).toDouble());
    final budget = trip.budget;
    final progress = budget > 0 ? (totalSpent / budget).clamp(0.0, 1.0) : 0.0;

    return Dismissible(
      key: Key(trip.id ?? trip.name),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text('Delete Trip?', style: GoogleFonts.syne(fontWeight: FontWeight.w700, fontSize: 18)),
            content: Text('This will permanently delete "${trip.name}" and all its expenses.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.tertiary),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ?? false;
      },
      onDismissed: (_) {
        if (trip.id != null) tripProvider.deleteTrip(trip.id!);
      },
      background: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.tertiary,
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 26),
      ),
      child: GestureDetector(
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
            color: isActive
                ? _primaryColor.withValues(alpha: 0.3)
                : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: _primaryColor.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isActive
                            ? [_primaryColor, _tertiaryColor]
                            : [Colors.grey.shade600, Colors.grey.shade700],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.flight_takeoff_rounded,
                        color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 14),
                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                trip.name,
                                style: GoogleFonts.syne(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            // Status badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: isActive
                                    ? _primaryColor.withValues(alpha: 0.15)
                                    : Colors.grey.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                isActive ? 'Active' : 'Ended',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: isActive ? _primaryColor : Colors.grey,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.location_on_rounded,
                                size: 13,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.5)),
                            const SizedBox(width: 3),
                            Text(
                              trip.destination,
                              style: TextStyle(
                                fontSize: 13,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.6),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Icon(Icons.calendar_today_rounded,
                                size: 12,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.5)),
                            const SizedBox(width: 3),
                            Text(
                              '${DateFormat('MMM d').format(trip.startDate)} – ${DateFormat('MMM d').format(trip.endDate)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.5),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.3)),
                ],
              ),
            ),

            // Budget progress bar
            if (budget > 0)
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${trip.currency} ${totalSpent.toStringAsFixed(0)} spent',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: progress > 0.85
                                ? _tertiaryColor
                                : _secondaryColor,
                          ),
                        ),
                        Text(
                          'of ${trip.currency} ${budget.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 6,
                        backgroundColor: Theme.of(context)
                            .colorScheme
                            .outline
                            .withValues(alpha: 0.2),
                        valueColor: AlwaysStoppedAnimation(
                          progress > 0.85 ? _tertiaryColor : _primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    ),
    );
  }

  void _showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}

// ── Create Trip Bottom Sheet ─────────────────────────────────────────────────

class _CreateTripSheet extends StatefulWidget {
  final TextEditingController tripNameController;
  final TextEditingController destinationController;
  final TextEditingController budgetController;
  final DateTime initialStartDate;
  final DateTime initialEndDate;
  final String initialCurrency;
  final Function(Trip) onCreateTrip;

  const _CreateTripSheet({
    required this.tripNameController,
    required this.destinationController,
    required this.budgetController,
    required this.initialStartDate,
    required this.initialEndDate,
    required this.initialCurrency,
    required this.onCreateTrip,
  });

  @override
  State<_CreateTripSheet> createState() => _CreateTripSheetState();
}

class _CreateTripSheetState extends State<_CreateTripSheet> {
  late DateTime _startDate;
  late DateTime _endDate;
  late String _currency;

  @override
  void initState() {
    super.initState();
    _startDate = widget.initialStartDate;
    _endDate = widget.initialEndDate;
    _currency = widget.initialCurrency;
  }


  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(24, 12, 24, 24 + bottomPad),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            Text(
              'New Trip',
              style: GoogleFonts.syne(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Fill in the details to start tracking',
              style: TextStyle(
                fontSize: 14,
                color:
                    Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55),
              ),
            ),
            const SizedBox(height: 24),

            // Trip Name
            _buildLabel('Trip Name'),
            TextField(
              controller: widget.tripNameController,
              decoration: const InputDecoration(
                hintText: 'e.g. Bangkok Summer 2025',
                prefixIcon: Icon(Icons.luggage_rounded, size: 20),
              ),
            ),
            const SizedBox(height: 14),

            // Destination
            _buildLabel('Destination'),
            TextField(
              controller: widget.destinationController,
              decoration: const InputDecoration(
                hintText: 'e.g. Bangkok, Thailand',
                prefixIcon: Icon(Icons.location_on_rounded, size: 20),
              ),
            ),
            const SizedBox(height: 14),

            // Budget + Currency row
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('Budget'),
                      TextField(
                        controller: widget.budgetController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          hintText: '0.00',
                          prefixIcon: Icon(Icons.wallet_rounded, size: 20),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('Currency'),
                      DropdownButtonFormField<String>(
                        value: _currency,
                        decoration: const InputDecoration(
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 12, vertical: 14),
                        ),
                        onChanged: (v) => setState(() => _currency = v!),
                        items: ['BDT', 'USD', 'EUR', 'GBP', 'INR', 'JPY', 'AUD']
                            .map((c) => DropdownMenuItem(
                                value: c, child: Text(c)))
                            .toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Date pickers
            _buildLabel('Trip Dates'),
            Row(
              children: [
                Expanded(
                  child: _buildDateButton(
                    context,
                    label: DateFormat('MMM d, yyyy').format(_startDate),
                    icon: Icons.flight_takeoff_rounded,
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _startDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2101),
                      );
                      if (picked != null) {
                        setState(() {
                          _startDate = picked;
                          if (_endDate.isBefore(_startDate)) {
                            _endDate =
                                _startDate.add(const Duration(days: 7));
                          }
                        });
                      }
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(Icons.arrow_forward_rounded,
                      size: 18,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.4)),
                ),
                Expanded(
                  child: _buildDateButton(
                    context,
                    label: DateFormat('MMM d, yyyy').format(_endDate),
                    icon: Icons.flight_land_rounded,
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _endDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2101),
                      );
                      if (picked != null) {
                        setState(() {
                          _endDate = picked;
                          if (_startDate.isAfter(_endDate)) {
                            _startDate = _endDate
                                .subtract(const Duration(days: 7));
                          }
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // Create button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (widget.tripNameController.text.isEmpty ||
                      widget.destinationController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content:
                            const Text('Please fill in trip name & destination'),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        margin: const EdgeInsets.all(16),
                      ),
                    );
                    return;
                  }
                  final trip = Trip(
                    id: const Uuid().v4(),
                    name: widget.tripNameController.text,
                    destination: widget.destinationController.text,
                    startDate: _startDate,
                    endDate: _endDate,
                    budget:
                        double.tryParse(widget.budgetController.text) ?? 0.0,
                    currency: _currency,
                    expenses: [],
                  );
                  widget.onCreateTrip(trip);
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Create Trip'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
        ),
      ),
    );
  }

  Widget _buildDateButton(BuildContext context,
      {required String label,
      required IconData icon,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 16,
                color:
                    Theme.of(context).colorScheme.primary.withValues(alpha: 0.8)),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
