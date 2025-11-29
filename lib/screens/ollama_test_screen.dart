import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class OllamaTestScreen extends StatefulWidget {
  const OllamaTestScreen({super.key});

  @override
  State<OllamaTestScreen> createState() => _OllamaTestScreenState();
}

class _OllamaTestScreenState extends State<OllamaTestScreen> {
  String _response = '';
  bool _isLoading = false;

  // 👇 Replace this with your laptop’s local IP
  final String ollamaHost = "192.168.1.1";  // Example
  final int ollamaPort = 11434;

  Future<void> _pingOllama() async {
    setState(() {
      _isLoading = true;
      _response = '';
    });

    final prompt = "Say hello! I’m testing the Ollama connection from my phone.";

    try {
      final url = Uri.parse("http://$ollamaHost:$ollamaPort/api/generate");
      final res = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "model": "tinyllama",  // You can use mistral, phi3, etc. if downloaded
          "prompt": prompt
        }),
      );

      if (res.statusCode == 200) {
        final lines = res.body.split('\n');
        final buffer = StringBuffer();

        for (final line in lines) {
          if (line.trim().isEmpty) continue;
          try {
            final data = jsonDecode(line);
            if (data['response'] != null) buffer.write(data['response']);
          } catch (_) {
            // Ignore partial JSON lines
          }
        }

        setState(() {
          _response = buffer.toString().trim();
        });
      } else {
        setState(() {
          _response =
              "❌ Ollama returned error ${res.statusCode}\n${res.body}";
        });
      }
    } catch (e) {
      setState(() {
        _response = "⚠️ Failed to reach Ollama: $e";
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Ping Ollama Test"),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              "Tap below to test if your phone can connect to your laptop’s Ollama API.",
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              icon: const Icon(Icons.wifi_tethering),
              label: const Text("Ping Ollama"),
              onPressed: _isLoading ? null : _pingOllama,
            ),
            const SizedBox(height: 30),
            if (_isLoading)
              const CircularProgressIndicator(color: Colors.deepPurple),
            if (_response.isNotEmpty)
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Text(
                      _response,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
