
import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import '../models/budget.dart';
import '../models/category.dart';
import '../models/transaction.dart';

class BudgetsScreen extends StatefulWidget {
  const BudgetsScreen({super.key});

  @override
  State<BudgetsScreen> createState() => _BudgetsScreenState();
}

class _BudgetsScreenState extends State<BudgetsScreen> {
  DateTime _selectedMonth = DateTime.now();

  List<CategoryModel> _categories = [];
  List<BudgetModel> _budgets = [];
  List<TransactionModel> _transactions = [];

  bool _isLoading = true;

  String get _monthKey =>
      '${_selectedMonth.year}-'
      '${_selectedMonth.month.toString().padLeft(2, '0')}';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final categories =
          await DatabaseHelper.instance.getCategories();

      final budgets =
          await DatabaseHelper.instance.getBudgetsForMonth(_monthKey);

      final transactions =
          await DatabaseHelper.instance.getTransactions();

      if (!mounted) return;

      setState(() {
        _categories = categories;
        _budgets = budgets;
        _transactions = transactions;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading budgets: $e')),
      );
    }
  }

  Future<void> _changeMonth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDatePickerMode: DatePickerMode.year,
    );

    if (picked != null) {
      setState(() {
        _selectedMonth = DateTime(picked.year, picked.month);
        _isLoading = true;
      });

      await _loadData();
    }
  }

  String _monthName() {
    const months = [
      'January', 'February', 'March', 'April',
      'May', 'June', 'July', 'August',
      'September', 'October', 'November', 'December'
    ];

    return '${months[_selectedMonth.month - 1]} ${_selectedMonth.year}';
  }

  double _totalIncome() {
    return _transactions
        .where((t) =>
            t.type == 'Income' &&
            t.date.year == _selectedMonth.year &&
            t.date.month == _selectedMonth.month)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double _totalExpenses() {
    return _transactions
        .where((t) =>
            t.type == 'Expense' &&
            t.date.year == _selectedMonth.year &&
            t.date.month == _selectedMonth.month)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double _spentForCategory(int categoryId) {
    return _transactions
        .where((t) =>
            t.type == 'Expense' &&
            t.categoryId == categoryId &&
            t.date.year == _selectedMonth.year &&
            t.date.month == _selectedMonth.month)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  Future<void> _setBudget(CategoryModel category) async {
    final controller = TextEditingController();

    final existing = _budgets.where(
      (b) => b.categoryId == category.id,
    );

    if (existing.isNotEmpty) {
      controller.text = existing.first.amount.toString();
    }

    final formKey = GlobalKey<FormState>();

    final amount = await showDialog<double>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('${category.name} Budget'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: controller,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Monthly budget',
                prefixText: 'Rs. ',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                final number = double.tryParse(value ?? '');

                if (number == null ||
                    !number.isFinite ||
                    number <= 0) {
                  return 'Enter an amount greater than zero';
                }

                return null;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(
                    dialogContext,
                    double.parse(controller.text.trim()),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (amount == null || category.id == null) return;

    try {
      await DatabaseHelper.instance.saveBudget(
        BudgetModel(
          categoryId: category.id!,
          month: _monthKey,
          amount: amount,
        ),
      );

      await _loadData();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Budget saved successfully!')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save budget: $e')),
      );
    }
  }

  Widget _summaryCard(String title, double amount) {
    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 8),
            Text(
              'Rs. ${amount.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4A3025),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final income = _totalIncome();
    final expenses = _totalExpenses();
    final balance = income - expenses;

    final expenseCategories =
        _categories.where((c) => c.type == 'Expense').toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Monthly Budgets',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: _changeMonth,
            icon: const Icon(Icons.calendar_month),
            tooltip: 'Select month',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    _monthName(),
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4A3025),
                    ),
                  ),
                  const SizedBox(height: 15),

                  _summaryCard('Total Income', income),
                  _summaryCard('Total Expenses', expenses),
                  _summaryCard('Monthly Balance', balance),

                  const SizedBox(height: 20),

                  const Text(
                    'Category Budgets',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  if (expenseCategories.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('No expense categories available.'),
                      ),
                    ),

                  ...expenseCategories.map((category) {
                    final existing = _budgets.where(
                      (b) => b.categoryId == category.id,
                    );

                    final budget = existing.isNotEmpty
                        ? existing.first.amount
                        : 0.0;

                    final spent = category.id == null
                        ? 0.0
                        : _spentForCategory(category.id!);

                    final remaining = budget - spent;

                    final progress = budget > 0
                        ? (spent / budget).clamp(0.0, 1.0)
                        : 0.0;

                    return Card(
                      color: Colors.white,
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    category.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 17,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => _setBudget(category),
                                  icon: const Icon(Icons.edit),
                                  tooltip: 'Set or edit budget',
                                ),
                              ],
                            ),
                            Text(
                              'Budget: Rs. ${budget.toStringAsFixed(2)}',
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Spent: Rs. ${spent.toStringAsFixed(2)}',
                            ),
                            const SizedBox(height: 6),
                            Text(
                              budget == 0
                                  ? 'Set a budget to track spending'
                                  : remaining >= 0
                                      ? 'Remaining: Rs. ${remaining.toStringAsFixed(2)}'
                                      : 'Over budget by: Rs. ${(-remaining).toStringAsFixed(2)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: budget == 0
                                    ? Colors.grey
                                    : remaining < 0
                                        ? Colors.red
                                        : Colors.green,
                              ),
                            ),
                            const SizedBox(height: 10),
                            LinearProgressIndicator(
                              value: progress,
                              minHeight: 8,
                              backgroundColor: Colors.grey.shade200,
                              color: remaining < 0
                                  ? Colors.red
                                  : const Color(0xFF854C30),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
    );
  }
}
