class SwimmerResult {
  final int? id;
  final int sessionId;
  final String name;
  final int lane;
  final String totalTime;
  final List<String> splits;

  SwimmerResult({
    this.id,
    required this.sessionId,
    required this.name,
    required this.lane,
    required this.totalTime,
    required this.splits,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'session_id': sessionId,
      'name': name,
      'lane': lane,
      'total_time': totalTime,
      'splits': splits.join(','), // Guardamos los parciales como texto
    };
  }
}