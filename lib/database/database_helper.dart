import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../models/transaction.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('momo_float_tracker.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final Directory documentsDirectory = await getApplicationDocumentsDirectory();
    final String path = join(documentsDirectory.path, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        network INTEGER NOT NULL,
        type INTEGER NOT NULL,
        amount REAL NOT NULL,
        fee REAL,
        balanceAfter REAL NOT NULL,
        customerName TEXT,
        customerPhone TEXT,
        notes TEXT,
        timestamp TEXT NOT NULL
      )
    ''');
  }

  // Get current float balance for a network
  Future<double> getCurrentBalance(NetworkType network) async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.query(
      'transactions',
      where: 'network = ?',
      whereArgs: [network.index],
      orderBy: 'timestamp DESC',
      limit: 1,
    );

    if (result.isEmpty) return 0.0;
    return result.first['balanceAfter'] as double;
  }

  // Add new transaction
  Future<int> insertTransaction(FloatTransaction transaction) async {
    final db = await database;
    return await db.insert('transactions', transaction.toMap());
  }

  // Get all transactions
  Future<List<FloatTransaction>> getAllTransactions() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      orderBy: 'timestamp DESC',
    );
    return List.generate(maps.length, (i) => FloatTransaction.fromMap(maps[i]));
  }

  // Get transactions by network
  Future<List<FloatTransaction>> getTransactionsByNetwork(NetworkType network) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      where: 'network = ?',
      whereArgs: [network.index],
      orderBy: 'timestamp DESC',
    );
    return List.generate(maps.length, (i) => FloatTransaction.fromMap(maps[i]));
  }

  // Get transactions for today
  Future<List<FloatTransaction>> getTodayTransactions() async {
    final db = await database;
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day).toIso8601String();
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59).toIso8601String();

    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      where: 'timestamp BETWEEN ? AND ?',
      whereArgs: [startOfDay, endOfDay],
      orderBy: 'timestamp DESC',
    );
    return List.generate(maps.length, (i) => FloatTransaction.fromMap(maps[i]));
  }

  // Get transactions by date range
  Future<List<FloatTransaction>> getTransactionsByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      where: 'timestamp BETWEEN ? AND ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'timestamp DESC',
    );
    return List.generate(maps.length, (i) => FloatTransaction.fromMap(maps[i]));
  }

  // Delete transaction
  Future<int> deleteTransaction(int id) async {
    final db = await database;
    return await db.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Get summary statistics
  Future<Map<String, dynamic>> getSummary() async {
    final db = await database;

    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day).toIso8601String();
    final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59).toIso8601String();

    // MTN Stats
    final mtnCashIn = await db.rawQuery('''
      SELECT COALESCE(SUM(amount), 0) as total FROM transactions 
      WHERE network = ? AND type = ? AND timestamp BETWEEN ? AND ?
    ''', [NetworkType.mtn.index, TransactionType.cashIn.index, startOfDay, endOfDay]);

    final mtnCashOut = await db.rawQuery('''
      SELECT COALESCE(SUM(amount), 0) as total FROM transactions 
      WHERE network = ? AND type = ? AND timestamp BETWEEN ? AND ?
    ''', [NetworkType.mtn.index, TransactionType.cashOut.index, startOfDay, endOfDay]);

    // Airtel Stats
    final airtelCashIn = await db.rawQuery('''
      SELECT COALESCE(SUM(amount), 0) as total FROM transactions 
      WHERE network = ? AND type = ? AND timestamp BETWEEN ? AND ?
    ''', [NetworkType.airtel.index, TransactionType.cashIn.index, startOfDay, endOfDay]);

    final airtelCashOut = await db.rawQuery('''
      SELECT COALESCE(SUM(amount), 0) as total FROM transactions 
      WHERE network = ? AND type = ? AND timestamp BETWEEN ? AND ?
    ''', [NetworkType.airtel.index, TransactionType.cashOut.index, startOfDay, endOfDay]);

    // Total fees
    final totalFees = await db.rawQuery('''
      SELECT COALESCE(SUM(fee), 0) as total FROM transactions 
      WHERE timestamp BETWEEN ? AND ? AND fee IS NOT NULL
    ''', [startOfDay, endOfDay]);

    return {
      'mtnCashIn': (mtnCashIn.first['total'] as num?)?.toDouble() ?? 0.0,
      'mtnCashOut': (mtnCashOut.first['total'] as num?)?.toDouble() ?? 0.0,
      'airtelCashIn': (airtelCashIn.first['total'] as num?)?.toDouble() ?? 0.0,
      'airtelCashOut': (airtelCashOut.first['total'] as num?)?.toDouble() ?? 0.0,
      'totalFees': (totalFees.first['total'] as num?)?.toDouble() ?? 0.0,
      'mtnBalance': await getCurrentBalance(NetworkType.mtn),
      'airtelBalance': await getCurrentBalance(NetworkType.airtel),
    };
  }

  // Export all transactions as CSV
  Future<String> exportToCSV() async {
    final transactions = await getAllTransactions();
    final StringBuffer csv = StringBuffer();

    csv.writeln('ID,Network,Type,Amount,Fee,Balance After,Customer Name,Customer Phone,Notes,Timestamp');

    for (var t in transactions) {
      csv.writeln('${t.id},${t.networkLabel},${t.typeLabel},${t.amount},${t.fee ?? 0},${t.balanceAfter},"${t.customerName ?? ''}","${t.customerPhone ?? ''}","${t.notes ?? ''}",${t.timestamp.toIso8601String()}');
    }

    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/momo_transactions_export.csv');
    await file.writeAsString(csv.toString());
    return file.path;
  }

  Future close() async {
    final db = await database;
    db.close();
  }
}
