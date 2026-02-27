import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

import '../../../core/constants/app_constants.dart';

class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  Database? _db;

  Future<Database> get database async {
    _db ??= await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final path = p.join(await getDatabasesPath(), AppConstants.dbName);
    return openDatabase(
      path,
      version: AppConstants.dbVersion,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE exchange_rates (
        currency_code TEXT NOT NULL,
        rate          REAL NOT NULL,
        base_currency TEXT NOT NULL,
        fetched_at    INTEGER NOT NULL,
        PRIMARY KEY (currency_code, base_currency)
      )
    ''');

    await db.execute('''
      CREATE TABLE currencies (
        code TEXT PRIMARY KEY,
        name TEXT NOT NULL
      )
    ''');
  }

  /// Quick helper to clear and reinsert rows in a single transaction
  Future<void> replaceAll(String table, List<Map<String, dynamic>> rows) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete(table);
      for (final row in rows) {
        await txn.insert(table, row, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }

  Future<List<Map<String, dynamic>>> query(
    String table, {
    String? where,
    List<Object?>? whereArgs,
    String? orderBy,
  }) async {
    final db = await database;
    return db.query(table, where: where, whereArgs: whereArgs, orderBy: orderBy);
  }

  Future<void> close() async => _db?.close();
}
