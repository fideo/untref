import 'package:flutter/material.dart';
import '../models/swimmer.dart';
import '../utils/stopwatch_manager.dart';
import '../widgets/swimmer_card.dart';

import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

import 'package:share_plus/share_plus.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final StopwatchManager stopwatchManager = StopwatchManager();
  final List<Swimmer> swimmers = [];

  void _resetAll() {
    stopwatchManager.reset();
    setState(() {
      for (var s in swimmers) {
        s.reset();
      }
    });
  }

  void addSwimmer(String name, int lane) {
    setState(() {
      swimmers.add(Swimmer(name: name, lane: lane));
    });
  }

  void _showAddDialog() {
    final nameController = TextEditingController();
    final laneController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Agregar nadador'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: InputDecoration(labelText: 'Nombre')),
            TextField(controller: laneController, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Andarivel')),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              final name = nameController.text;
              final lane = int.tryParse(laneController.text) ?? 0;
              if (name.isNotEmpty && lane > 0) {
                addSwimmer(name, lane);
              }
              Navigator.pop(context);
            },
            child: Text('Agregar'),
          )
        ],
      ),
    );
  }

  void _startAll() {
    stopwatchManager.start();
    setState(() {
      for (var s in swimmers) {
        s.isRunning = true;
      }
    });
  }

  void _stopAll() {
    stopwatchManager.stop();
    setState(() {
      for (var s in swimmers) {
        s.isRunning = false;
      }
    });
  }

  @override
  void dispose() {
    stopwatchManager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('UNTREF Natación')),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        child: Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(child: ElevatedButton(onPressed: _startAll, child: Text('Iniciar Todos'))),
                SizedBox(width: 8),
                Expanded(child: ElevatedButton(onPressed: _stopAll, child: Text('Detener Todos'))),
                SizedBox(width: 8),
                Expanded(child: ElevatedButton(onPressed: _resetAll, child: Text('Resetear Todos'))),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              children: [
                /*ElevatedButton.icon(
                  onPressed: _exportToExcel,
                  icon: Icon(Icons.download),
                  label: Text('Exportar a Excel'),
                ),*/
                ElevatedButton.icon(
                  onPressed: _exportAndShareExcel,
                  icon: Icon(Icons.share),
                  label: Text('Exportar y Compartir'),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: swimmers.length,
              itemBuilder: (context, index) {
                return SwimmerCard(
                  swimmer: swimmers[index],
                  stopwatchManager: stopwatchManager,
                );
              },
            ),
          )
        ],
      ),
    );
  }

  // Exportar a Excel
  Future<void> _exportToExcel() async {
    final status = await Permission.storage.request();
    if (!status.isGranted) {
      return;
    }

    var excel = Excel.createExcel();
    Sheet sheet = excel['Nadadores'];

    // Primera fila con encabezados
    sheet.appendRow(['Nombre', 'Andarivel', ..._maxSplitsHeader()]);

    // Agregar los datos
    for (var swimmer in swimmers) {
      List<String> row = [
        swimmer.name,
        swimmer.lane.toString(),
        ...swimmer.splits.map((d) => _formatDuration(d)),
      ];
      sheet.appendRow(row);
    }

    // Obtener ruta y guardar archivo
    final directory = await getExternalStorageDirectory();
    String outputPath = '${directory!.path}/nadadores.xlsx';
    File(outputPath)
      ..createSync(recursive: true)
      ..writeAsBytesSync(excel.encode()!);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Archivo guardado en: $outputPath')),
    );
  }

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


}