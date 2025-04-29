import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/session.dart'; // Acordate de importar el modelo

class DatabaseHelper {

  Future<int> insertSession(Session session) async {
    final db = await database;
    return await db.insert('sessions', session.toMap());
  }

  Future<int> insertSwimmer(Map<String, dynamic> swimmer) async {
    final db = await database;
    return await db.insert('swimmers', swimmer);
  }

  Future<List<Map<String, dynamic>>> getSwimmersBySession(int sessionId) async {
    final db = await database;
    return await db.query('swimmers', where: 'session_id = ?', whereArgs: [sessionId]);
  }

  Future<int> updateSwimmer(int id, Map<String, dynamic> swimmer) async {
    final db = await database;
    return await db.update('swimmers', swimmer, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteSwimmer(int id) async {
    final db = await database;
    return await db.delete('swimmers', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> saveSplit(int sessionId, int swimmerId, Duration tiempo, int numeroParcial) async {
    final db = await database;
    await db.insert('splits', {
      'session_id': sessionId,
      'swimmer_id': swimmerId,
      'time': tiempo.toString(), // o tiempo.inMilliseconds
      'lap_number': numeroParcial,
    });
  }

  static Database? _database;

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  static Future<Database> _initDB() async {
    if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'natacion.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE sessions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            date TEXT,
            distance TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE swimmers(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            session_id INTEGER,
            name TEXT,
            lane INTEGER,
            FOREIGN KEY(session_id) REFERENCES sessions(id)
          )
        ''');

        await db.execute('''
          CREATE TABLE swimmer_results (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            session_id INTEGER,
            name TEXT,
            lane INTEGER,
            total_time TEXT,
            splits TEXT,
            FOREIGN KEY (session_id) REFERENCES sessions(id)
          )
        ''');

        await db.execute('''
          CREATE TABLE splits (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            swimmer_id INTEGER,
            session_id INTEGER,
            time TEXT,  -- Guardado como "00:01:23.450"
            lap_number INTEGER
          );
        ''');

      },
    );
  }
}