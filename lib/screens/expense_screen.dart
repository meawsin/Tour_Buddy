import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import '../providers/trip_provider.dart';
import '../models/trip.dart';
import 'analytics_screen.dart';

// ── Category definitions ────────────────────────────────────────────────────
class ExpenseCategory {
  final String id;
  final String label;
  final IconData icon;
  final Color color;
  const ExpenseCategory(this.id, this.label, this.icon, this.color);
}

const kCategories = [
  ExpenseCategory('Food', 'Food', Icons.restaurant_rounded, Color(0xFFFF9F43)),
  ExpenseCategory('Transport', 'Travel', Icons.flight_rounded, Color(0xFF54A0FF)),
  ExpenseCategory('Accommodation', 'Stay', Icons.hotel_rounded, Color(0xFF5F27CD)),
  ExpenseCategory('Shopping', 'Shop', Icons.shopping_bag_rounded, Color(0xFF00D2D3)),
  ExpenseCategory('Activities', 'Fun', Icons.attractions_rounded, Color(0xFFFF6B81)),
  ExpenseCategory('Other', 'Other', Icons.category_rounded, Color(0xFFA29BFE)),
];

ExpenseCategory categoryFor(String id) =>
    kCategories.firstWhere((c) => c.id == id, orElse: () => kCategories.last);

// ── Sort options ────────────────────────────────────────────────────────────
enum SortOption { dateDesc, dateAsc, amountDesc, amountAsc, category }

class ExpenseScreen extends StatefulWidget {
  final Trip trip;
  const ExpenseScreen({super.key, required this.trip});

  @override
  State<ExpenseScreen> createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends State<ExpenseScreen>
    with SingleTickerProviderStateMixin {
  final _titleCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  String _selectedCategory = 'Food';
  SortOption _sort = SortOption.dateDesc;
  String? _filterCategory;

  late AnimationController _fabAnim;

  @override
  void initState() {
    super.initState();
    _fabAnim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _fabAnim.forward();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _amountCtrl.dispose();
    _notesCtrl.dispose();
    _fabAnim.dispose();
    super.dispose();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  Color get _primary => Theme.of(context).colorScheme.primary;
  Color get _secondary => Theme.of(context).colorScheme.secondary;
  Color get _tertiary => Theme.of(context).colorScheme.tertiary;

  List<Map<String, dynamic>> _sorted(List<Map<String, dynamic>> raw) {
    final list = List<Map<String, dynamic>>.from(raw);
    if (_filterCategory != null) {
      list.retainWhere((e) => e['category'] == _filterCategory);
    }
    switch (_sort) {
      case SortOption.dateDesc:
        list.sort((a, b) => _parseDate(b['date']).compareTo(_parseDate(a['date'])));
      case SortOption.dateAsc:
        list.sort((a, b) => _parseDate(a['date']).compareTo(_parseDate(b['date'])));
      case SortOption.amountDesc:
        list.sort((a, b) => (b['amount'] as num).compareTo(a['amount'] as num));
      case SortOption.amountAsc:
        list.sort((a, b) => (a['amount'] as num).compareTo(b['amount'] as num));
      case SortOption.category:
        list.sort((a, b) =>
            (a['category'] as String).compareTo(b['category'] as String));
    }
    return list;
  }

  DateTime _parseDate(dynamic v) {
    if (v == null) return DateTime.now();
    try { return DateTime.parse(v.toString()); } catch (_) { return DateTime.now(); }
  }

  double _totalSpentOf(Trip t) =>
      t.expenses.fold(0, (s, e) => s + (e['amount'] as num));

  double _budgetProgressOf(Trip t) =>
      t.budget > 0 ? (_totalSpentOf(t) / t.budget).clamp(0.0, 1.0) : 0.0;

  // Live getter — always uses fresh trip data
  Trip get _liveTripData {
    final p = Provider.of<TripProvider>(context, listen: false);
    return p.trips.firstWhere((t) => t.id == widget.trip.id, orElse: () => widget.trip);
  }
  double get _totalSpent => _totalSpentOf(_liveTripData);

  Map<String, double> _categoryTotalsOf(Trip t) {
    final Map<String, double> map = {};
    for (final e in t.expenses) {
      final cat = e['category'] as String? ?? 'Other';
      map[cat] = (map[cat] ?? 0) + (e['amount'] as num);
    }
    return map;
  }


  // ── Add Expense Sheet ──────────────────────────────────────────────────────
  void _showAddExpenseSheet() {
    _titleCtrl.clear();
    _amountCtrl.clear();
    _notesCtrl.clear();
    _selectedCategory = 'Food';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final pad = MediaQuery.of(ctx).viewInsets.bottom;
          return Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: EdgeInsets.fromLTRB(24, 12, 24, 24 + pad),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle
                  Center(
                    child: Container(
                      width: 40, height: 4,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                  Text('Add Expense 💸',
                      style: GoogleFonts.syne(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).colorScheme.onSurface)),
                  const SizedBox(height: 4),
                  Text('Track your spending for ${widget.trip.name}',
                      style: TextStyle(
                          fontSize: 13,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.5))),
                  const SizedBox(height: 22),

                  // Title
                  _sheetLabel('Title'),
                  TextField(
                    controller: _titleCtrl,
                    decoration: const InputDecoration(
                      hintText: 'e.g. Street food lunch',
                      prefixIcon: Icon(Icons.receipt_long_rounded, size: 20),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Amount
                  _sheetLabel('Amount (${widget.trip.currency})'),
                  TextField(
                    controller: _amountCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      hintText: '0.00',
                      prefixIcon: Icon(Icons.payments_rounded, size: 20),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Category picker
                  _sheetLabel('Category'),
                  SizedBox(
                    height: 76,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: kCategories.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (_, i) {
                        final cat = kCategories[i];
                        final sel = _selectedCategory == cat.id;
                        return GestureDetector(
                          onTap: () => setSheetState(
                              () => _selectedCategory = cat.id),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            width: 66,
                            decoration: BoxDecoration(
                              color: sel
                                  ? cat.color.withValues(alpha: 0.2)
                                  : Theme.of(context)
                                      .colorScheme
                                      .surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: sel
                                    ? cat.color
                                    : Theme.of(context)
                                        .colorScheme
                                        .outline
                                        .withValues(alpha: 0.3),
                                width: sel ? 1.5 : 1,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(cat.icon,
                                    size: 24,
                                    color: sel
                                        ? cat.color
                                        : Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withValues(alpha: 0.5)),
                                const SizedBox(height: 5),
                                Text(cat.label,
                                    style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: sel
                                            ? FontWeight.w700
                                            : FontWeight.normal,
                                        color: sel
                                            ? cat.color
                                            : Theme.of(context)
                                                .colorScheme
                                                .onSurface
                                                .withValues(alpha: 0.5))),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Notes
                  _sheetLabel('Notes (optional)'),
                  TextField(
                    controller: _notesCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Any extra details...',
                      prefixIcon: Icon(Icons.notes_rounded, size: 20),
                    ),
                  ),
                  const SizedBox(height: 26),

                  // Submit
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _submitExpense(context),
                      style: ElevatedButton.styleFrom(
                          padding:
                              const EdgeInsets.symmetric(vertical: 16)),
                      child: const Text('Add Expense'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _submitExpense(BuildContext ctx) {
    final title = _titleCtrl.text.trim();
    final amount = double.tryParse(_amountCtrl.text);
    if (title.isEmpty || amount == null || amount <= 0) {
      ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
        content: const Text('Please enter a valid title and amount'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ));
      return;
    }
    final expense = {
      'id': const Uuid().v4(),
      'title': title,
      'amount': amount,
      'category': _selectedCategory,
      'notes': _notesCtrl.text.trim(),
      'date': DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now()),
    };
    Provider.of<TripProvider>(ctx, listen: false)
        .addExpenseToCurrentTrip(widget.trip, expense);
    Navigator.pop(ctx);
    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
      content: Text('$title added'),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
  }

  // ── Main Build ─────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final tripProvider = Provider.of<TripProvider>(context);
    // Use live trip from provider so UI updates instantly after adding expense
    final liveTrip = tripProvider.trips.firstWhere(
      (t) => t.id == widget.trip.id,
      orElse: () => widget.trip,
    );
    final expenses = liveTrip.expenses;
    final sorted = _sorted(expenses);
    final budget = liveTrip.budget;
    final totalSpent = _totalSpentOf(liveTrip);
    final remaining = budget - totalSpent;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── Hero App Bar ─────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _primary.withValues(alpha: 0.15),
                      _tertiary.withValues(alpha: 0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding:
                        const EdgeInsets.fromLTRB(20, 60, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          widget.trip.name,
                          style: GoogleFonts.syne(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color:
                                Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.location_on_rounded,
                                size: 14,
                                color: _primary.withValues(alpha: 0.8)),
                            const SizedBox(width: 4),
                            Text(widget.trip.destination,
                                style: TextStyle(
                                    fontSize: 13,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.6))),
                            const SizedBox(width: 12),
                            Icon(Icons.calendar_today_rounded,
                                size: 12,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.4)),
                            const SizedBox(width: 4),
                            Text(
                              '${DateFormat('MMM d').format(widget.trip.startDate)} – ${DateFormat('MMM d').format(widget.trip.endDate)}',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.5)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              titlePadding: EdgeInsets.zero,
              title: const SizedBox.shrink(), // title shown in background instead
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.bar_chart_rounded),
                tooltip: 'Analytics',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AnalyticsScreen(trip: widget.trip),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.share_rounded),
                onPressed: () => _shareTrip(context),
              ),
              PopupMenuButton<SortOption>(
                icon: const Icon(Icons.sort_rounded),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                onSelected: (v) => setState(() => _sort = v),
                itemBuilder: (_) => [
                  _menuItem(SortOption.dateDesc, 'Newest first',
                      Icons.arrow_downward_rounded),
                  _menuItem(SortOption.dateAsc, 'Oldest first',
                      Icons.arrow_upward_rounded),
                  _menuItem(SortOption.amountDesc, 'Highest amount',
                      Icons.trending_down_rounded),
                  _menuItem(SortOption.amountAsc, 'Lowest amount',
                      Icons.trending_up_rounded),
                  _menuItem(SortOption.category, 'By category',
                      Icons.category_rounded),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.edit_rounded),
                onPressed: () => _showTripSettingsSheet(context, tripProvider),
              ),
            ],
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([

                // ── Budget Card ────────────────────────────────────
                _buildBudgetCard(context, liveTrip, budget, totalSpent, remaining),

                const SizedBox(height: 20),

                // ── Category Breakdown ─────────────────────────────
                if (expenses.isNotEmpty) ...[
                  _buildCategoryBreakdown(context, liveTrip),
                  const SizedBox(height: 20),
                ],

                // ── Expenses Header ────────────────────────────────
                Row(
                  children: [
                    Text('Expenses',
                        style: GoogleFonts.syne(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface)),
                    const Spacer(),
                    if (expenses.isNotEmpty)
                      TextButton.icon(
                        onPressed: () =>
                            _showResetConfirmation(context, tripProvider),
                        icon: Icon(Icons.delete_sweep_rounded,
                            size: 16, color: _tertiary),
                        label: Text('Clear all',
                            style: TextStyle(
                                fontSize: 12, color: _tertiary)),
                        style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4)),
                      ),
                  ],
                ),
                const SizedBox(height: 10),

                // ── Category filter chips ──────────────────────────
                if (expenses.isNotEmpty)
                  _buildFilterChips(context, expenses),

                const SizedBox(height: 12),

                // ── Expense list or empty ──────────────────────────
                if (expenses.isEmpty)
                  _buildEmptyExpenses(context)
                else if (sorted.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text('No expenses in this category',
                          style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.4))),
                    ),
                  )
                else
                  ...sorted.map((e) => _buildExpenseCard(context, e, tripProvider)),
              ]),
            ),
          ),
        ],
      ),

      // ── FAB ──────────────────────────────────────────────────────
      floatingActionButton: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 20),
        child: FloatingActionButton.extended(
          onPressed: _showAddExpenseSheet,
          backgroundColor: _primary,
          foregroundColor: Colors.white,
          elevation: 8,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          icon: const Icon(Icons.add_rounded, size: 22),
          label: Text('Add Expense',
              style: GoogleFonts.syne(
                  fontWeight: FontWeight.w600, fontSize: 15)),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  // ── Budget Card ────────────────────────────────────────────────────────────
  Widget _buildBudgetCard(
      BuildContext context, Trip liveTrip, double budget, double totalSpent, double remaining) {
    final isOver = remaining < 0 && budget > 0;
    final progressColor = isOver ? _tertiary : _primary;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _primary.withValues(alpha: 0.12),
            _secondary.withValues(alpha: 0.06),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total Spent',
                        style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.55))),
                    const SizedBox(height: 4),
                    Text(
                      '${liveTrip.currency} ${totalSpent.toStringAsFixed(2)}',
                      style: GoogleFonts.syne(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: Theme.of(context).colorScheme.onSurface),
                    ),
                  ],
                ),
              ),
              if (budget > 0)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(isOver ? '⚠️ Over budget' : '✅ On track',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isOver ? _tertiary : _secondary)),
                    const SizedBox(height: 4),
                    Text(
                      isOver
                          ? '${liveTrip.currency} ${remaining.abs().toStringAsFixed(0)} over'
                          : '${liveTrip.currency} ${remaining.toStringAsFixed(0)} left',
                      style: GoogleFonts.syne(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isOver ? _tertiary : _secondary),
                    ),
                  ],
                ),
            ],
          ),
          if (budget > 0) ...[
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Budget: ${liveTrip.currency} ${budget.toStringAsFixed(0)}',
                    style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.45))),
                Text('${(_budgetProgressOf(liveTrip) * 100).toInt()}%',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: progressColor)),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: _budgetProgressOf(liveTrip),
                minHeight: 8,
                backgroundColor:
                    Theme.of(context).colorScheme.outline.withValues(alpha: 0.15),
                valueColor: AlwaysStoppedAnimation(progressColor),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Category Breakdown ─────────────────────────────────────────────────────
  Widget _buildCategoryBreakdown(BuildContext context, Trip liveTrip) {
    final totals = _categoryTotalsOf(liveTrip);
    if (totals.isEmpty) return const SizedBox.shrink();
    final sorted = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('By Category',
            style: GoogleFonts.syne(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface)),
        const SizedBox(height: 12),
        ...sorted.map((entry) {
          final cat = categoryFor(entry.key);
          final pct = _totalSpent > 0 ? entry.value / _totalSpent : 0.0;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: cat.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(cat.icon, size: 16, color: cat.color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(cat.label,
                              style: const TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w500)),
                          Text(
                            '${widget.trip.currency} ${entry.value.toStringAsFixed(0)}  (${(pct * 100).toInt()}%)',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: cat.color),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: LinearProgressIndicator(
                          value: pct,
                          minHeight: 4,
                          backgroundColor: Theme.of(context)
                              .colorScheme
                              .outline
                              .withValues(alpha: 0.12),
                          valueColor: AlwaysStoppedAnimation(cat.color),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // ── Filter Chips ───────────────────────────────────────────────────────────
  Widget _buildFilterChips(BuildContext context, List<Map<String, dynamic>> expenses) {
    final usedCats = expenses
        .map((e) => e['category'] as String? ?? 'Other')
        .toSet()
        .toList();

    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _filterChip(context, null, 'All'),
          ...usedCats.map((cat) => _filterChip(context, cat, cat)),
        ],
      ),
    );
  }

  Widget _filterChip(BuildContext context, String? catId, String label) {
    final active = _filterCategory == catId;
    final cat = catId != null ? categoryFor(catId) : null;
    return GestureDetector(
      onTap: () => setState(() => _filterCategory = catId),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: active
              ? (cat?.color ?? _primary).withValues(alpha: 0.15)
              : Theme.of(context)
                  .colorScheme
                  .surfaceContainerHighest
                  .withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active
                ? (cat?.color ?? _primary)
                : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: active ? FontWeight.w700 : FontWeight.normal,
            color: active
                ? (cat?.color ?? _primary)
                : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ),
    );
  }

  // ── Expense Card ───────────────────────────────────────────────────────────
  Widget _buildExpenseCard(BuildContext context,
      Map<String, dynamic> expense, TripProvider tripProvider) {
    final cat = categoryFor(expense['category'] as String? ?? 'Other');
    final amount = (expense['amount'] as num).toDouble();
    final date = _parseDate(expense['date']);
    final notes = expense['notes'] as String?;

    return Dismissible(
      key: Key(expense['id'] ?? expense['title']),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: _tertiary.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(Icons.delete_rounded, color: _tertiary),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            title: Text('Delete expense?',
                style: GoogleFonts.syne(
                    fontWeight: FontWeight.w700, fontSize: 17)),
            content: Text('Remove "${expense['title']}" from this trip?'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                    backgroundColor: _tertiary),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) {
        final currentTrip = tripProvider.trips.firstWhere((t) => t.id == widget.trip.id, orElse: () => widget.trip);
        final updated = List<Map<String, dynamic>>.from(currentTrip.expenses)
          ..removeWhere(
              (e) => e['id'] == expense['id'] && e['title'] == expense['title']);
        currentTrip.expenses.clear();
        currentTrip.expenses.addAll(updated);
        tripProvider.updateTrip(currentTrip);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Removed "${expense['title']}"'),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color:
                  Theme.of(context).colorScheme.outline.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: cat.color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(cat.icon, color: cat.color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(expense['title'] as String,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: cat.color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(cat.label,
                            style: TextStyle(
                                fontSize: 10,
                                color: cat.color,
                                fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        DateFormat('MMM d, h:mm a').format(date),
                        style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.4)),
                      ),
                    ],
                  ),
                  if (notes != null && notes.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(notes,
                        style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.4)),
                        overflow: TextOverflow.ellipsis),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${widget.trip.currency} ${amount.toStringAsFixed(2)}',
              style: GoogleFonts.syne(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _tertiary),
            ),
          ],
        ),
      ),
    );
  }

  // ── Empty state ────────────────────────────────────────────────────────────
  Widget _buildEmptyExpenses(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: _primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Icon(Icons.receipt_long_rounded,
                size: 38, color: _primary.withValues(alpha: 0.6)),
          ),
          const SizedBox(height: 16),
          Text('No expenses yet',
              style: GoogleFonts.syne(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface)),
          const SizedBox(height: 8),
          Text('Tap "Add Expense" to start tracking\nyour spending',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.45),
                  height: 1.5)),
        ],
      ),
    );
  }

  // ── Trip Settings Sheet ────────────────────────────────────────────────────
  void _showTripSettingsSheet(
      BuildContext context, TripProvider tripProvider) {
    final budgetCtrl = TextEditingController(
        text: widget.trip.budget > 0
            ? widget.trip.budget.toStringAsFixed(0)
            : '');
    String currency = widget.trip.currency;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) {
          final pad = MediaQuery.of(ctx).viewInsets.bottom;
          return Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: EdgeInsets.fromLTRB(24, 12, 24, 24 + pad),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40, height: 4,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                  Text('Trip Settings ⚙️',
                      style: GoogleFonts.syne(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).colorScheme.onSurface)),
                  const SizedBox(height: 22),
                  _sheetLabel('Budget'),
                  TextField(
                    controller: budgetCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: '0.00',
                      prefixIcon:
                          const Icon(Icons.wallet_rounded, size: 20),
                      prefixText: '$currency ',
                    ),
                  ),
                  const SizedBox(height: 14),
                  _sheetLabel('Currency'),
                  DropdownButtonFormField<String>(
                    value: currency,
                    decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12)),
                    onChanged: (v) { if (v != null) setS(() => currency = v); },
                    items: ['BDT', 'USD', 'EUR', 'GBP', 'INR', 'JPY', 'AUD']
                        .map((c) => DropdownMenuItem(
                            value: c, child: Text(c)))
                        .toList(),
                  ),
                  const SizedBox(height: 26),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        tripProvider.updateCurrentTrip(
                          trip: widget.trip,
                          budget: double.tryParse(budgetCtrl.text),
                          currency: currency,
                        );
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: const Text('Trip settings saved'),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          margin: const EdgeInsets.all(16),
                        ));
                      },
                      style: ElevatedButton.styleFrom(
                          padding:
                              const EdgeInsets.symmetric(vertical: 16)),
                      child: const Text('Save Changes'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showResetConfirmation(
      BuildContext context, TripProvider tripProvider) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Clear All Expenses?',
            style: GoogleFonts.syne(
                fontWeight: FontWeight.w700, fontSize: 18)),
        content: const Text(
            'This will permanently remove all expenses for this trip.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              tripProvider.resetCurrentTripExpenses(widget.trip);
              Navigator.pop(context);
            },
            style:
                ElevatedButton.styleFrom(backgroundColor: _tertiary),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  void _shareTrip(BuildContext context) {
    final buffer = StringBuffer();
    buffer.writeln('🗺️ Trip: ${widget.trip.name}');
    buffer.writeln('📍 ${widget.trip.destination}');
    buffer.writeln(
        '📅 ${DateFormat('MMM d').format(widget.trip.startDate)} – ${DateFormat('MMM d, yyyy').format(widget.trip.endDate)}');
    buffer.writeln(
        '💰 Total Spent: ${widget.trip.currency} ${_totalSpent.toStringAsFixed(2)}');
    if (widget.trip.budget > 0) {
      buffer.writeln(
          '🎯 Budget: ${widget.trip.currency} ${widget.trip.budget.toStringAsFixed(2)}');
    }
    buffer.writeln('\nExpenses:');
    for (final e in widget.trip.expenses) {
      buffer.writeln(
          '• ${e['title']}: ${widget.trip.currency} ${(e['amount'] as num).toStringAsFixed(2)}');
    }
    Share.share(buffer.toString(), subject: 'Tour Buddy – ${widget.trip.name}');
  }

  PopupMenuItem<SortOption> _menuItem(
      SortOption val, String label, IconData icon) {
    return PopupMenuItem(
      value: val,
      child: Row(
        children: [
          Icon(icon, size: 18,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  Widget _sheetLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
          color:
              Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
        ),
      ),
    );
  }
}
