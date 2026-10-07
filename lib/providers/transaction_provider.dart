// lib/providers/transaction_provider.dart
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/my_transaction.dart';

class TransactionProvider with ChangeNotifier {
  static const _databaseName = 'expenses.db';
  static const _tableName = 'transactions';

  Future<Database>? _databaseFuture;
  List<MyTransaction> _transactions = [];
  bool _isLoading = false;
  String? _errorMessage;

  TransactionProvider() {
    unawaited(fetchAndSetTransactions().catchError((Object _) {}));
  }

  List<MyTransaction> get transactions => List.unmodifiable(_transactions);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<Database> _openDatabase() async {
    final databasePath = join(await getDatabasesPath(), _databaseName);
    return openDatabase(
      databasePath,
      version: 1,
      onCreate: (db, version) => db.execute(
        'CREATE TABLE $_tableName('
        'id INTEGER PRIMARY KEY AUTOINCREMENT, '
        'title TEXT NOT NULL, '
        'amount REAL NOT NULL, '
        'date TEXT NOT NULL, '
        'type TEXT NOT NULL)',
      ),
    );
  }

  Future<Database> _initDatabase() async {
    final future = _databaseFuture ??= _openDatabase();
    try {
      return await future;
    } catch (_) {
      if (identical(_databaseFuture, future)) _databaseFuture = null;
      rethrow;
    }
  }

  Future<void> fetchAndSetTransactions() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final db = await _initDatabase();
      final rows = await db.query(_tableName, orderBy: 'date DESC, id DESC');
      _transactions = rows.map(MyTransaction.fromMap).toList();
    } catch (error) {
      _errorMessage = 'โหลดรายการไม่สำเร็จ: $error';
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addTransaction(
    String title,
    double amount,
    DateTime date,
    TransactionType type,
  ) async {
    final db = await _initDatabase();
    await db.insert(
      _tableName,
      MyTransaction(
        title: title,
        amount: amount,
        date: date,
        type: type,
      ).toMap(),
    );
    await fetchAndSetTransactions();
  }

  Future<void> updateTransaction(int id, MyTransaction newTransaction) async {
    final db = await _initDatabase();
    final values = newTransaction.toMap()..remove('id');
    await db.update(_tableName, values, where: 'id = ?', whereArgs: [id]);
    await fetchAndSetTransactions();
  }

  Future<void> deleteTransaction(int id) async {
    final db = await _initDatabase();
    await db.delete(_tableName, where: 'id = ?', whereArgs: [id]);
    await fetchAndSetTransactions();
  }
}