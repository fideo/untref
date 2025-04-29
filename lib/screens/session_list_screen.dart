import 'dart:async';
import 'package:flutter/material.dart';
import 'package:untref/db/database_helper.dart';
import '../utils/stopwatch_manager.dart';
import '../utils/stopwatch_provider.dart';
import 'package:intl/intl.dart';
import '../models/session.dart';
import '../models/swimmer.dart';


import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'package:share_plus/share_plus.dart';

class SwimmerListScreen extends StatefulWidget {
  final int sessionId;

  SwimmerListScreen({required this.sessionId});

  @override
  _SwimmerListScreenState createState() => _SwimmerListScreenState();
}

class _SwimmerListScreenState extends State<SwimmerListScreen> {
  final StopwatchManager stopwatchManager = StopwatchManager();
  List<Map<String, dynamic>> _swimmers = [];
  final List<Swimmer> swimmers = [];
  Map<int, Stopwatch> stopwatches = {};
  Map<int, Timer?> timers = {};

  // Helper: calcula los encabezados para la cantidad máxima de parciales
  List<String> _maxSplitsHeader() {
    final maxSplits = swimmers.map((s) => s.splits.length).fold<int>(0, (a, b) => a > b ? a : b);
    return List.generate(maxSplits, (i) => 'Pasada ${i + 1}');
  }

  // Ya tenés esto en swimmer_card.dart, pero lo copiamos acá también
  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    final millis = (d.inMilliseconds.remainder(1000) ~/ 10).toString().padLeft(2, '0');
    return '$minutes:$seconds.$millis';
  }

  // Exportar Share Plus
  Future<void> _exportAndShareExcel() async {
    final status = await Permission.storage.request();
    if (!status.isGranted) {
      return;
    }

    var excel = Excel.createExcel();
    Sheet sheet = excel['Nadadores'];

    sheet.appendRow(['Nombre', 'Andarivel', ..._maxSplitsHeader()]);
    for (var swimmer in swimmers) {
      List<String> row = [
        swimmer.name,
        swimmer.lane.toString(),
        ...swimmer.splits.map((d) => _formatDuration(d)),
      ];
      sheet.appendRow(row);
    }

    final directory = await getTemporaryDirectory(); // usamos temporal para facilitar compartir
    String outputPath = '${directory.path}/nadadores.xlsx';
    File file = File(outputPath)
      ..createSync(recursive: true)
      ..writeAsBytesSync(excel.encode()!);

    // Compartimos
    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Resultados de los nadadores 🏊',
    );
  }

  @override
  void initState() {
    super.initState();
    _loadSwimmers();
  }

  void _resetAll() {
    stopwatchManager.reset();
    setState(() {
      stopwatches.forEach((index, sw) {
        if (!sw.isRunning) {
          sw.reset();
        }
      });
    });
  }

  void _startAll() {
    stopwatchManager.start();
    setState(() {
      stopwatches.forEach((index, sw) {
        if (!sw.isRunning) {
          sw.start();
          timers[index] = Timer.periodic(Duration(milliseconds: 100), (timer) {
            setState(() {}); // Redibuja para actualizar el tiempo mostrado
          });
        }
      });
    });
  }

  void _stopAll() {
    stopwatchManager.stop();
    setState(() {
      stopwatches.forEach((index, sw) {
        if (sw.isRunning) {
          sw.stop();
          timers[index]?.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    stopwatchManager.dispose();
    super.dispose();
  }


  Future<void> _loadSwimmers() async {
    final swimmers = await DatabaseHelper().getSwimmersBySession(
        widget.sessionId);
    setState(() {
      _swimmers = swimmers;

    // Inicializa los cronómetros y timers una vez que se cargan los nadadores
      for (int i = 0; i < _swimmers.length; i++) {
        stopwatches[i] = Stopwatch();
        timers[i] = null;
      }

    });
  }

  Future<void> _editSwimmer(Map<String, dynamic> swimmer) async {
    TextEditingController nameController = TextEditingController(
        text: swimmer['name']);
    TextEditingController laneController = TextEditingController(
        text: swimmer['lane'].toString());

    await showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: Text('Editar Nadador'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(labelText: 'Nombre'),
                ),
                TextField(
                  controller: laneController,
                  decoration: InputDecoration(labelText: 'Andarivel (número)'),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancelar'),
              ),
              TextButton(
                onPressed: () async {
                  if (nameController.text.isNotEmpty &&
                      laneController.text.isNotEmpty) {
                    await DatabaseHelper().updateSwimmer(swimmer['id'], {
                      'session_id': swimmer['session_id'],
                      'name': nameController.text,
                      'lane': int.tryParse(laneController.text) ?? 0,
                    });
                    _loadSwimmers();
                    Navigator.pop(context);
                  }
                },
                child: Text('Guardar'),
              ),
            ],
          ),
    );
  }

  Future<void> _deleteSwimmer(int id) async {
    await DatabaseHelper().deleteSwimmer(id);
    _loadSwimmers();
  }

  Future<void> _addSwimmer() async {
    TextEditingController nameController = TextEditingController();
    TextEditingController laneController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: Text('Agregar Nadador'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(labelText: 'Nombre'),
                ),
                TextField(
                  controller: laneController,
                  decoration: InputDecoration(labelText: 'Andarivel (número)'),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancelar'),
              ),
              TextButton(
                onPressed: () async {
                  if (nameController.text.isNotEmpty &&
                      laneController.text.isNotEmpty) {
                    await DatabaseHelper().insertSwimmer({
                      'session_id': widget.sessionId,
                      'name': nameController.text,
                      'lane': int.tryParse(laneController.text) ?? 0,
                    });
                    _loadSwimmers();
                    Navigator.pop(context);
                  }
                },
                child: Text('Guardar'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Nadadores - Sesión ${widget.sessionId}'),
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(child: ElevatedButton(
                  onPressed: _startAll, child: Text('Iniciar Todos'),),),
                SizedBox(width: 8),
                Expanded(child: ElevatedButton(
                  onPressed: _stopAll, child: Text('Detener Todos'),),),
                SizedBox(width: 8),
                Expanded(child: ElevatedButton(
                  onPressed: _resetAll, child: Text('Resetear Todos'),),),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              children: [
                ElevatedButton.icon(onPressed: _exportAndShareExcel, icon: Icon(Icons.share), label: Text('Exportar y Compartir'),),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _swimmers.length,
              itemBuilder: (context, index) {
                final swimmer = _swimmers[index];
                final sw = stopwatches[index];
                final elapsed = sw?.elapsed ?? Duration.zero;

                final formattedTime =
                    '${elapsed.inMinutes.toString().padLeft(2, '0')}:${(elapsed
                    .inSeconds % 60).toString().padLeft(2, '0')}.${(elapsed
                    .inMilliseconds % 1000 ~/ 10).toString().padLeft(2, '0')}';

                return ListTile(
                  title: Text('${swimmer['name']}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Andarivel: ${swimmer['lane']}'),
                      Text('Tiempo: $formattedTime'),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // IconButton(icon: Icon(Icons.flag), onPressed: () => ),
                      IconButton(icon: Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _editSwimmer(swimmer),),
                      IconButton(icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteSwimmer(swimmer['id']),),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addSwimmer,
        child: Icon(Icons.add),
      ),
    );
  }
}

class SessionListScreen extends StatefulWidget {
  const SessionListScreen({super.key});

  @override
  State<SessionListScreen> createState() => _SessionListScreenState();
}

class _SessionListScreenState extends State<SessionListScreen> {
  List<Map<String, dynamic>> sessions = [];

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    final db = await DatabaseHelper.database;
    final data = await db.query('sessions');
    setState(() {
      sessions = data;
    });
  }

  Future<void> _addSession() async {
    TextEditingController distanceController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Ingresar distancia'),
        content: TextField(
          controller: distanceController,
          decoration: InputDecoration(hintText: 'Ej: 100 metros'),
        ),
        actions: [
          TextButton(
            child: Text('Cancelar'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          TextButton(
            child: Text('Aceptar'),
            onPressed: () async {
              final distance = distanceController.text;
              if (distance.isNotEmpty) {
                final session = Session(
                  date: DateTime.now().toIso8601String(),
                  distance: distance,
                );
                await DatabaseHelper().insertSession(session);
                _loadSessions();
                Navigator.of(context).pop(); // Cierra el dialogo
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sesiones de UNTREF Natación'),
      ),
      body: ListView.builder(
        itemCount: sessions.length,
        itemBuilder: (context, index) {
          final session = sessions[index];
          return ListTile(
            title: Text('Fecha: ${session['date']}'),
            subtitle: Text('Distancia: ${session['distance']}'),
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                  builder: (context) => SwimmerListScreen(sessionId: session['id']),
              ),
              );
              // ACA nos falta hacer que al tocar, nos lleve a cargar nadadores.
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addSession,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class ListaSplits extends StatelessWidget {
  final int swimmerId;
  final int sessionId;

  const ListaSplits({required this.swimmerId, required this.sessionId});

  Future<List<Map<String, dynamic>>> obtenerSplits() async {
    final db = await  DatabaseHelper.database;
    return await db.query(
      'splits',
      where: 'session_id = ? AND swimmer_id = ?',
      whereArgs: [sessionId, swimmerId],
      orderBy: 'lap_number ASC',
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: obtenerSplits(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return CircularProgressIndicator();
        final splits = snapshot.data!;
        return ListView.builder(
          itemCount: splits.length,
          itemBuilder: (context, index) {
            final split = splits[index];
            return ListTile(
              leading: Text('Parcial ${split['lap_number']}'),
              title: Text('${split['time']}'),
            );
          },
        );
      },
    );
  }
}