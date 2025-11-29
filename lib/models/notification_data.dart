import 'package:hive/hive.dart';



@HiveType(typeId: 0)
class NotificationData {
  @HiveField(0)
  final String package;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String text;

  @HiveField(3)
  final DateTime timestamp;

  NotificationData({
    required this.package,
    required this.title,
    required this.text,
    required this.timestamp,
  });

  factory NotificationData.fromMap(Map<dynamic, dynamic> map) {
    return NotificationData(
      package: map['package'] ?? '',
      title: map['title'] ?? '',
      text: map['text'] ?? '',
      timestamp: DateTime.tryParse(map['timestamp'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'package': package,
      'title': title,
      'text': text,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
