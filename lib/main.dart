import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:sqflite/sqflite.dart';

import 'screens/dashboard_screen.dart';
import 'screens/add_transaction_screen.dart';
import 'screens/history_screen.dart';
import 'screens/budgets_screen.dart';

void main() {
  databaseFactory = databaseFactoryFfiWeb;
  runApp(const SpendWiseApp());
}

class SpendWiseApp extends StatelessWidget {
  const SpendWiseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SpendWise',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF854C30)),
        scaffoldBackgroundColor: const Color(0xFFFFF5EC),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Widget _menuButton({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Widget screen,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF854C30),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => screen),
          );
        },
        icon: Icon(icon),
        label: Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'SpendWise',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF4A3025),
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFFFFF5EC),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.account_balance_wallet,
                size: 75,
                color: Color(0xFF854C30),
              ),

              const SizedBox(height: 18),

              const Text(
                'Welcome to SpendWise!',
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF854C30),
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Manage your money, track expenses, and stay on budget.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Color(0xFF8D7162)),
              ),

              const SizedBox(height: 35),

              _menuButton(
                context: context,
                title: 'Dashboard',
                icon: Icons.dashboard_outlined,
                screen: const DashboardScreen(),
              ),

              const SizedBox(height: 15),

              _menuButton(
                context: context,
                title: 'Add Transaction',
                icon: Icons.add_circle_outline,
                screen: const AddTransactionScreen(),
              ),

              const SizedBox(height: 15),

              _menuButton(
                context: context,
                title: 'Transaction History',
                icon: Icons.history,
                screen: const HistoryScreen(),
              ),

              const SizedBox(height: 15),

              _menuButton(
                context: context,
                title: 'Monthly Budgets',
                icon: Icons.account_balance_wallet_outlined,
                screen: const BudgetsScreen(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
