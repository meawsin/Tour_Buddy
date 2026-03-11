import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../providers/trip_provider.dart';
import '../models/trip.dart';

// Re-use category colours from expense_screen
const _catColors = {
  'Food': Color(0xFFFF9F43),
  'Transport': Color(0xFF54A0FF),
  'Accommodation': Color(0xFF5F27CD),
  'Shopping': Color(0xFF00D2D3),
  'Activities': Color(0xFFFF6B81),
  'Other': Color(0xFFA29BFE),
};

Color _colorFor(String cat) =>
    _catColors[cat] ?? const Color(0xFFA29BFE);

class AnalyticsScreen extends StatefulWidget {
  final Trip trip;
  const AnalyticsScreen({super.key, required this.trip});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  int _touchedPieIndex = -1;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  Trip get _live {
    final p = Provider.of<TripProvider>(context, listen: false);
    return p.trips.firstWhere((t) => t.id == widget.trip.id,
        orElse: () => widget.trip);
  }

  double get _totalSpent =>
      _live.expenses.fold(0, (s, e) => s + (e['amount'] as num? ?? 0));

  Map<String, double> get _byCategory {
    final map = <String, double>{};
    for (final e in _live.expenses) {
      final cat = e['category'] as String? ?? 'Other';
      map[cat] = (map[cat] ?? 0) + (e['amount'] as num? ?? 0);
    }
    return map;
  }

  /// Daily totals between trip start and end
  Map<String, double> get _byDay {
    final map = <String, double>{};
    for (final e in _live.expenses) {
      final raw = e['date'] as String?;
      if (raw == null) continue;
      try {
        final d = DateTime.parse(raw);
        final key = DateFormat('MMM d').format(d);
        map[key] = (map[key] ?? 0) + (e['amount'] as num? ?? 0);
      } catch (_) {}
    }
    return map;
  }

  List<MapEntry<String, double>> get _sortedDays {
    final days = _byDay.entries.toList();
    days.sort((a, b) {
      final af = DateFormat('MMM d').parse(a.key);
      final bf = DateFormat('MMM d').parse(b.key);
      return af.compareTo(bf);
    });
    return days;
  }

  int get _tripDays =>
      _live.endDate.difference(_live.startDate).inDays + 1;

  double get _dailyAvg =>
      _tripDays > 0 ? _totalSpent / _tripDays : 0;

  MapEntry<String, double>? get _topDay {
    if (_byDay.isEmpty) return null;
    return _byDay.entries.reduce((a, b) => a.value > b.value ? a : b);
  }

  MapEntry<String, double>? get _topCategory {
    if (_byCategory.isEmpty) return null;
    return _byCategory.entries.reduce((a, b) => a.value > b.value ? a : b);
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    // Listen to provider so charts update live
    Provider.of<TripProvider>(context);
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: Text('Analytics',
            style: GoogleFonts.syne(fontWeight: FontWeight.w700)),
        bottom: TabBar(
          controller: _tabs,
          labelStyle:
              GoogleFonts.syne(fontWeight: FontWeight.w600, fontSize: 13),
          unselectedLabelStyle: const TextStyle(fontSize: 13),
          indicatorColor: primary,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'By Day'),
            Tab(text: 'Categories'),
          ],
        ),
      ),
      body: _live.expenses.isEmpty
          ? _buildEmpty(context)
          : TabBarView(
              controller: _tabs,
              children: [
                _buildOverview(context),
                _buildDailyTab(context),
                _buildCategoryTab(context),
              ],
            ),
    );
  }

  // ── Empty State ────────────────────────────────────────────────────────────
  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .primary
                  .withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(Icons.bar_chart_rounded,
                size: 46,
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.5)),
          ),
          const SizedBox(height: 20),
          Text('No data yet',
              style: GoogleFonts.syne(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface)),
          const SizedBox(height: 8),
          Text('Add expenses to see analytics',
              style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.5))),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // TAB 1 — OVERVIEW
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildOverview(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final secondary = Theme.of(context).colorScheme.secondary;
    final tertiary = Theme.of(context).colorScheme.tertiary;
    final budget = _live.budget;
    final spent = _totalSpent;
    final progress = budget > 0 ? (spent / budget).clamp(0.0, 1.0) : 0.0;
    final isOver = spent > budget && budget > 0;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      children: [

        // ── Trip summary card ──────────────────────────────────────
        _card(context, child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              _iconBox(context, Icons.flight_rounded, primary),
              const SizedBox(width: 12),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_live.name,
                      style: GoogleFonts.syne(
                          fontWeight: FontWeight.w700, fontSize: 16,
                          color: Theme.of(context).colorScheme.onSurface)),
                  Text('${_live.destination} · $_tripDays days',
                      style: TextStyle(fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurface
                              .withValues(alpha: 0.5))),
                ],
              )),
            ]),
            const SizedBox(height: 20),

            // Big spent number
            Text(_live.currency,
                style: TextStyle(fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurface
                        .withValues(alpha: 0.5))),
            Text(spent.toStringAsFixed(2),
                style: GoogleFonts.syne(
                    fontSize: 40, fontWeight: FontWeight.w800,
                    color: Theme.of(context).colorScheme.onSurface)),
            Text('total spent',
                style: TextStyle(fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurface
                        .withValues(alpha: 0.45))),

            if (budget > 0) ...[
              const SizedBox(height: 16),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Budget: ${_live.currency} ${budget.toStringAsFixed(0)}',
                      style: TextStyle(fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurface
                              .withValues(alpha: 0.5))),
                  Text('${(progress * 100).toInt()}%  ${isOver ? "⚠️ over" : "✅ ok"}',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                          color: isOver ? tertiary : secondary)),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: progress, minHeight: 8,
                  backgroundColor: Theme.of(context).colorScheme.outline
                      .withValues(alpha: 0.15),
                  valueColor: AlwaysStoppedAnimation(isOver ? tertiary : primary),
                ),
              ),
            ],
          ],
        )),

        const SizedBox(height: 16),

        // ── Stat chips ────────────────────────────────────────────
        Row(children: [
          _statChip(context,
              icon: Icons.receipt_long_rounded,
              label: 'Expenses',
              value: '${_live.expenses.length}',
              color: primary),
          const SizedBox(width: 12),
          _statChip(context,
              icon: Icons.today_rounded,
              label: 'Daily avg',
              value: '${_live.currency} ${_dailyAvg.toStringAsFixed(0)}',
              color: secondary),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          _statChip(context,
              icon: Icons.trending_up_rounded,
              label: 'Top day',
              value: _topDay != null
                  ? '${_topDay!.key} (${_live.currency} ${_topDay!.value.toStringAsFixed(0)})'
                  : '—',
              color: const Color(0xFFFF9F43)),
          const SizedBox(width: 12),
          _statChip(context,
              icon: Icons.category_rounded,
              label: 'Top category',
              value: _topCategory?.key ?? '—',
              color: _topCategory != null
                  ? _colorFor(_topCategory!.key)
                  : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4)),
        ]),

        const SizedBox(height: 24),

        // ── Mini donut preview ────────────────────────────────────
        if (_byCategory.isNotEmpty) ...[
          Text('Spending breakdown',
              style: GoogleFonts.syne(
                  fontSize: 16, fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface)),
          const SizedBox(height: 14),
          _card(context, child: SizedBox(
            height: 220,
            child: _buildDonut(context, mini: true),
          )),
        ],
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // TAB 2 — BY DAY (Bar Chart)
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildDailyTab(BuildContext context) {
    final days = _sortedDays;
    final primary = Theme.of(context).colorScheme.primary;

    if (days.isEmpty) {
      return _buildEmpty(context);
    }

    final maxY = days.fold<double>(0, (prev, e) => e.value > prev ? e.value : prev);
    final barGroups = days.asMap().entries.map((entry) {
      return BarChartGroupData(
        x: entry.key,
        barRods: [
          BarChartRodData(
            toY: entry.value.toY.toDouble(),
            color: primary,
            width: days.length > 7 ? 10 : 20,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: maxY * 1.15,
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.08),
            ),
          ),
        ],
      );
    }).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      children: [
        Text('Daily Spending',
            style: GoogleFonts.syne(
                fontSize: 18, fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface)),
        const SizedBox(height: 4),
        Text('${_live.currency} per day across your trip',
            style: TextStyle(fontSize: 13,
                color: Theme.of(context).colorScheme.onSurface
                    .withValues(alpha: 0.5))),
        const SizedBox(height: 16),

        _card(context, child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 20, 16, 12),
          child: SizedBox(
            height: 240,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxY * 1.15,
                barGroups: barGroups,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (v) => FlLine(
                    color: Theme.of(context).colorScheme.outline
                        .withValues(alpha: 0.15),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 46,
                      getTitlesWidget: (v, _) => Text(
                        v == 0 ? '' : _live.currency == 'BDT'
                            ? '৳${v.toInt()}'
                            : '${v.toInt()}',
                        style: TextStyle(fontSize: 10,
                            color: Theme.of(context).colorScheme.onSurface
                                .withValues(alpha: 0.4)),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      getTitlesWidget: (v, _) {
                        final i = v.toInt();
                        if (i < 0 || i >= days.length) return const SizedBox();
                        // Show every label if ≤7 days, else every other
                        if (days.length > 7 && i % 2 != 0) return const SizedBox();
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(days[i].key,
                            style: TextStyle(fontSize: 10,
                                color: Theme.of(context).colorScheme.onSurface
                                    .withValues(alpha: 0.5)),
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) =>
                        Theme.of(context).colorScheme.surface,
                    getTooltipItem: (group, _, rod, __) => BarTooltipItem(
                      '${days[group.x].key}\n',
                      GoogleFonts.syne(
                          fontWeight: FontWeight.w600, fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurface),
                      children: [
                        TextSpan(
                          text: '${_live.currency} ${rod.toY.toStringAsFixed(0)}',
                          style: TextStyle(
                              color: primary,
                              fontWeight: FontWeight.w700,
                              fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        )),

        const SizedBox(height: 20),

        // ── Daily breakdown list ────────────────────────────────
        Text('Day by day',
            style: GoogleFonts.syne(
                fontSize: 16, fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface)),
        const SizedBox(height: 12),
        ...days.map((entry) {
          final pct = _totalSpent > 0 ? entry.value / _totalSpent : 0.0;
          final isTop = _topDay?.key == entry.key;
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isTop
                    ? primary.withValues(alpha: 0.4)
                    : Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
            child: Row(children: [
              Container(
                width: 42, height: 42,
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: isTop ? 0.2 : 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.calendar_today_rounded,
                    size: 18, color: primary),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Text(entry.key,
                        style: GoogleFonts.syne(
                            fontWeight: FontWeight.w600, fontSize: 14,
                            color: Theme.of(context).colorScheme.onSurface)),
                    if (isTop) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text('Top day',
                            style: TextStyle(fontSize: 10,
                                color: primary, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ]),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      value: pct, minHeight: 4,
                      backgroundColor: Theme.of(context).colorScheme.outline
                          .withValues(alpha: 0.12),
                      valueColor: AlwaysStoppedAnimation(primary),
                    ),
                  ),
                ],
              )),
              const SizedBox(width: 12),
              Text(
                '${_live.currency} ${entry.value.toStringAsFixed(0)}',
                style: GoogleFonts.syne(
                    fontWeight: FontWeight.w700, fontSize: 14,
                    color: primary),
              ),
            ]),
          );
        }),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // TAB 3 — CATEGORIES (Pie/Donut + list)
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildCategoryTab(BuildContext context) {
    final cats = _byCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      children: [
        Text('Category Breakdown',
            style: GoogleFonts.syne(
                fontSize: 18, fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface)),
        const SizedBox(height: 4),
        Text('Where your money went',
            style: TextStyle(fontSize: 13,
                color: Theme.of(context).colorScheme.onSurface
                    .withValues(alpha: 0.5))),
        const SizedBox(height: 16),

        // ── Donut chart ─────────────────────────────────────────
        _card(context, child: SizedBox(
          height: 280,
          child: _buildDonut(context, mini: false),
        )),

        const SizedBox(height: 20),

        // ── Category list ────────────────────────────────────────
        Text('Breakdown',
            style: GoogleFonts.syne(
                fontSize: 16, fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface)),
        const SizedBox(height: 12),
        ...cats.asMap().entries.map((entry) {
          final i = entry.key;
          final cat = entry.value;
          final color = _colorFor(cat.key);
          final pct = _totalSpent > 0 ? cat.value / _totalSpent : 0.0;
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: i == 0
                    ? color.withValues(alpha: 0.4)
                    : Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(
                    width: 42, height: 42,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(_iconForCat(cat.key), size: 20, color: color),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(cat.key,
                      style: GoogleFonts.syne(
                          fontWeight: FontWeight.w600, fontSize: 15,
                          color: Theme.of(context).colorScheme.onSurface))),
                  if (i == 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('Top',
                          style: TextStyle(fontSize: 11, color: color,
                              fontWeight: FontWeight.w700)),
                    ),
                  const SizedBox(width: 8),
                  Text(
                    '${_live.currency} ${cat.value.toStringAsFixed(0)}',
                    style: GoogleFonts.syne(
                        fontWeight: FontWeight.w700, fontSize: 14,
                        color: color),
                  ),
                ]),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      value: pct, minHeight: 6,
                      backgroundColor: Theme.of(context).colorScheme.outline
                          .withValues(alpha: 0.12),
                      valueColor: AlwaysStoppedAnimation(color),
                    ),
                  )),
                  const SizedBox(width: 10),
                  Text('${(pct * 100).toInt()}%',
                      style: TextStyle(fontSize: 12,
                          fontWeight: FontWeight.w600, color: color)),
                ]),
              ],
            ),
          );
        }),
      ],
    );
  }

  // ── Donut chart (shared) ───────────────────────────────────────────────────
  Widget _buildDonut(BuildContext context, {required bool mini}) {
    final cats = _byCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final sections = cats.asMap().entries.map((entry) {
      final i = entry.key;
      final cat = entry.value;
      final color = _colorFor(cat.key);
      final pct = _totalSpent > 0 ? cat.value / _totalSpent : 0.0;
      final isTouched = _touchedPieIndex == i;

      return PieChartSectionData(
        color: color,
        value: cat.value,
        radius: mini
            ? (isTouched ? 52 : 44)
            : (isTouched ? 80 : 68),
        title: pct > 0.05 ? '${(pct * 100).toInt()}%' : '',
        titleStyle: TextStyle(
          fontSize: isTouched ? 14 : 11,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
        badgeWidget: isTouched && !mini
            ? Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(color: color.withValues(alpha: 0.4),
                        blurRadius: 8, offset: const Offset(0, 3))
                  ],
                ),
                child: Text(
                  '${cat.key}\n${_live.currency} ${cat.value.toStringAsFixed(0)}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700),
                ),
              )
            : null,
        badgePositionPercentageOffset: 1.3,
      );
    }).toList();

    return Row(
      children: [
        Expanded(
          flex: 3,
          child: PieChart(
            PieChartData(
              sections: sections,
              centerSpaceRadius: mini ? 38 : 52,
              sectionsSpace: 3,
              pieTouchData: PieTouchData(
                touchCallback: (event, response) {
                  setState(() {
                    if (!event.isInterestedForInteractions ||
                        response?.touchedSection == null) {
                      _touchedPieIndex = -1;
                    } else {
                      _touchedPieIndex =
                          response!.touchedSection!.touchedSectionIndex;
                    }
                  });
                },
              ),
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...cats.take(mini ? 4 : cats.length).map((cat) {
                final color = _colorFor(cat.key);
                final pct =
                    _totalSpent > 0 ? cat.value / _totalSpent : 0.0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(children: [
                    Container(
                      width: 10, height: 10,
                      decoration: BoxDecoration(
                          color: color, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 7),
                    Expanded(child: Text(cat.key,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12,
                            color: Theme.of(context).colorScheme.onSurface
                                .withValues(alpha: 0.75)))),
                    Text('${(pct * 100).toInt()}%',
                        style: TextStyle(fontSize: 11,
                            fontWeight: FontWeight.w700, color: color)),
                  ]),
                );
              }),
              if (mini && cats.length > 4)
                Text('+${cats.length - 4} more',
                    style: TextStyle(fontSize: 11,
                        color: Theme.of(context).colorScheme.onSurface
                            .withValues(alpha: 0.4))),
            ],
          ),
        ),
      ],
    );
  }

  // ── Shared UI helpers ──────────────────────────────────────────────────────
  Widget _card(BuildContext context, {required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.25),
        ),
      ),
      child: child,
    );
  }

  Widget _iconBox(BuildContext context, IconData icon, Color color) {
    return Container(
      width: 44, height: 44,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.7), color],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Icon(icon, color: Colors.white, size: 22),
    );
  }

  Widget _statChip(BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(fontSize: 11,
                      color: Theme.of(context).colorScheme.onSurface
                          .withValues(alpha: 0.45))),
              const SizedBox(height: 2),
              Text(value,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13,
                      fontWeight: FontWeight.w700, color: color)),
            ],
          )),
        ]),
      ),
    );
  }

  IconData _iconForCat(String cat) {
    const icons = {
      'Food': Icons.restaurant_rounded,
      'Transport': Icons.flight_rounded,
      'Accommodation': Icons.hotel_rounded,
      'Shopping': Icons.shopping_bag_rounded,
      'Activities': Icons.attractions_rounded,
    };
    return icons[cat] ?? Icons.category_rounded;
  }
}

extension on MapEntry<String, double> {
  double get toY => value;
}