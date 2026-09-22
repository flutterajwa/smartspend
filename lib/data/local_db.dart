import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../data/models/transaction_model.dart';
import '../data/models/budget_model.dart';
import '../data/models/debt_model.dart';
import '../data/models/recurring_transaction_model.dart';

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
      version: 7,
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
        await db.execute('''
            CREATE TABLE IF NOT EXISTS debts (
              id TEXT PRIMARY KEY,
              personName TEXT,
              amount REAL,
              type TEXT,
              date TEXT,
              note TEXT,
              isSettled INTEGER,
              dueDate TEXT,
              settledDate TEXT
            )
          ''');
        await db.execute('''
          CREATE TABLE IF NOT EXISTS recurring_transactions (
            id TEXT PRIMARY KEY,
            title TEXT,
            amount REAL,
            category TEXT,
            type TEXT,
            startDate TEXT,
            frequency TEXT,
            isActive INTEGER,
            lastExecutedDate TEXT,
            paymentMethod TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE IF NOT EXISTS categories (
            name TEXT PRIMARY KEY,
            icon INTEGER,
            color INTEGER
          )
        ''');
        
        final defaults = [
          {'name': 'Food', 'icon': 0xe52a, 'color': 0xFFFF9800},
          {'name': 'Travel', 'icon': 0xe1d1, 'color': 0xFF2196F3},
          {'name': 'Bills', 'icon': 0xf00b0, 'color': 0xFFF44336},
          {'name': 'Shopping', 'icon': 0xf37f, 'color': 0xFF9C27B0},
          {'name': 'Health', 'icon': 0xe3e7, 'color': 0xFF4CAF50},
          {'name': 'Salary', 'icon': 0xf0074, 'color': 0xFF009688},
          {'name': 'Others', 'icon': 0xe402, 'color': 0xFF9E9E9E},
        ];
        for (var c in defaults) {
          await db.insert('categories', c);
        }
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
        if (oldVersion < 4) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS debts (
              id TEXT PRIMARY KEY,
              personName TEXT,
              amount REAL,
              type TEXT,
              date TEXT,
              note TEXT,
              isSettled INTEGER,
              dueDate TEXT,
              settledDate TEXT
            )
          ''');
        }
        if (oldVersion < 5) {
          // Check if columns exist before adding (safest for migrations)
          var columns = await db.rawQuery('PRAGMA table_info(debts)');
          var columnNames = columns.map((c) => c['name'] as String).toList();
          
          if (!columnNames.contains('dueDate')) {
             await db.execute('ALTER TABLE debts ADD COLUMN dueDate TEXT');
          }
          if (!columnNames.contains('settledDate')) {
             await db.execute('ALTER TABLE debts ADD COLUMN settledDate TEXT');
          }
        }
        if (oldVersion < 6) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS recurring_transactions (
              id TEXT PRIMARY KEY,
              title TEXT,
              amount REAL,
              category TEXT,
              type TEXT,
              startDate TEXT,
              frequency TEXT,
              isActive INTEGER,
              lastExecutedDate TEXT,
              paymentMethod TEXT
            )
          ''');
        }
        if (oldVersion < 7) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS categories (
              name TEXT PRIMARY KEY,
              icon INTEGER,
              color INTEGER
            )
          ''');
          final defaults = [
            {'name': 'Food', 'icon': 0xe52a, 'color': 0xFFFF9800},
            {'name': 'Travel', 'icon': 0xe1d1, 'color': 0xFF2196F3},
            {'name': 'Bills', 'icon': 0xf00b0, 'color': 0xFFF44336},
            {'name': 'Shopping', 'icon': 0xf37f, 'color': 0xFF9C27B0},
            {'name': 'Health', 'icon': 0xe3e7, 'color': 0xFF4CAF50},
            {'name': 'Salary', 'icon': 0xf0074, 'color': 0xFF009688},
            {'name': 'Others', 'icon': 0xe402, 'color': 0xFF9E9E9E},
          ];
          for (var c in defaults) {
            await db.insert('categories', c, conflictAlgorithm: ConflictAlgorithm.ignore);
          }
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

  // Debt DB Methods
  static Future<void> insertDebt(DebtModel debt) async {
    final db = await database;
    await db.insert('debts', debt.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<List<DebtModel>> getDebts() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('debts', orderBy: 'date DESC');
    return List.generate(maps.length, (i) => DebtModel.fromMap(maps[i]));
  }

  static Future<void> deleteDebt(String id) async {
    final db = await database;
    await db.delete('debts', where: 'id = ?', whereArgs: [id]);
  }

  static Future<void> updateDebtSettlement(String id, bool isSettled, {DateTime? settledDate}) async {
    final db = await database;
    await db.update(
      'debts', 
      {
        'isSettled': isSettled ? 1 : 0,
        'settledDate': isSettled ? (settledDate ?? DateTime.now()).toIso8601String() : null,
      }, 
      where: 'id = ?', 
      whereArgs: [id]
    );
  }

  // Recurring Transactions DB Methods
  static Future<void> insertRecurringTransaction(RecurringTransactionModel recurring) async {
    final db = await database;
    await db.insert('recurring_transactions', recurring.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<List<RecurringTransactionModel>> getRecurringTransactions() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('recurring_transactions');
    return List.generate(maps.length, (i) => RecurringTransactionModel.fromMap(maps[i]));
  }

  static Future<void> deleteRecurringTransaction(String id) async {
    final db = await database;
    await db.delete('recurring_transactions', where: 'id = ?', whereArgs: [id]);
  }

  static Future<void> updateRecurringTransaction(RecurringTransactionModel recurring) async {
    final db = await database;
    await db.update(
      'recurring_transactions',
      recurring.toMap(),
      where: 'id = ?',
      whereArgs: [recurring.id],
    );
  }

  // Category DB Methods
  static Future<List<Map<String, dynamic>>> getCategories() async {
    final db = await database;
    return await db.query('categories');
  }

  static Future<void> saveCategory(String name, int iconCode, int colorValue) async {
    final db = await database;
    await db.insert(
      'categories',
      {
        'name': name,
        'icon': iconCode,
        'color': colorValue,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<void> deleteCategory(String name) async {
    final db = await database;
    await db.delete('categories', where: 'name = ?', whereArgs: [name]);
  }
}
