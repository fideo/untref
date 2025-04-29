import 'dart:async';
import 'package:flutter/material.dart';
import 'package:untref/db/database_helper.dart';// Ajustá el path según tu estructura

class StopwatchProvider with ChangeNotifier {
  final int sessionId;
  final int swimmerId;

  final Stopwatch _stopwatch = Stopwatch();
  Timer? _timer;
  Duration _elapsed = Duration.zero;
  List<Map<String, dynamic>> _splits = [];
  int _lapCounter = 1;

  StopwatchProvider({
    required this.sessionId,
    required this.swimmerId,
  }) {
    _init();
  }

  Duration get elapsed => _elapsed;
  List<Map<String, dynamic>> get splits => _splits;

  void _init() {
    _stopwatch.start();
    _timer = Timer.periodic(Duration(milliseconds: 30), (_) {
      _elapsed = _stopwatch.elapsed;
      notifyListeners();
    });
    _loadSplits();
  }

  Future<void> _loadSplits() async {
    final db = await DatabaseHelper.database;
    final results = await db.query(
      'splits',
      where: 'session_id = ? AND swimmer_id = ?',
      whereArgs: [sessionId, swimmerId],
      orderBy: 'lap_number ASC',
    );
    _splits = results;
    _lapCounter = _splits.length + 1;
    notifyListeners();
  }

  Future<void> addSplit() async {
    final tiempo = _stopwatch.elapsed;
    final db = await DatabaseHelper.database;

    await db.insert('splits', {
      'session_id': sessionId,
      'swimmer_id': swimmerId,
      'time': tiempo.toString(),
      'lap_number': _lapCounter,
    });

    _splits.add({
      'lap_number': _lapCounter,
      'time': tiempo.toString(),
    });
    _lapCounter++;
    notifyListeners();
  }

  void disposeProvider() {
    _timer?.cancel();
    _stopwatch.stop();
  }
}