import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/notification_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _channel = EventChannel('smartdigest/notifications');
  final NotificationService _notificationService = NotificationService();

  List<Map<String, dynamic>> notifications = [];

  @override
  void initState() {
    super.initState();
    _initNotifications();
  }

  Future<void> _initNotifications() async {
    // Fetch existing notifications from Hive
    notifications = _notificationService.getAllNotifications();

    // Start listening for new ones
    _listenNotifications();

    setState(() {});
  }

  void _listenNotifications() {
    _channel.receiveBroadcastStream().listen((event) async {
      final data = Map<String, dynamic>.from(event);
      data['timestamp'] = DateTime.now().toIso8601String();

      await _notificationService.saveNotification(data);

      setState(() {
        notifications.insert(0, data); // 👈 newest first
      });

      debugPrint("📩 Notification received: $data");
    }, onError: (error) {
      debugPrint("❌ Error in EventChannel: $error");
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SmartDigest Notifications'),
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () async {
              await _notificationService.clearAll();
              setState(() {
                notifications.clear();
              });
            },
          ),
        ],
      ),
      body: notifications.isEmpty
          ? const Center(
              child: Text(
                'No notifications yet.\nSend yourself a message!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
            )
          : ListView.builder(
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final n = notifications[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: ListTile(
                    title: Text(
                      n['title'] ?? '(No title)',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '${n['text'] ?? ''}\n${n['package'] ?? ''}',
                    ),
                    isThreeLine: true,
                  ),
                );
              },
            ),
    );
  }
}
