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
    currentTime = Duration.zero;
    widget.stopwatchManager.timeStream.listen((elapsed) {
      if (widget.swimmer.isRunning) {
        setState(() {
          currentTime = elapsed;
        });
      }
    });
  }

  void takeSplit() {
    setState(() {
      widget.swimmer.splits.add(currentTime);
    });
  }

  void stop() {
    setState(() {
      widget.swimmer.elapsed = currentTime;
      widget.swimmer.isRunning = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: ListTile(
        title: Text('${widget.swimmer.name} (Andarivel ${widget.swimmer.lane})'),
        subtitle: Text('Tiempo: ${_formatDuration(currentTime)}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(icon: Icon(Icons.flag), onPressed: takeSplit),
            IconButton(icon: Icon(Icons.stop), onPressed: stop),
          ],
        ),
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