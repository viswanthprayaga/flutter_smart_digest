import 'package:flutter/material.dart';
import 'ui/home_screen.dart';
import 'ui/digest_screen.dart';
import 'screens/ollama_test_screen.dart';


void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: OllamaTestScreen(),
  ));
}


class SmartDigestApp extends StatefulWidget {
  const SmartDigestApp({super.key});

  @override
  State<SmartDigestApp> createState() => _SmartDigestAppState();
}

class _SmartDigestAppState extends State<SmartDigestApp> {
  int _currentIndex = 0;
  final _pages = const [HomeScreen(), DigestScreen()];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SmartDigest',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.deepPurple),
      home: Scaffold(
        body: _pages[_currentIndex],
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
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
      ),
    );
  }
}
