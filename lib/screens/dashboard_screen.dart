import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import '../models/transaction.dart';
import '../models/category.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<TransactionModel> _transactions = [];
  List<CategoryModel> _categories = [];

  bool _isLoading = true;

  final Color brown = const Color(0xFF854C30);
  final Color darkBrown = const Color(0xFF4A3025);
  final Color background = const Color(0xFFFFF5EC);
  final Color lightBrown = const Color(0xFFF4E0D8);

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    try {
      final transactions = await DatabaseHelper.instance.getTransactions();
      final categories = await DatabaseHelper.instance.getCategories();

      if (!mounted) return;

      setState(() {
        _transactions = transactions;
        _categories = categories;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not load dashboard: $e')));
    }
  }

  double get _totalIncome {
    return _transactions
        .where((t) => t.type == 'Income')
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double get _totalExpenses {
    return _transactions
        .where((t) => t.type == 'Expense')
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double get _balance => _totalIncome - _totalExpenses;

  String _categoryName(int categoryId) {
    final matches = _categories.where((category) => category.id == categoryId);

    if (matches.isEmpty) return 'Other';
    return matches.first.name;
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  Widget _summaryCard({
    required String title,
    required double amount,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.12),
              child: Icon(icon, color: color),
            ),
            const SizedBox(height: 12),
            Text(title, style: TextStyle(color: darkBrown, fontSize: 13)),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                'Rs ${amount.toStringAsFixed(2)}',
                style: TextStyle(
                  color: color,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentTransaction(TransactionModel transaction) {
    final isIncome = transaction.type == 'Income';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: lightBrown,
            child: Icon(
              isIncome ? Icons.arrow_downward : Icons.arrow_upward,
              color: brown,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.title,
                  style: TextStyle(
                    color: darkBrown,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_categoryName(transaction.categoryId)} • ${_formatDate(transaction.date)}',
                  style: TextStyle(color: Colors.brown.shade400, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            '${isIncome ? '+' : '-'} Rs ${transaction.amount.toStringAsFixed(2)}',
            style: TextStyle(
              color: isIncome ? Colors.green.shade700 : Colors.red.shade700,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        elevation: 0,
        title: Text(
          'SpendWise',
          style: TextStyle(
            color: darkBrown,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _loadDashboard,
            icon: Icon(Icons.refresh, color: brown),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: brown))
          : RefreshIndicator(
              onRefresh: _loadDashboard,
              color: brown,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    'Your Financial Overview',
                    style: TextStyle(
                      color: darkBrown,
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Keep track of your money with ease.',
                    style: TextStyle(color: Colors.brown.shade400),
                  ),
                  const SizedBox(height: 22),

                  // Balance card
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: brown,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Available Balance',
                          style: TextStyle(color: Colors.white70, fontSize: 15),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Rs ${_balance.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Income and expense cards
                  Row(
                    children: [
                      _summaryCard(
                        title: 'Total Income',
                        amount: _totalIncome,
                        icon: Icons.trending_up,
                        color: Colors.green.shade700,
                      ),
                      const SizedBox(width: 12),
                      _summaryCard(
                        title: 'Total Expenses',
                        amount: _totalExpenses,
                        icon: Icons.trending_down,
                        color: Colors.red.shade700,
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Recent Transactions',
                        style: TextStyle(
                          color: darkBrown,
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${_transactions.length} total',
                        style: TextStyle(
                          color: Colors.brown.shade400,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  if (_transactions.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(25),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.receipt_long,
                            size: 45,
                            color: brown.withValues(alpha: 0.6),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'No transactions yet',
                            style: TextStyle(
                              color: darkBrown,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'Your recent transactions will appear here.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.brown.shade400),
                          ),
                        ],
                      ),
                    )
                  else
                    ..._transactions.take(5).map(_buildRecentTransaction),
                ],
              ),
            ),
    );
  }
}
