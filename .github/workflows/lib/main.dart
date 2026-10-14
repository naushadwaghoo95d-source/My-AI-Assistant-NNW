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
        scaffoldBackgroundColor: const Color(0xFF0D0E15),
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

class _AssistantScreenState extends State<AssistantScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final FlutterTts _flutterTts = FlutterTts();
  late stt.SpeechToText _speech;

  late AnimationController _animController;
  late Animation<double> _glowAnimation;

  bool _isListening = false;
  bool _isLoading = false;
  bool _isSpeaking = false;
  String _assistantReply = "नमस्ते! मैं आपकी पर्सनल AI असिस्टेंट हूँ। आज मैं आपकी क्या मदद करूँ?";
  String _selectedGender = "female";

  // AI Avatars (Online 3D Styled Render URLs)
  final String _femaleAvatarUrl =
      "https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?w=600&auto=format&fit=crop&q=80";
  final String _maleAvatarUrl =
      "https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=600&auto=format&fit=crop&q=80";

  final String _backendUrl = 'https://httpbin.org/post';

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 4.0, end: 18.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );

    _initTts();
  }

  void _initTts() async {
    await _flutterTts.setLanguage("hi-IN");
    await _flutterTts.setSpeechRate(0.48);
    await _flutterTts.setPitch(_selectedGender == "female" ? 1.25 : 0.85);

    _flutterTts.setStartHandler(() {
      setState(() => _isSpeaking = true);
    });

    _flutterTts.setCompletionHandler(() {
      setState(() => _isSpeaking = false);
    });
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
      _assistantReply = "सोच रही हूँ...";
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
        String reply = _selectedGender == "female"
            ? "जी, मैंने सुन लिया: '$text'। सब कुछ नोट कर लिया है!"
            : "हाँ दोस्त, मैंने समझ लिया: '$text'। सब कुछ सुरक्षित है!";

        setState(() {
          _assistantReply = reply;
        });

        await _flutterTts.speak(reply);
      } else {
        setState(() {
          _assistantReply = "सर्वर से संपर्क नहीं हो सका!";
        });
      }
    } catch (e) {
      setState(() {
        _assistantReply = "कनेक्शन में समस्या आई: $e";
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
  void dispose() {
    _animController.dispose();
    _controller.dispose();
    _flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Color accentColor = _selectedGender == "female"
        ? const Color(0xFF00E5FF)
        : const Color(0xFF7C4DFF);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0, -0.4),
            radius: 1.2,
            colors: [
              accentColor.withOpacity(0.18),
              const Color(0xFF090A10),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: Colors.greenAccent,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.greenAccent.withOpacity(0.6),
                                blurRadius: 6,
                              )
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          "AI CORE ONLINE",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                    // Gender Selector Pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: DropdownButton<String>(
                        value: _selectedGender,
                        dropdownColor: const Color(0xFF1A1C29),
                        underline: const SizedBox(),
                        icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white70),
                        items: const [
                          DropdownMenuItem(
                            value: "female",
                            child: Text("Female AI 👩", style: TextStyle(color: Colors.white)),
                          ),
                          DropdownMenuItem(
                            value: "male",
                            child: Text("Male AI 👨", style: TextStyle(color: Colors.white)),
                          ),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedGender = val);
                            _initTts();
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Glowing Animated 3D Avatar
              AnimatedBuilder(
                animation: _glowAnimation,
                builder: (context, child) {
                  return Container(
                    width: 220,
                    height: 220,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: accentColor.withOpacity(_isSpeaking ? 0.8 : 0.35),
                          blurRadius: _isSpeaking ? 35 : _glowAnimation.value,
                          spreadRadius: _isSpeaking ? 8 : 2,
                        ),
                      ],
                      border: Border.all(
                        color: _isSpeaking ? Colors.white : accentColor.withOpacity(0.8),
                        width: _isSpeaking ? 3 : 2,
                      ),
                    ),
                    child: ClipOval(
                      child: Container(
                        color: Colors.black,
                        child: Center(
                          child: Icon(
                            _selectedGender == "female"
                                ? Icons.support_agent_rounded
                                : Icons.smart_toy_rounded,
                            size: 110,
                            color: accentColor,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 20),

              // Status indicator
              Text(
                _isSpeaking
                    ? "🗣️ Speaking..."
                    : (_isListening ? "🎙️ Listening to you..." : "⚡ Ready"),
                style: TextStyle(
                  color: accentColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  letterSpacing: 1.1,
                ),
              ),

              const Spacer(),

              // Dialog / Conversation Card
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
                decoration: BoxDecoration(
                  color: const Color(0xFF151724).withOpacity(0.9),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.4),
                      blurRadius: 15,
                    ),
                  ],
                ),
                child: Text(
                  _assistantReply,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.5,
                    color: Colors.white,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Bottom Input Bar & Futuristic Mic Button
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF151724),
                  borderRadius: BorderRadius.circular(35),
                  border: Border.all(color: Colors.white.withOpacity(0.12)),
                ),
                child: Row(
                  children: [
                    // Glowing Mic Button
                    GestureDetector(
                      onTap: _toggleListening,
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _isListening ? Colors.redAccent : accentColor,
                          boxShadow: [
                            BoxShadow(
                              color: (_isListening ? Colors.redAccent : accentColor)
                                  .withOpacity(0.5),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: Icon(
                          _isListening ? Icons.mic : Icons.mic_none,
                          color: Colors.black,
                          size: 26,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: "Say or type something...",
                          hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
                          border: InputBorder.none,
                        ),
                        onSubmitted: (text) => _sendMessage(text),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.arrow_upward_rounded, color: accentColor),
                      onPressed: _isLoading ? null : () => _sendMessage(_controller.text),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
