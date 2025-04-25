import 'package:flutter/material.dart';
import '../models/swimmer.dart';
import '../utils/stopwatch_manager.dart';

class SwimmerCard extends StatefulWidget {
  final Swimmer swimmer;
  final StopwatchManager stopwatchManager;

  const SwimmerCard({
    super.key,
    required this.swimmer,
    required this.stopwatchManager,
  });

  @override
  State<SwimmerCard> createState() => _SwimmerCardState();
}

class _SwimmerCardState extends State<SwimmerCard> {
  late Duration currentTime;

  @override
  void initState() {
    super.initState();
    currentTime = widget.swimmer.isRunning ? widget.stopwatchManager.current : widget.swimmer.elapsed;
    widget.stopwatchManager.timeStream.listen((elapsed) {
      setState(() {
        if (widget.swimmer.isRunning) {
          currentTime = elapsed;
        } else if (elapsed == Duration.zero) {
          // Mostrar cero cuando el cronómetro fue reseteado
          currentTime = widget.swimmer.elapsed;
        }
      });
    });
  }

  void takeSplit() {
    setState(() {
      final time = widget.swimmer.isRunning
          ? widget.stopwatchManager.current
          : widget.swimmer.elapsed;
      widget.swimmer.splits.add(time);
    });
  }

  void stop() {
    setState(() {
      widget.swimmer.elapsed = widget.stopwatchManager.current;
      widget.swimmer.isRunning = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: ExpansionTile(
        title: Text('${widget.swimmer.name} (Andarivel ${widget.swimmer.lane}) - Parciales: ${widget.swimmer.splits.length}',),
        subtitle: Text('Tiempo actual: ${_formatDuration(currentTime)}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(icon: Icon(Icons.flag), onPressed: takeSplit),
            IconButton(icon: Icon(Icons.stop), onPressed: stop),
          ],
        ),
        children: widget.swimmer.splits.isNotEmpty
            ? widget.swimmer.splits
            .asMap()
            .entries
            .map((entry) => ListTile(
          dense: true,
          title: Text('Parcial ${entry.key + 1}: ${_formatDuration(entry.value)}'),
        ))
            .toList()
            : [Padding(padding: EdgeInsets.all(8), child: Text('Sin parciales'))],
      ),
    );
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    final millis = (d.inMilliseconds.remainder(1000) ~/ 10).toString().padLeft(2, '0');
    return '$minutes:$seconds.$millis';
  }
}