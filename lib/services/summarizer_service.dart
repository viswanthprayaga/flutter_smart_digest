import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/notification_service.dart';

class SummarizerService {
  final NotificationService _notificationService = NotificationService();

  /// Lightweight fallback summary (no AI / offline)
  Future<String> generateLocalSummary() async {
    final grouped = _notificationService.groupByDate();
    if (grouped.isEmpty) return "No notifications to summarize.";

    // Use latest date group (most recent)
    final sortedKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));
    final todayKey = sortedKeys.first;
    final todayNotes = grouped[todayKey] ?? [];

    final total = todayNotes.length;
    final appSet = todayNotes.map((n) => n['package'] ?? '').toSet();
    final apps = appSet.length;

    final appCounts = <String, int>{};
    for (var n in todayNotes) {
      final pkg = (n['package'] ?? 'unknown').toString();
      appCounts[pkg] = (appCounts[pkg] ?? 0) + 1;
    }

    final mostActiveApp = appCounts.isEmpty
        ? 'apps'
        : appCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key.split('.').last;

    return "You received $total notifications from $apps apps today. Mostly from $mostActiveApp.";
  }

  /// AI summary using local Ollama REST API
  /// Update the host if you use a real device (replace 127.0.0.1 with your laptop IP)
  Future<String> generateAISummary({String host = "192.168.1.1", int port = 11434, String model = "tinyllama"}) async {
    final grouped = _notificationService.groupByDate();
    if (grouped.isEmpty) return "No notifications to summarize.";

    final sortedKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));
    final todayKey = sortedKeys.first;
    final todayNotes = grouped[todayKey] ?? [];

    final textData = todayNotes.map((n) {
      final pkg = n['package'] ?? '';
      final title = n['title'] ?? '';
      final body = n['text'] ?? '';
      return "[$pkg] $title - $body";
    }).join("\n");

    final prompt = """
You are a helpful assistant. Summarize the following notifications for the user in 2-3 sentences.
Highlight offers, bank/payment alerts, and important reminders if present.
Be concise and user-friendly.

Notifications:
$textData
""";

    final uri = Uri.parse("http://$host:$port/api/generate");

    try {
      final response = await http.post(
        uri,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "model": model,
          "prompt": prompt,
        }),
      );

      if (response.statusCode != 200) {
        return "AI server error: ${response.statusCode}. Showing local summary:\n\n${await generateLocalSummary()}";
      }

      // Ollama streams newline-separated JSON objects — join response pieces
      final lines = response.body.split('\n');
      final buffer = StringBuffer();
      for (final line in lines) {
        if (line.trim().isEmpty) continue;
        try {
          final data = jsonDecode(line);
          if (data is Map && data['response'] != null) buffer.write(data['response']);
        } catch (_) {
          // ignore parse errors of partial lines
        }
      }

      final output = buffer.toString().trim();
      return output.isEmpty ? "AI returned empty response. ${await generateLocalSummary()}" : output;
    } catch (e) {
      // Network or other error — fallback to local summary
      return "Unable to reach AI service: $e\n\n${await generateLocalSummary()}";
    }
  }
}
