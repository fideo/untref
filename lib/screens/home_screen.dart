import 'package:flutter/material.dart';
import '../models/swimmer.dart';
import '../utils/stopwatch_manager.dart';
import '../widgets/swimmer_card.dart';

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
      appBar: AppBar(title: Text('Swim Timer')),
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
}