import 'package:hive/hive.dart';
import 'package:intl/intl.dart';

class NotificationService {
  final Box _box = Hive.box('notifications');

  // Save new notification
  Future<void> saveNotification(Map<String, dynamic> data) async {
    data['timestamp'] ??= DateTime.now().toIso8601String();
    await _box.add(data);
  }

  // Get all notifications (newest first)
  List<Map<String, dynamic>> getAllNotifications() {
    final values = List<Map<String, dynamic>>.from(_box.values);
    values.sort((a, b) {
      final ta = DateTime.tryParse(a['timestamp'] ?? '') ?? DateTime.now();
      final tb = DateTime.tryParse(b['timestamp'] ?? '') ?? DateTime.now();
      return tb.compareTo(ta);
    });
    return values;
  }

  // Group notifications by date
  Map<String, List<Map<String, dynamic>>> groupByDate() {
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (var item in _box.values) {
      final map = Map<String, dynamic>.from(item);
      final ts = DateTime.tryParse(map['timestamp'] ?? '') ?? DateTime.now();
      final dateKey = DateFormat('yyyy-MM-dd').format(ts);
      grouped.putIfAbsent(dateKey, () => []).add(map);
    }
    return grouped;
  }

  // Get total count + unique app count
  Map<String, int> getStats() {
    final total = _box.length;
    final apps = _box.values
        .map((e) => (e as Map)['package'] ?? '')
        .toSet()
        .length;
    return {'total': total, 'apps': apps};
  }

  // Delete all notifications
  Future<void> clearAll() async => await _box.clear();
}
