import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ExpenseScreen extends StatefulWidget {
  const ExpenseScreen({super.key});

  @override
  _ExpenseScreenState createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends State<ExpenseScreen> {
  List<Map<String, dynamic>> expenses = [];
  String title = 'Expenses';
  final TextEditingController _expenseTitleController = TextEditingController();
  final TextEditingController _expenseAmountController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    loadExpenses();
    loadTitle();
  }

  void loadExpenses() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedExpenses = prefs.getString('expenses');
    if (savedExpenses != null) {
      List<dynamic> decodedExpenses = json.decode(savedExpenses);
      expenses = List<Map<String, dynamic>>.from(decodedExpenses);
      setState(() {});
    }
  }

  void saveExpenses() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('expenses', json.encode(expenses));
  }

  void addExpense(String title, double amount) {
    var now = DateTime.now();
    expenses.add({
      'title': title,
      'amount': amount,
      'date': "${now.year}-${now.month}-${now.day} ${now.hour}:${now.minute}",
    });

    saveExpenses();
    setState(() {});
  }

  void resetExpenses() {
    expenses.clear();
    saveExpenses();
    setState(() {});
  }

  void loadTitle() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedTitle = prefs.getString('title');
    if (savedTitle != null) {
      setState(() {
        title = savedTitle;
      });
    }
  }

  void saveTitle(String newTitle) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('title', newTitle);
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    double totalExpense = expenses.fold(0, (sum, item) => sum + item['amount']);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Expanded(
              child: TextField(
                controller: TextEditingController(text: title),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Edit Title',
                ),
                onSubmitted: (value) {
                  setState(() {
                    title = value.isNotEmpty ? value : title;
                    saveTitle(title);
                  });
                },
              ),
            ),
          ],
        ),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
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
              title: const Text('Reset Data'),
              onTap: () {
                resetExpenses();
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Total: ৳${totalExpense.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 28),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: expenses.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text('${expenses[index]['title']}'),
                  subtitle: Text('${expenses[index]['date']}'),
                  trailing: Text(
                      '৳${expenses[index]['amount'].toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 20)),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () {
                _showAddExpenseDialog();
              },
              child: const Text("Add Expense"),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddExpenseDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Add Expense"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _expenseTitleController,
                decoration: const InputDecoration(labelText: 'Expense Title'),
              ),
              TextField(
                controller: _expenseAmountController,
                decoration: const InputDecoration(labelText: 'Amount (৳)'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                double? amount = double.tryParse(_expenseAmountController.text);
                if (_expenseTitleController.text.isNotEmpty && amount != null) {
                  addExpense(_expenseTitleController.text, amount);
                  _expenseTitleController.clear();
                  _expenseAmountController.clear();
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
}
