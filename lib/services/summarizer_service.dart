import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/notification_service.dart';

class SummarizerService {
  final NotificationService _notificationService = NotificationService();

  /// ---------------------------------------------------------------------------
  /// 🔹 OFFLINE SUMMARY (fallback if AI unreachable)
  /// ---------------------------------------------------------------------------
  Future<String> generateLocalSummary() async {
    final grouped = _notificationService.groupByDate();
    if (grouped.isEmpty) return "No notifications to summarize.";

    final sortedKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));
    final latestDateKey = sortedKeys.first;
    final notes = grouped[latestDateKey] ?? [];

    final total = notes.length;
    final uniqueApps = notes.map((n) => n['package'] ?? '').toSet().length;

    final appCounts = <String, int>{};
    for (var n in notes) {
      final pkg = (n['package'] ?? 'unknown').toString();
      appCounts[pkg] = (appCounts[pkg] ?? 0) + 1;
    }

    final mostActiveApp = appCounts.entries.isEmpty
        ? "apps"
        : appCounts.entries.reduce((a, b) => a.value > b.value ? a : b)
            .key
            .split('.')
            .last;

    return "You received $total notifications from $uniqueApps apps today. "
           "Most frequent updates were from $mostActiveApp.";
  }

  /// ---------------------------------------------------------------------------
  /// 🔥 AI SUMMARY — using Ollama running on your laptop
  ///
  /// - If `customText` is provided → summarize *that text only*
  /// - If not → summarize “today” from Hive
  /// ---------------------------------------------------------------------------
  Future<String> generateAISummary({
    String? customText,
    String host = "192.168.1.9",
    int port = 11434,
    String model = "tinyllama",
  }) async {

    // ------------------------------------------------------------------------
    // If customText is provided (for a selected date in DigestScreen)
    // ------------------------------------------------------------------------
    String textData = "";

    if (customText != null) {
      textData = customText.trim();
      if (textData.isEmpty) {
        return "No notification text found for this date.";
      }
    } else {
      // ----------------------------------------------------------------------
      // Default mode — summarize the *latest* day
      // ----------------------------------------------------------------------
      final grouped = _notificationService.groupByDate();
      if (grouped.isEmpty) return "No notifications to summarize.";

      final sortedKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));
      final latestDateKey = sortedKeys.first;
      final todayNotes = grouped[latestDateKey] ?? [];

      textData = todayNotes.map((n) {
        final pkg = n['package'] ?? '';
        final title = n['title'] ?? '';
        final body = n['text'] ?? '';
        return "[$pkg] $title - $body";
      }).join("\n");
    }

    // ------------------------------------------------------------------------
    // Prompt sent to the model
    // ------------------------------------------------------------------------
    final prompt = """
You are SmartDigest AI.

Summarize the following notifications into 2–4 short, clear sentences.
Highlight:
- Offers / discounts
- Bank or payment alerts
- OTPs
- Important reminders
- Delivery or app updates

Keep the summary simple, helpful, and friendly.

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
        return "AI server error (${response.statusCode}).\n\nFallback:\n${await generateLocalSummary()}";
      }

      // ----------------------------------------------------------------------
      // Ollama returns streaming JSON lines → combine them
      // ----------------------------------------------------------------------
      final lines = response.body.split('\n');
      final buffer = StringBuffer();

      for (final line in lines) {
        if (line.trim().isEmpty) continue;
        try {
          final json = jsonDecode(line);
          if (json["response"] != null) {
            buffer.write(json["response"]);
          }
        } catch (_) {
          // ignore invalid fragments
        }
      }

      final output = buffer.toString().trim();
      return output.isEmpty
          ? "AI returned no output.\n\n${await generateLocalSummary()}"
          : output;

    } catch (e) {
      return "Unable to reach AI service: $e\n\n${await generateLocalSummary()}";
    }
  }
}
