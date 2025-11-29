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
  String smartSummary = '';
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadGroupedNotifications();
  }

  void _loadGroupedNotifications() {
    groupedByDate = _notificationService.groupByDate();
    setState(() {});
  }

  /// 🔹 Generate AI summary via Ollama
  Future<void> _generateAISummary() async {
    setState(() => isLoading = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('🤖 Generating AI summary...')),
    );

    final summary = await _summarizerService.generateAISummary();

    setState(() {
      smartSummary = summary;
      isLoading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✅ AI summary ready!')),
    );
  }

  /// 🔹 Fallback local summary if AI not available
  Future<void> _generateLocalSummary() async {
    final summary = await _summarizerService.generateLocalSummary();
    setState(() {
      smartSummary = summary;
    });
  }

  String _generateAppSummary(List<Map<String, dynamic>> notifications) {
    final appCounts = <String, int>{};
    for (var n in notifications) {
      final app = n['package'] ?? 'unknown';
      appCounts[app] = (appCounts[app] ?? 0) + 1;
    }
    return appCounts.entries
        .map((e) => "${e.key.split('.').last}: ${e.value} alerts")
        .join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final dates = groupedByDate.keys.toList()..sort((a, b) => b.compareTo(a));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Digest'),
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome),
            tooltip: 'Generate AI Summary',
            onPressed: isLoading ? null : _generateAISummary,
          ),
          IconButton(
            icon: const Icon(Icons.offline_bolt),
            tooltip: 'Generate Local Summary',
            onPressed: isLoading ? null : _generateLocalSummary,
          ),
        ],
      ),
      body: dates.isEmpty
          ? const Center(
              child: Text(
                'No notifications yet.\nCome back later!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
            )
          : Column(
              children: [
                if (isLoading)
                  const LinearProgressIndicator(
                    color: Colors.deepPurple,
                    minHeight: 3,
                  ),
                if (smartSummary.isNotEmpty)
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Card(
                      elevation: 3,
                      color: Colors.deepPurple.shade50,
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
                                smartSummary,
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
                    itemBuilder: (context, i) {
                      final date = dates[i];
                      final notes = groupedByDate[date] ?? [];
                      return Card(
                        margin: const EdgeInsets.all(8),
                        child: ExpansionTile(
                          title: Text(
                            DateFormat('EEE, MMM d')
                                .format(DateTime.parse(date)),
                            style:
                                const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text('${notes.length} notifications'),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(_generateAppSummary(notes)),
                            ),
                            TextButton.icon(
                              onPressed: isLoading ? null : _generateAISummary,
                              icon: const Icon(Icons.smart_toy_outlined),
                              label: const Text('Smart Summarize (AI)'),
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
