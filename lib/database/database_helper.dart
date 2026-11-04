
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import '../models/transaction.dart';
import '../models/category.dart';
import '../models/budget.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();

  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDB('spendwise.db');
    return _database!;
  }

  Future<Database> _initDB(String fileName) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, fileName);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        categoryId INTEGER NOT NULL,
        date TEXT NOT NULL,
        type TEXT NOT NULL,
        note TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        type TEXT NOT NULL
      )
    ''');

    await _createBudgetTable(db);
  }

  Future<void> _onUpgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) {
      await _createBudgetTable(db);
    }
  }

  Future<void> _createBudgetTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS budgets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        categoryId INTEGER NOT NULL,
        month TEXT NOT NULL,
        amount REAL NOT NULL,
        UNIQUE(categoryId, month)
      )
    ''');
  }

  // INSERT TRANSACTION
  Future<int> insertTransaction(
    TransactionModel transaction,
  ) async {
    final db = await database;

    return await db.insert(
      'transactions',
      transaction.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // GET TRANSACTIONS
  Future<List<TransactionModel>> getTransactions() async {
    final db = await database;

    final result = await db.query(
      'transactions',
      orderBy: 'date DESC, id DESC',
    );

    return result.map((map) {
      return TransactionModel.fromMap({
        ...map,
        'amount': (map['amount'] as num).toDouble(),
      });
    }).toList();
  }

  // UPDATE TRANSACTION
  Future<int> updateTransaction(
    TransactionModel transaction,
  ) async {
    final db = await database;

    return await db.update(
      'transactions',
      transaction.toMap(),
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
  }

  // DELETE TRANSACTION
  Future<int> deleteTransaction(int id) async {
    final db = await database;

    return await db.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // INSERT CATEGORY
  Future<int> insertCategory(CategoryModel category) async {
    final db = await database;

    return await db.insert(
      'categories',
      category.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // GET CATEGORIES
  Future<List<CategoryModel>> getCategories() async {
    final db = await database;

    final result = await db.query('categories');

    return result.map((map) {
      return CategoryModel.fromMap(map);
    }).toList();
  }

  // SAVE OR UPDATE MONTHLY BUDGET
  Future<int> saveBudget(BudgetModel budget) async {
    final db = await database;

    return await db.insert(
      'budgets',
      budget.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // GET BUDGETS FOR A SELECTED MONTH
  Future<List<BudgetModel>> getBudgetsForMonth(
    String month,
  ) async {
    final db = await database;

    final result = await db.query(
      'budgets',
      where: 'month = ?',
      whereArgs: [month],
    );

    return result.map((map) {
      return BudgetModel.fromMap(map);
    }).toList();
  }

  // DELETE A BUDGET
  Future<int> deleteBudget(int id) async {
    final db = await database;

    return await db.delete(
      'budgets',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
