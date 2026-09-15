import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:tour_buddy/screens/past_trips_screen.dart';
import '../providers/trip_provider.dart';
import '../models/trip.dart';
import '../models/expense.dart';
import '../models/expense_category.dart';
import '../services/currency_service.dart';
import 'settings_screen.dart';
import 'start_screen.dart';

enum ExpenseSortOption {
  dateDesc,
  dateAsc,
  amountDesc,
  amountAsc,
  categoryAsc,
}

class ExpenseScreen extends StatefulWidget {
  final Trip trip;

  const ExpenseScreen({super.key, required this.trip});

  @override
  State<ExpenseScreen> createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends State<ExpenseScreen> {
  ExpenseSortOption _currentSortOption = ExpenseSortOption.dateDesc;
  late TextEditingController _notesController;
  bool _isNotesInitialized = false;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController(text: widget.trip.notes ?? '');
  }

  @override
  void dispose() {
    _notesController.dispose();
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

    if (!_isNotesInitialized && currentTrip.notes != null) {
      _notesController.text = currentTrip.notes!;
      _isNotesInitialized = true;
    }

    final double totalExpense =
        currentTrip.expenses.fold(0.0, (sum, item) => sum + item.amount);
    final List<Expense> sortedExpenses = _getSortedExpenses(currentTrip.expenses);
    final bool isOverBudget =
        currentTrip.budget > 0 && totalExpense > currentTrip.budget;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(currentTrip.name),
          bottom: const TabBar(
            tabs: [
              Tab(
                icon: Icon(Icons.receipt_long_outlined),
                text: 'Expenses',
              ),
              Tab(
                icon: Icon(Icons.event_note_outlined),
                text: 'Itinerary & Notes',
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.analytics_outlined),
              tooltip: 'Insights',
              onPressed: () => _showTripInsightsSheet(context, currentTrip),
            ),
            PopupMenuButton<ExpenseSortOption>(
              icon: const Icon(Icons.sort_rounded),
              tooltip: 'Sort Expenses',
              onSelected: (ExpenseSortOption result) {
                setState(() {
                  _currentSortOption = result;
                });
              },
              itemBuilder: (BuildContext context) => [
                const PopupMenuItem(
                  value: ExpenseSortOption.dateDesc,
                  child: Text('Newest first'),
                ),
                const PopupMenuItem(
                  value: ExpenseSortOption.dateAsc,
                  child: Text('Oldest first'),
                ),
                const PopupMenuItem(
                  value: ExpenseSortOption.amountDesc,
                  child: Text('Highest amount'),
                ),
                const PopupMenuItem(
                  value: ExpenseSortOption.amountAsc,
                  child: Text('Lowest amount'),
                ),
                const PopupMenuItem(
                  value: ExpenseSortOption.categoryAsc,
                  child: Text('By category'),
                ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.share_outlined),
              tooltip: 'Share',
              onPressed: () => _shareTrip(context, currentTrip),
            ),
            IconButton(
              icon: const Icon(Icons.tune_rounded),
              tooltip: 'Trip Settings',
              onPressed: () => _showTripSettingsSheet(context, currentTrip),
            ),
          ],
        ),
        drawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: <Widget>[
              DrawerHeader(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const Text(
                      'Tour Buddy',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      currentTrip.name,
                      style: const TextStyle(color: Colors.white70, fontSize: 15),
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
                leading: const Icon(Icons.history_rounded),
                title: const Text('Past Trips'),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const PastTripsScreen()),
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
                leading:
                    const Icon(Icons.delete_sweep_outlined, color: Colors.redAccent),
                title: const Text(
                  'Reset Trip Expenses',
                  style: TextStyle(color: Colors.redAccent),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  _showResetConfirmationDialog(
                      context, tripProvider, currentTrip);
                },
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // TAB 1: Expenses View
            Column(
              children: [
                // Budget Summary Card
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total Spent',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (currentTrip.budget > 0)
                            Text(
                              'Budget: ${currentTrip.currency} ${currentTrip.budget.toStringAsFixed(2)}',
                              style: TextStyle(
                                  fontSize: 13, color: Colors.grey[600]),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${currentTrip.currency} ${totalExpense.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (currentTrip.budget > 0) ...[
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: (totalExpense /
                                    currentTrip.budget
                                        .clamp(0.01, double.infinity))
                                .clamp(0.0, 1.0),
                            minHeight: 6,
                            backgroundColor: Colors.grey[200],
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isOverBudget ? Colors.redAccent : Colors.teal,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isOverBudget
                              ? 'Over budget by ${currentTrip.currency} ${(totalExpense - currentTrip.budget).toStringAsFixed(2)}'
                              : '${currentTrip.currency} ${(currentTrip.budget - totalExpense).toStringAsFixed(2)} remaining',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isOverBudget
                                ? Colors.redAccent
                                : Colors.teal[700],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Expenses List Header
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Expenses (${sortedExpenses.length})',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (sortedExpenses.isNotEmpty)
                        Text(
                          'Swipe to delete • Tap to edit',
                          style:
                              TextStyle(fontSize: 12, color: Colors.grey[500]),
                        ),
                    ],
                  ),
                ),

                // Expenses List
                Expanded(
                  child: sortedExpenses.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.receipt_long_outlined,
                                  size: 56, color: Colors.grey[350]),
                              const SizedBox(height: 12),
                              Text(
                                'No expenses logged yet.',
                                style: TextStyle(
                                    fontSize: 16, color: Colors.grey[600]),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Tap below to add your first expense.',
                                style: TextStyle(
                                    fontSize: 13, color: Colors.grey[500]),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: sortedExpenses.length,
                          padding: const EdgeInsets.only(bottom: 80),
                          itemBuilder: (context, index) {
                            final expense = sortedExpenses[index];
                            final categoryInfo =
                                ExpenseCategory.getCategory(expense.category);

                            return Dismissible(
                              key: Key(expense.id),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 24),
                                color: Colors.redAccent,
                                child: const Icon(Icons.delete_outline,
                                    color: Colors.white, size: 24),
                              ),
                              confirmDismiss: (direction) async => true,
                              onDismissed: (_) {
                                tripProvider.deleteExpenseFromCurrentTrip(
                                    currentTrip, expense.id);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content:
                                        Text('Removed "${expense.title}"'),
                                    action: SnackBarAction(
                                      label: 'Undo',
                                      onPressed: () {
                                        tripProvider.addExpenseToCurrentTrip(
                                            currentTrip, expense);
                                      },
                                    ),
                                  ),
                                );
                              },
                              child: InkWell(
                                onTap: () {
                                  _showAddOrEditExpenseSheet(
                                    context,
                                    tripProvider,
                                    currentTrip,
                                    existingExpense: expense,
                                  );
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 6),
                                  child: Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).cardColor,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color:
                                            Colors.grey.withValues(alpha: 0.12),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 44,
                                          height: 44,
                                          decoration: BoxDecoration(
                                            color: categoryInfo.color
                                                .withValues(alpha: 0.12),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Icon(
                                            categoryInfo.icon,
                                            color: categoryInfo.color,
                                            size: 22,
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                expense.title,
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 3),
                                              Text(
                                                '${DateFormat('MMM d, h:mm a').format(expense.date)} • ${expense.category}',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              '${currentTrip.currency} ${expense.amount.toStringAsFixed(2)}',
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            if (expense.foreignAmount != null &&
                                                expense.foreignCurrency !=
                                                    null &&
                                                expense.foreignCurrency !=
                                                    currentTrip.currency)
                                              Text(
                                                '${expense.foreignCurrency} ${expense.foreignAmount!.toStringAsFixed(2)}',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.grey[500],
                                                ),
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),

            // TAB 2: Itinerary & Notes View
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.grey.withValues(alpha: 0.12),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline,
                            color: Colors.blue, size: 22),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Save your travel notes, flight numbers, hotel details, and day-by-day plans here.',
                            style: TextStyle(
                                fontSize: 13, color: Colors.grey[700]),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Quick Template Insert Pills
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        ActionChip(
                          avatar: const Icon(Icons.hotel_outlined, size: 16),
                          label: const Text('Hotel'),
                          onPressed: () {
                            _appendNoteTemplate('\n🏨 Hotel / Stay:\n- Name:\n- Address:\n- Check-in:\n');
                          },
                        ),
                        const SizedBox(width: 8),
                        ActionChip(
                          avatar: const Icon(Icons.flight_outlined, size: 16),
                          label: const Text('Flight'),
                          onPressed: () {
                            _appendNoteTemplate('\n✈️ Flight / Transit:\n- Flight #:\n- Departure:\n- Arrival:\n');
                          },
                        ),
                        const SizedBox(width: 8),
                        ActionChip(
                          avatar: const Icon(Icons.today_outlined, size: 16),
                          label: const Text('Day Plan'),
                          onPressed: () {
                            _appendNoteTemplate('\n📅 Day 1:\n- Morning:\n- Afternoon:\n- Evening:\n');
                          },
                        ),
                        const SizedBox(width: 8),
                        ActionChip(
                          avatar: const Icon(Icons.checklist_outlined, size: 16),
                          label: const Text('Packing List'),
                          onPressed: () {
                            _appendNoteTemplate('\n🎒 Packing List:\n- Passport / NID\n- Charger\n- Medication\n');
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: TextField(
                      controller: _notesController,
                      maxLines: null,
                      expands: true,
                      textAlignVertical: TextAlignVertical.top,
                      decoration: InputDecoration(
                        hintText: 'Type your itinerary, reminders, or notes here...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        alignLabelWithHint: true,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () async {
                      await tripProvider.updateTripNotes(
                          currentTrip, _notesController.text);
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Itinerary & Notes saved.')),
                      );
                    },
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('Save Notes'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            _showAddOrEditExpenseSheet(context, tripProvider, currentTrip);
          },
          icon: const Icon(Icons.add),
          label: const Text("Add Expense"),
        ),
      ),
    );
  }

  void _appendNoteTemplate(String text) {
    final current = _notesController.text;
    _notesController.text = current.isEmpty ? text.trimLeft() : '$current$text';
  }

  // --- Modal Bottom Sheet: Add / Edit Expense ---
  void _showAddOrEditExpenseSheet(
    BuildContext context,
    TripProvider tripProvider,
    Trip trip, {
    Expense? existingExpense,
  }) {
    final bool isEditing = existingExpense != null;
    final titleController =
        TextEditingController(text: isEditing ? existingExpense.title : '');
    final amountController = TextEditingController(
        text: isEditing ? existingExpense.amount.toStringAsFixed(2) : '');
    final foreignController = TextEditingController(
        text: isEditing && existingExpense.foreignAmount != null
            ? existingExpense.foreignAmount!.toStringAsFixed(2)
            : '');

    String selectedCategory = isEditing
        ? existingExpense.category
        : ExpenseCategory.defaultCategories.first.name;
    String foreignCurrency = isEditing && existingExpense.foreignCurrency != null
        ? existingExpense.foreignCurrency!
        : 'USD';
    bool showCurrencyConverter = isEditing && existingExpense.foreignAmount != null;

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
                    Text(
                      isEditing ? 'Edit Expense' : 'Add Expense',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Title Input
                    TextField(
                      controller: titleController,
                      autofocus: !isEditing,
                      decoration: InputDecoration(
                        labelText: 'Expense Title',
                        hintText: 'e.g. Dinner, Taxi to Hotel',
                        prefixIcon: const Icon(Icons.edit_note_outlined),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Amount Input
                    TextField(
                      controller: amountController,
                      decoration: InputDecoration(
                        labelText: 'Amount (${trip.currency})',
                        prefixIcon: const Icon(Icons.payments_outlined),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                    ),
                    const SizedBox(height: 16),

                    // Category Selector Chips
                    const Text(
                      'Category',
                      style:
                          TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: ExpenseCategory.defaultCategories.map((cat) {
                          final isSelected = selectedCategory == cat.name;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(cat.icon,
                                      size: 16,
                                      color: isSelected
                                          ? Colors.white
                                          : cat.color),
                                  const SizedBox(width: 6),
                                  Text(cat.name),
                                ],
                              ),
                              selected: isSelected,
                              selectedColor: cat.color,
                              labelStyle: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.color,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                              onSelected: (_) {
                                setSheetState(() {
                                  selectedCategory = cat.name;
                                });
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Currency Conversion Toggle
                    InkWell(
                      onTap: () {
                        setSheetState(() {
                          showCurrencyConverter = !showCurrencyConverter;
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            Icon(
                              showCurrencyConverter
                                  ? Icons.keyboard_arrow_down
                                  : Icons.keyboard_arrow_right,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Convert from foreign currency',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    if (showCurrencyConverter) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: foreignController,
                              decoration: InputDecoration(
                                labelText: 'Foreign Amount',
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade400),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: foreignCurrency,
                                onChanged: (val) {
                                  if (val != null) {
                                    setSheetState(() {
                                      foreignCurrency = val;
                                    });
                                  }
                                },
                                items: ['USD', 'EUR', 'GBP', 'INR', 'BDT']
                                    .map((c) => DropdownMenuItem(
                                          value: c,
                                          child: Text(c),
                                        ))
                                    .toList(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Submit Button
                    ElevatedButton(
                      onPressed: () async {
                        final title = titleController.text.trim();
                        final amount = double.tryParse(amountController.text);
                        final foreignAmount =
                            double.tryParse(foreignController.text);

                        if (title.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Please enter an expense title.')),
                          );
                          return;
                        }

                        if (amount == null && foreignAmount == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Please enter an amount.')),
                          );
                          return;
                        }

                        double finalAmount = amount ?? 0.0;
                        if (foreignAmount != null &&
                            foreignCurrency != trip.currency) {
                          try {
                            final converted = await CurrencyService()
                                .convertCurrency(foreignAmount, foreignCurrency,
                                    trip.currency);
                            finalAmount += converted;
                          } catch (e) {
                            debugPrint('Currency conversion failed: $e');
                          }
                        } else if (foreignAmount != null &&
                            foreignCurrency == trip.currency) {
                          finalAmount += foreignAmount;
                        }

                        if (isEditing) {
                          final updated = existingExpense.copyWith(
                            title: title,
                            amount: finalAmount,
                            category: selectedCategory,
                            foreignAmount: foreignAmount,
                            foreignCurrency: foreignAmount != null
                                ? foreignCurrency
                                : null,
                          );
                          await tripProvider.updateExpenseInCurrentTrip(
                              trip, updated);
                        } else {
                          final newExpense = Expense(
                            id: const Uuid().v4(),
                            title: title,
                            amount: finalAmount,
                            category: selectedCategory,
                            date: DateTime.now(),
                            foreignAmount: foreignAmount,
                            foreignCurrency: foreignAmount != null
                                ? foreignCurrency
                                : null,
                          );
                          await tripProvider.addExpenseToCurrentTrip(
                              trip, newExpense);
                        }

                        if (!sheetContext.mounted) return;
                        Navigator.of(sheetContext).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text(
                        isEditing ? 'Save Changes' : 'Add Expense',
                        style: const TextStyle(fontSize: 16),
                      ),
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

  // --- Modal Bottom Sheet: Trip Settings ---
  void _showTripSettingsSheet(BuildContext context, Trip trip) {
    final tripProvider = Provider.of<TripProvider>(context, listen: false);
    final budgetController =
        TextEditingController(text: trip.budget.toStringAsFixed(2));
    String selectedCurrency = trip.currency;
    DateTime startDate = trip.startDate;
    DateTime endDate = trip.endDate;

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
                    Text(
                      'Trip Settings - ${trip.name}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Budget
                    TextField(
                      controller: budgetController,
                      decoration: InputDecoration(
                        labelText: 'Trip Budget',
                        prefixIcon:
                            const Icon(Icons.account_balance_wallet_outlined),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                    ),
                    const SizedBox(height: 14),

                    // Currency Dropdown
                    DropdownButtonFormField<String>(
                      initialValue: selectedCurrency,
                      decoration: InputDecoration(
                        labelText: 'Trip Currency',
                        prefixIcon: const Icon(Icons.currency_exchange),
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
                          .map(
                              (c) => DropdownMenuItem(value: c, child: Text(c)))
                          .toList(),
                    ),
                    const SizedBox(height: 16),

                    // Date Range Tile
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
                            const Icon(Icons.date_range_outlined),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Trip Dates',
                                      style: TextStyle(
                                          fontSize: 12, color: Colors.grey)),
                                  Text(
                                    '${DateFormat('MMM d, yyyy').format(startDate)} - ${DateFormat('MMM d, yyyy').format(endDate)}',
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

                    ElevatedButton(
                      onPressed: () async {
                        await tripProvider.updateCurrentTrip(
                          trip: trip,
                          budget: double.tryParse(budgetController.text),
                          currency: selectedCurrency,
                          startDate: startDate,
                          endDate: endDate,
                        );
                        if (!sheetContext.mounted) return;
                        Navigator.of(sheetContext).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('Save Settings',
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

  // --- Modal Bottom Sheet: Trip Insights ---
  void _showTripInsightsSheet(BuildContext context, Trip trip) {
    final double totalExpense =
        trip.expenses.fold(0.0, (sum, item) => sum + item.amount);
    final int tripDays = trip.endDate.difference(trip.startDate).inDays + 1;
    final double dailyAvg = tripDays > 0 ? totalExpense / tripDays : totalExpense;

    Map<String, double> categoryTotals = {};
    for (var expense in trip.expenses) {
      categoryTotals.update(
        expense.category,
        (val) => val + expense.amount,
        ifAbsent: () => expense.amount,
      );
    }
    final sortedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
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
                'Trip Insights',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // Metrics Row
              Row(
                children: [
                  Expanded(
                    child: _buildMetricTile(
                      'Total Spent',
                      '${trip.currency} ${totalExpense.toStringAsFixed(0)}',
                      Icons.payments_outlined,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildMetricTile(
                      'Daily Average',
                      '${trip.currency} ${dailyAvg.toStringAsFixed(0)}',
                      Icons.calendar_today_outlined,
                      Colors.teal,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              if (trip.budget > 0) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (totalExpense > trip.budget
                            ? Colors.red
                            : Colors.green)
                        .withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        totalExpense > trip.budget
                            ? Icons.warning_amber_rounded
                            : Icons.check_circle_outline,
                        color: totalExpense > trip.budget
                            ? Colors.red
                            : Colors.green[700],
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          totalExpense > trip.budget
                              ? 'Over budget by ${trip.currency} ${(totalExpense - trip.budget).toStringAsFixed(2)}.'
                              : '${trip.currency} ${(trip.budget - totalExpense).toStringAsFixed(2)} under your allocated budget.',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: totalExpense > trip.budget
                                ? Colors.red[800]
                                : Colors.green[800],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              const Text(
                'Category Breakdown',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),

              if (sortedCategories.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'No expenses recorded yet.',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              else
                ...sortedCategories.map((entry) {
                  final catInfo = ExpenseCategory.getCategory(entry.key);
                  final pct =
                      totalExpense > 0 ? (entry.value / totalExpense) : 0.0;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(catInfo.icon, size: 16, color: catInfo.color),
                            const SizedBox(width: 8),
                            Text(catInfo.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w500)),
                            const Spacer(),
                            Text(
                              '${trip.currency} ${entry.value.toStringAsFixed(2)} (${(pct * 100).toStringAsFixed(1)}%)',
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[700]),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: pct,
                            minHeight: 6,
                            backgroundColor: Colors.grey[200],
                            valueColor:
                                AlwaysStoppedAnimation<Color>(catInfo.color),
                          ),
                        ),
                      ],
                    ),
                  );
                }),

              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMetricTile(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
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

  void _shareTrip(BuildContext context, Trip trip) {
    String summary = "Tour Buddy: ${trip.name}\n";
    summary += "Destination: ${trip.destination}\n";
    summary +=
        "Dates: ${DateFormat('MMM d, yyyy').format(trip.startDate)} - ${DateFormat('MMM d, yyyy').format(trip.endDate)}\n";
    summary +=
        "Budget: ${trip.currency} ${trip.budget.toStringAsFixed(2)}\n\n";

    double total = trip.expenses.fold(0.0, (sum, item) => sum + item.amount);
    summary +=
        "Total Expenses: ${trip.currency} ${total.toStringAsFixed(2)}\n\n";

    if (trip.expenses.isNotEmpty) {
      summary += "Expenses Breakdown:\n";
      for (var expense in trip.expenses) {
        summary +=
            "- ${expense.title} (${expense.category}): ${trip.currency} ${expense.amount.toStringAsFixed(2)}\n";
      }
    } else {
      summary += "No expenses recorded yet.\n";
    }

    if (trip.notes != null && trip.notes!.isNotEmpty) {
      summary += "\nItinerary & Notes:\n${trip.notes}\n";
    }

    Share.share(summary, subject: 'Trip Summary: ${trip.name}');
  }
}
