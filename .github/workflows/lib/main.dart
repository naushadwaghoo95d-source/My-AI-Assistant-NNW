import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

void main() {
  runApp(const AssistantApp());
}

class AssistantApp extends StatelessWidget {
  const AssistantApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF121212),
        primaryColor: Colors.deepPurpleAccent,
      ),
      home: const AssistantScreen(),
    );
  }
}

class AssistantScreen extends StatefulWidget {
  const AssistantScreen({super.key});

  @override
  State<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends State<AssistantScreen> {
  final TextEditingController _controller = TextEditingController();
  final FlutterTts _flutterTts = FlutterTts();
  late stt.SpeechToText _speech;

  bool _isListening = false;
  bool _isLoading = false;
  String _assistantReply = "नमस्ते! मैं आपकी क्या मदद कर सकता हूँ?";
  String _selectedGender = "female";

  // डेमो रिस्पॉन्स एंडपॉइंट (या आपका लाइव बैकएंड सर्वर)
  final String _backendUrl = 'https://httpbin.org/post';

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _initTts();
  }

  void _initTts() async {
    await _flutterTts.setLanguage("hi-IN");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setPitch(_selectedGender == "female" ? 1.2 : 0.9);
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
      _assistantReply = "सोच रहा हूँ...";
    });
    _controller.clear();

    try {
      final response = await http.post(
        Uri.parse(_backendUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': 'user_123',
          'message': text,
          'character_gender': _selectedGender,
        }),
      );

      if (response.statusCode == 200) {
        String reply = "मैंने आपकी बात सुन ली: '$text'";
        setState(() {
          _assistantReply = reply;
        });
        await _flutterTts.speak(reply);
      } else {
        setState(() {
          _assistantReply = "सर्वर से कनेक्ट नहीं हो सका!";
        });
      }
    } catch (e) {
      setState(() {
        _assistantReply = "एरर: $e";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _toggleListening() async {
    if (!_isListening) {
      bool available = await _speech.initialize();
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) {
            if (val.finalResult) {
              _sendMessage(val.recognizedWords);
              setState(() => _isListening = false);
            }
          },
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Personal AI Assistant"),
        centerTitle: true,
        actions: [
          DropdownButton<String>(
            value: _selectedGender,
            underline: const SizedBox(),
            items: const [
              DropdownMenuItem(value: "female", child: Text("Female 👩")),
              DropdownMenuItem(value: "male", child: Text("Male 👨")),
            ],
            onChanged: (val) {
              if (val != null) {
                setState(() => _selectedGender = val);
                _initTts();
              }
            },
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 30),
          CircleAvatar(
            radius: 75,
            backgroundColor: Colors.deepPurpleAccent.withOpacity(0.3),
            child: Icon(
              _selectedGender == "female" ? Icons.face_3 : Icons.face,
              size: 90,
              color: Colors.deepPurpleAccent,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Center(
                child: SingleChildScrollView(
                  child: Text(
                    _assistantReply,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 18, height: 1.5),
                  ),
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(_isListening ? Icons.mic : Icons.mic_none),
                  color: _isListening ? Colors.redAccent : Colors.white70,
                  onPressed: _toggleListening,
                ),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: "कुछ बोलें या लिखें...",
                      border: InputBorder.none,
                    ),
                    onSubmitted: (text) => _sendMessage(text),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.deepPurpleAccent),
                  onPressed: _isLoading ? null : () => _sendMessage(_controller.text),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
