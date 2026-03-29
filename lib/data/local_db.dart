import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../data/models/transaction_model.dart';
import '../data/models/budget_model.dart';

class LocalDB {
  static Database? _database;

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  static Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'smartspend.db');

    return await openDatabase(
      path,
      version: 3,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS transactions (
            id TEXT PRIMARY KEY,
            userId TEXT,
            title TEXT,
            amount REAL,
            category TEXT,
            type TEXT,
            date TEXT,
            note TEXT,
            paymentMethod TEXT,
            toPaymentMethod TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE IF NOT EXISTS budgets (
            category TEXT,
            amount REAL,
            month INTEGER,
            year INTEGER,
            PRIMARY KEY (category, month, year)
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS budgets (
              category TEXT,
              amount REAL,
              month INTEGER,
              year INTEGER,
              PRIMARY KEY (category, month, year)
            )
          ''');
        }
        if (oldVersion < 3) {
          await db.execute('ALTER TABLE transactions ADD COLUMN paymentMethod TEXT DEFAULT "account"');
          await db.execute('ALTER TABLE transactions ADD COLUMN toPaymentMethod TEXT');
        }
      },
    );
  }

  // Budget DB Methods
  static Future<void> saveBudget(BudgetModel budget) async {
    final db = await database;
    await db.insert('budgets', budget.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<List<BudgetModel>> getBudgets(int month, int year) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'budgets', 
      where: 'month = ? AND year = ?', 
      whereArgs: [month, year]
    );
    return List.generate(maps.length, (i) => BudgetModel.fromMap(maps[i]));
  }

  static Future<void> deleteBudget(String category, int month, int year) async {
    final db = await database;
    await db.delete('budgets', where: 'category = ? AND month = ? AND year = ?', whereArgs: [category, month, year]);
  }

  static Future<void> insertTransaction(TransactionModel transaction) async {
    final db = await database;
    await db.insert('transactions', transaction.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<List<TransactionModel>> getTransactions() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('transactions', orderBy: 'date DESC');
    return List.generate(maps.length, (i) => TransactionModel.fromMap(maps[i]));
  }

  static Future<void> deleteTransaction(String id) async {
    final db = await database;
    await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }
}
