class Swimmer {
  final String name;
  final int lane;
  bool isRunning;
  Duration elapsed;
  List<Duration> splits;

  Swimmer({
    required this.name,
    required this.lane,
    this.isRunning = false,
    this.elapsed = Duration.zero,
    List<Duration>? splits,
  }) : splits = splits ?? [];

  void reset() {
    isRunning = false;
    elapsed = Duration.zero;
    splits.clear();
  }
}