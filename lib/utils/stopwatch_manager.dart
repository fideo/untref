import 'dart:async';

class StopwatchManager {
  final Stopwatch _stopwatch = Stopwatch();
  final StreamController<Duration> _controller = StreamController.broadcast();

  Timer? _timer;

  Stream<Duration> get timeStream => _controller.stream;

  void start() {
    if (!_stopwatch.isRunning) {
      _stopwatch.start();
      _timer = Timer.periodic(Duration(milliseconds: 100), (_) {
        _controller.add(_stopwatch.elapsed);
      });
    }
  }

  void stop() {
    _stopwatch.stop();
    _timer?.cancel();
  }

  void reset() {
    stop();
    _stopwatch.reset();
    _controller.add(Duration.zero);
  }

  Duration get current => _stopwatch.elapsed;

  void dispose() {
    _timer?.cancel();
    _controller.close();
  }
}