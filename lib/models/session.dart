class Session {
  final int? id;
  final String date;
  final String distance;

  Session({this.id, required this.date, required this.distance});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'distance': distance,
    };
  }

  factory Session.fromMap(Map<String, dynamic> map) {
    return Session(
      id: map['id'],
      date: map['date'],
      distance: map['distance'],
    );
  }

}