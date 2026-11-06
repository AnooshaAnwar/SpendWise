import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

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

  final List<Color> _chartColors = [
    const Color(0xFF854C30),
    const Color(0xFFB17A56),
    const Color(0xFFD6A783),
    const Color(0xFF684333),
    const Color(0xFFE0C3A5),
    const Color(0xFF9C7056),
    const Color(0xFFC49A7A),
    const Color(0xFF553729),
  ];

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
      final categories = await DatabaseHelper.instance.getCategories();

      final budgets = await DatabaseHelper.instance.getBudgetsForMonth(
        _monthKey,
      );

      final transactions = await DatabaseHelper.instance.getTransactions();

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

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error loading budgets: $e')));
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
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return '${months[_selectedMonth.month - 1]} ${_selectedMonth.year}';
  }

  double _totalIncome() {
    return _transactions
        .where(
          (t) =>
              t.type == 'Income' &&
              t.date.year == _selectedMonth.year &&
              t.date.month == _selectedMonth.month,
        )
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double _totalExpenses() {
    return _transactions
        .where(
          (t) =>
              t.type == 'Expense' &&
              t.date.year == _selectedMonth.year &&
              t.date.month == _selectedMonth.month,
        )
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double _spentForCategory(int categoryId) {
    return _transactions
        .where(
          (t) =>
              t.type == 'Expense' &&
              t.categoryId == categoryId &&
              t.date.year == _selectedMonth.year &&
              t.date.month == _selectedMonth.month,
        )
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  // Donut chart for monthly category spending.
  Widget _spendingChart(List<CategoryModel> expenseCategories) {
    final spendingData = expenseCategories
        .where((category) => category.id != null)
        .map(
          (category) =>
              MapEntry(category.name, _spentForCategory(category.id!)),
        )
        .where((entry) => entry.value > 0)
        .toList();

    spendingData.sort((a, b) => b.value.compareTo(a.value));

    if (spendingData.isEmpty) {
      return Card(
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(25),
          child: Column(
            children: [
              Icon(
                Icons.pie_chart_outline,
                size: 55,
                color: Colors.brown.shade300,
              ),
              const SizedBox(height: 12),
              const Text(
                'No expenses to display yet.',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    final totalSpending = spendingData.fold(
      0.0,
      (sum, entry) => sum + entry.value,
    );

    final sections = spendingData.asMap().entries.map((item) {
      final index = item.key;
      final entry = item.value;

      final percentage = (entry.value / totalSpending) * 100;

      return PieChartSectionData(
        value: entry.value,
        color: _chartColors[index % _chartColors.length],
        radius: 55,
        title: '${percentage.toStringAsFixed(0)}%',
        titleStyle: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      );
    }).toList();

    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Expense Breakdown',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4A3025),
                ),
              ),
            ),

            const SizedBox(height: 15),

            SizedBox(
              height: 220,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  PieChart(
                    PieChartData(
                      sections: sections,
                      centerSpaceRadius: 48,
                      sectionsSpace: 3,
                      startDegreeOffset: -90,
                      pieTouchData: PieTouchData(enabled: false),
                    ),
                  ),

                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Total Spent',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Rs. ${totalSpending.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4A3025),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 15),

            const Divider(),

            const SizedBox(height: 10),

            ...spendingData.asMap().entries.map((item) {
              final index = item.key;
              final entry = item.value;

              final percentage = (entry.value / totalSpending) * 100;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Container(
                      width: 13,
                      height: 13,
                      decoration: BoxDecoration(
                        color: _chartColors[index % _chartColors.length],
                        shape: BoxShape.circle,
                      ),
                    ),

                    const SizedBox(width: 10),

                    Expanded(
                      child: Text(
                        entry.key,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),

                    Text(
                      '${percentage.toStringAsFixed(1)}%',
                      style: const TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(width: 12),

                    Text(
                      'Rs. ${entry.value.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4A3025),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Future<void> _setBudget(CategoryModel category) async {
    final existing = _budgets.where((b) => b.categoryId == category.id);

    final initialAmount = existing.isNotEmpty ? existing.first.amount : null;

    final amount = await showDialog<double>(
      context: context,
      builder: (dialogContext) {
        return BudgetAmountDialog(
          categoryName: category.name,
          initialAmount: initialAmount,
        );
      },
    );

    if (amount == null || category.id == null || !mounted) return;

    try {
      await DatabaseHelper.instance.saveBudget(
        BudgetModel(categoryId: category.id!, month: _monthKey, amount: amount),
      );

      await _loadData();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Budget saved successfully!')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Could not save budget: $e')));
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

    final expenseCategories = _categories
        .where((c) => c.type == 'Expense')
        .toList();

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
                    'Spending by Category',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 10),

                  _spendingChart(expenseCategories),

                  const SizedBox(height: 20),

                  const Text(
                    'Category Budgets',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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

                            Text('Budget: Rs. ${budget.toStringAsFixed(2)}'),

                            const SizedBox(height: 6),

                            Text('Spent: Rs. ${spent.toStringAsFixed(2)}'),

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

class BudgetAmountDialog extends StatefulWidget {
  final String categoryName;
  final double? initialAmount;

  const BudgetAmountDialog({
    super.key,
    required this.categoryName,
    this.initialAmount,
  });

  @override
  State<BudgetAmountDialog> createState() => _BudgetAmountDialogState();
}

class _BudgetAmountDialogState extends State<BudgetAmountDialog> {
  late final TextEditingController _controller;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();

    _controller = TextEditingController(
      text: widget.initialAmount?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _saveBudget() {
    if (_formKey.currentState!.validate()) {
      final amount = double.parse(_controller.text.trim());
      Navigator.pop(context, amount);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('${widget.categoryName} Budget'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Monthly budget',
            prefixText: 'Rs. ',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            final number = double.tryParse(value ?? '');

            if (number == null || !number.isFinite || number <= 0) {
              return 'Enter an amount greater than zero';
            }

            return null;
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(onPressed: _saveBudget, child: const Text('Save')),
      ],
    );
  }
}
