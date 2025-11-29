import 'package:hive/hive.dart';
import 'package:intl/intl.dart';

class NotificationService {
  // Box is opened in main.dart (important!)
  Box get _box => Hive.box('notifications');

  /// Save new notification safely
  Future<void> saveNotification(Map<String, dynamic> data) async {
    data['timestamp'] ??= DateTime.now().toIso8601String();
    await _box.add(data);
  }

  /// Get notifications sorted by time (newest first)
  List<Map<String, dynamic>> getAllNotifications() {
    final List<Map<String, dynamic>> values = _box.values
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    values.sort((a, b) {
      final ta = DateTime.tryParse(a['timestamp'] ?? '') ?? DateTime(2000);
      final tb = DateTime.tryParse(b['timestamp'] ?? '') ?? DateTime(2000);
      return tb.compareTo(ta);
    });

    return values;
  }

  /// Group notifications by date ("yyyy-MM-dd")
  Map<String, List<Map<String, dynamic>>> groupByDate() {
    final Map<String, List<Map<String, dynamic>>> grouped = {};

    for (var item in _box.values) {
      final map = Map<String, dynamic>.from(item);

      final ts = DateTime.tryParse(map['timestamp'] ?? '') ?? DateTime.now();
      final dateKey = DateFormat('yyyy-MM-dd').format(ts);

      grouped.putIfAbsent(dateKey, () => []);
      grouped[dateKey]!.add(map);
    }

    return grouped;
  }

  /// Count total notifications & number of unique apps
  Map<String, int> getStats() {
    final total = _box.length;

    final apps = _box.values
        .map((e) => (e as Map)['package'] ?? '')
        .toSet()
        .length;

    return {
      'total': total,
      'apps': apps,
    };
  }

  /// Delete all notifications
  Future<void> clearAll() async {
    await _box.clear();
  }
}
