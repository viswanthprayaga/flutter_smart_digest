import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'ui/home_screen.dart';
import 'ui/digest_screen.dart';
import 'screens/ollama_test_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ------------------------------------------------------------
  // 🔥 1. Initialize Hive BEFORE running the app
  // ------------------------------------------------------------
  await Hive.initFlutter();

  // ------------------------------------------------------------
  // 🔥 2. Open notifications box ONCE (shared by all screens)
  // ------------------------------------------------------------
  await Hive.openBox('notifications');

  // ------------------------------------------------------------
  // 🔥 3. Now run the real app
  // ------------------------------------------------------------
  runApp(const SmartDigestApp());
}

class SmartDigestApp extends StatefulWidget {
  const SmartDigestApp({super.key});

  @override
  State<SmartDigestApp> createState() => _SmartDigestAppState();
}

class _SmartDigestAppState extends State<SmartDigestApp> {
  int _currentIndex = 0;

  // MAIN APP PAGES
  final _pages = const [
    HomeScreen(),
    DigestScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SmartDigest',
      debugShowCheckedModeBanner: false,

      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.deepPurple,
          elevation: 1,
        ),
      ),

      home: Scaffold(
        body: _pages[_currentIndex],

        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          selectedItemColor: Colors.deepPurple,
          unselectedItemColor: Colors.grey,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.notifications),
              label: 'Notifications',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.list_alt),
              label: 'Digest',
            ),
          ],
        ),

        // Optional debugging tool (keep or remove)
        floatingActionButton: FloatingActionButton(
          backgroundColor: Colors.deepPurple,
          tooltip: "Test AI Connection",
          child: const Icon(Icons.bug_report),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const OllamaTestScreen(),
              ),
            );
          },
        ),
      ),
    );
  }
}
