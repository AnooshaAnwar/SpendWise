import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import '../models/category.dart';
import '../models/transaction.dart';
import 'add_transaction_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<TransactionModel> _transactions = [];
  List<CategoryModel> _categories = [];

  bool _isLoading = true;

  DateTime? _selectedMonth;
  String _selectedCategory = 'all';
  String _selectedType = 'All';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
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

      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error loading history: $e')));
    }
  }

  String _categoryName(int id) {
    final matches = _categories.where((c) => c.id == id);

    return matches.isNotEmpty ? matches.first.name : 'Unknown category';
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  String _monthName(DateTime date) {
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

    return '${months[date.month - 1]} ${date.year}';
  }

  List<TransactionModel> get _filteredTransactions {
    return _transactions.where((transaction) {
      final matchesMonth =
          _selectedMonth == null ||
          (transaction.date.year == _selectedMonth!.year &&
              transaction.date.month == _selectedMonth!.month);

      final matchesCategory =
          _selectedCategory == 'all' ||
          transaction.categoryId.toString() == _selectedCategory;

      final matchesType =
          _selectedType == 'All' || transaction.type == _selectedType;

      final query = _searchQuery.trim().toLowerCase();

      final matchesSearch =
          query.isEmpty ||
          transaction.title.toLowerCase().contains(query) ||
          transaction.note.toLowerCase().contains(query) ||
          _categoryName(transaction.categoryId).toLowerCase().contains(query);

      return matchesMonth && matchesCategory && matchesType && matchesSearch;
    }).toList()..sort((a, b) => b.date.compareTo(a.date));
  }

  double _filteredTotal(String type) {
    return _filteredTransactions
        .where((t) => t.type == type)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  Future<void> _selectMonth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedMonth ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDatePickerMode: DatePickerMode.year,
    );

    if (picked != null && mounted) {
      setState(() {
        _selectedMonth = DateTime(picked.year, picked.month);
      });
    }
  }

  void _clearFilters() {
    setState(() {
      _selectedMonth = null;
      _selectedCategory = 'all';
      _selectedType = 'All';
      _searchQuery = '';
    });
  }

  Future<void> _editTransaction(TransactionModel transaction) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => AddTransactionScreen(transaction: transaction),
      ),
    );

    if (result == true) {
      await _loadHistory();
    }
  }

  Future<void> _deleteTransaction(TransactionModel transaction) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Transaction?'),
          content: Text(
            'Are you sure you want to delete '
            '"${transaction.title}"?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || transaction.id == null) return;

    try {
      await DatabaseHelper.instance.deleteTransaction(transaction.id!);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transaction deleted successfully!')),
      );

      await _loadHistory();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not delete transaction: $e')),
      );
    }
  }

  Widget _buildTypeFilters() {
    final types = ['All', 'Income', 'Expense'];

    return Row(
      children: types.map((type) {
        final selected = _selectedType == type;

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ChoiceChip(
              label: Text(type),
              selected: selected,
              showCheckmark: false,
              selectedColor: const Color(0xFF854C30),
              backgroundColor: const Color(0xFFF4EAE2),
              labelStyle: TextStyle(
                color: selected ? Colors.white : const Color(0xFF4A3025),
                fontWeight: FontWeight.bold,
              ),
              onSelected: (_) {
                setState(() {
                  _selectedType = type;
                });
              },
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFilters() {
    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filter Transactions',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4A3025),
              ),
            ),

            const SizedBox(height: 12),

            TextField(
              decoration: InputDecoration(
                hintText: 'Search transactions...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: const Color(0xFFFAF7F4),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),

            const SizedBox(height: 14),

            _buildTypeFilters(),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _selectMonth,
                icon: const Icon(Icons.calendar_month),
                label: Text(
                  _selectedMonth == null
                      ? 'All Months'
                      : _monthName(_selectedMonth!),
                ),
              ),
            ),

            const SizedBox(height: 12),

            DropdownButtonFormField<String>(
              initialValue: _selectedCategory,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category),
              ),
              items: [
                const DropdownMenuItem<String>(
                  value: 'all',
                  child: Text('All Categories'),
                ),
                ..._categories.map((category) {
                  return DropdownMenuItem<String>(
                    value: category.id.toString(),
                    child: Text(category.name),
                  );
                }),
              ],
              onChanged: (value) {
                if (value == null) return;

                setState(() {
                  _selectedCategory = value;
                });
              },
            ),

            const SizedBox(height: 8),

            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _clearFilters,
                icon: const Icon(Icons.clear),
                label: const Text('Clear Filters'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummary() {
    final income = _filteredTotal('Income');
    final expenses = _filteredTotal('Expense');
    final balance = income - expenses;

    return Card(
      color: const Color(0xFFF4EAE2),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filtered Summary',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4A3025),
              ),
            ),

            const SizedBox(height: 14),

            _summaryRow('Income', income, Colors.green),

            const SizedBox(height: 8),

            _summaryRow('Expenses', expenses, Colors.red),

            const Divider(height: 22),

            _summaryRow(
              'Balance',
              balance,
              balance >= 0 ? Colors.green : Colors.red,
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(String title, double amount, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            color: Color(0xFF4A3025),
          ),
        ),
        Text(
          'Rs. ${amount.toStringAsFixed(2)}',
          style: TextStyle(fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 45),
      child: Column(
        children: [
          const Icon(Icons.receipt_long, size: 65, color: Color(0xFF854C30)),
          const SizedBox(height: 15),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF4A3025),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(TransactionModel transaction) {
    final isIncome = transaction.type == 'Income';

    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: ListTile(
        onTap: () => _editTransaction(transaction),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: isIncome
              ? const Color(0xFFE0EBDD)
              : const Color(0xFFF4E0D8),
          child: Icon(
            isIncome ? Icons.arrow_downward : Icons.arrow_upward,
            color: isIncome ? Colors.green : const Color(0xFF854C30),
          ),
        ),
        title: Text(
          transaction.title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF4A3025),
          ),
        ),
        subtitle: Text(
          '${_categoryName(transaction.categoryId)}'
          ' • ${_formatDate(transaction.date)}'
          '${transaction.note.isNotEmpty ? '\n${transaction.note}' : ''}',
        ),
        isThreeLine: transaction.note.isNotEmpty,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${isIncome ? '+' : '-'} Rs. '
              '${transaction.amount.toStringAsFixed(2)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isIncome ? Colors.green : Colors.red,
                fontSize: 12,
              ),
            ),
            PopupMenuButton<String>(
              tooltip: 'Transaction options',
              onSelected: (value) {
                if (value == 'edit') {
                  _editTransaction(transaction);
                } else if (value == 'delete') {
                  _deleteTransaction(transaction);
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 20),
                      SizedBox(width: 10),
                      Text('Edit'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red, size: 20),
                      SizedBox(width: 10),
                      Text('Delete'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredTransactions = _filteredTransactions;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Transaction History',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loadHistory,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadHistory,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildFilters(),

                  const SizedBox(height: 12),

                  _buildSummary(),

                  const SizedBox(height: 12),

                  Text(
                    '${filteredTransactions.length} transaction(s) found',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF854C30),
                    ),
                  ),

                  const SizedBox(height: 10),

                  if (filteredTransactions.isEmpty)
                    _buildEmptyState(
                      _transactions.isEmpty
                          ? 'No transactions yet'
                          : 'No transactions match your filters',
                    )
                  else
                    ...filteredTransactions.map(_buildTransactionCard),
                ],
              ),
            ),
    );
  }
}
