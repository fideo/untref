/*
import 'package:excel/excel.dart';

import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

// Helper: calcula los encabezados para la cantidad máxima de parciales
List<String> _maxSplitsHeader() {
  final maxSplits = swimmers.map((s) => s.splits.length).fold<int>(0, (a, b) => a > b ? a : b);
  return List.generate(maxSplits, (i) => 'Pasada ${i + 1}');
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

 */