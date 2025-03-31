class DietLog {
  final int userId;
  final DateTime timestamp;
  final String foodDescription;
  final int calories;
  final String nutrients;

  DietLog({required this.userId, required this.timestamp, required this.foodDescription, required this.calories, required this.nutrients});

  factory DietLog.fromJson(Map<String, dynamic> json) {
    return DietLog(
      userId: json['userId'],
      timestamp: DateTime.parse(json['timestamp']),
      foodDescription: json['foodDescription'],
      calories: json['calories'],
      nutrients: json['nutrients'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'timestamp': timestamp.toIso8601String(),
      'foodDescription': foodDescription,
      'calories': calories,
      'nutrients': nutrients,
    };
  }
}
