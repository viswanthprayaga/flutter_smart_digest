import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/notification_service.dart';
import '../services/summarizer_service.dart';

class DigestScreen extends StatefulWidget {
  const DigestScreen({super.key});

  @override
  State<DigestScreen> createState() => _DigestScreenState();
}

class _DigestScreenState extends State<DigestScreen> {
  final NotificationService _notificationService = NotificationService();
  final SummarizerService _summarizerService = SummarizerService();

  Map<String, List<Map<String, dynamic>>> groupedByDate = {};
  String globalSmartSummary = '';

  String? activeDateLoading; // Which date is currently loading?

  @override
  void initState() {
    super.initState();
    _loadGroupedNotifications();
  }

  void _loadGroupedNotifications() {
    groupedByDate = _notificationService.groupByDate();
    setState(() {});
  }

  /// 🔥 Generate AI summary for a specific date
  Future<void> _generateAISummaryForDate(String date) async {
    setState(() => activeDateLoading = date);

    final notes = groupedByDate[date] ?? [];
    final allText = notes
        .map((n) => "[${n['package']}] ${n['title']} - ${n['text']}")
        .join("\n");

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("🤖 Summarizing notifications for $date..."),
      ),
    );

    final summary = await _summarizerService.generateAISummary();

    setState(() {
      globalSmartSummary = summary;
      activeDateLoading = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("✅ AI summary ready!")),
    );
  }

  /// 🟡 Offline fallback summary
  Future<void> _generateLocalSummary() async {
    final summary = await _summarizerService.generateLocalSummary();
    setState(() {
      globalSmartSummary = summary;
    });
  }

  /// Small per-date summary of app counts
  String _generateAppSummary(List<Map<String, dynamic>> notifications) {
    final appCounts = <String, int>{};
    for (var n in notifications) {
      final app = n['package'] ?? 'unknown';
      appCounts[app] = (appCounts[app] ?? 0) + 1;
    }

    return appCounts.entries
        .map((e) => "${e.key.split('.').last}: ${e.value}")
        .join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final dates = groupedByDate.keys.toList()
      ..sort((a, b) => b.compareTo(a)); // newest first

    return Scaffold(
      appBar: AppBar(
        title: const Text("Smart Digest"),
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
            icon: const Icon(Icons.offline_bolt),
            tooltip: "Offline Summary",
            onPressed: _generateLocalSummary,
          ),
        ],
      ),

      body: dates.isEmpty
          ? const Center(
              child: Text(
                "No notifications yet.\nCome back later!",
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
            )
          : Column(
              children: [
                /// GLOBAL SMART SUMMARY CARD
                if (globalSmartSummary.isNotEmpty)
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Card(
                      color: Colors.deepPurple.shade50,
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.auto_awesome,
                                color: Colors.deepPurple),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                globalSmartSummary,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                Expanded(
                  child: ListView.builder(
                    itemCount: dates.length,
                    itemBuilder: (context, index) {
                      final date = dates[index];
                      final notes = groupedByDate[date] ?? [];

                      return Card(
                        margin: const EdgeInsets.all(8),
                        child: ExpansionTile(
                          title: Text(
                            DateFormat("EEE, MMM d").format(
                              DateTime.parse(date),
                            ),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                              "${notes.length} notifications • ${_generateAppSummary(notes)}"),

                          children: [
                            if (activeDateLoading == date)
                              const Padding(
                                padding: EdgeInsets.all(8.0),
                                child: LinearProgressIndicator(
                                  color: Colors.deepPurple,
                                  minHeight: 3,
                                ),
                              ),

                            TextButton.icon(
                              onPressed: activeDateLoading != null
                                  ? null
                                  : () => _generateAISummaryForDate(date),
                              icon: const Icon(Icons.smart_toy_outlined),
                              label: const Text("Summarize with AI"),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
