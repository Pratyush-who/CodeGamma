// Voice Chat Page with Gemini AI Integration
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../core/constants/app_colors.dart';
import 'package:codegamma_sih/core/models/cow_details.dart';

class VoiceChatPage extends StatefulWidget {
  final String tagId;
  final String geminiApiKey;
  final CowDetails? cowDetails;

  const VoiceChatPage({
    super.key,
    required this.tagId,
    required this.geminiApiKey,
    this.cowDetails,
  });

  @override
  State<VoiceChatPage> createState() => _VoiceChatPageState();
}

class _VoiceChatPageState extends State<VoiceChatPage>
    with TickerProviderStateMixin {
  late stt.SpeechToText _speech;
  late FlutterTts _flutterTts;

  bool _isListening = false;
  bool _isInitialized = false;
  bool _isSpeaking = false;
  bool _isProcessing = false;
  String _currentText = '';

  List<ChatMessage> _messages = [];
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Dynamic context (model based if provided)
  String get cowContext =>
      widget.cowDetails?.buildContextPrompt() ??
      'You are an AI assistant for dairy cow management. Cow Tag ID: ${widget.tagId}. Limited data provided; ask clarifying questions if needed before giving critical advice.';

  // Continuous listening configuration
  static const Duration maxSessionDuration = Duration(minutes: 10);
  static const Duration silenceTimeout = Duration(
    seconds: 7,
  ); // auto send after silence
  static const Duration autoRestartDelay = Duration(milliseconds: 600);
  DateTime? _lastSpeechUpdate;
  bool _pendingSend = false;

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _setupAnimations();
  }

  void _setupAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _pulseController.repeat(reverse: true);
  }

  Future<void> _initializeServices() async {
    await _requestPermissions();
    await _initializeSpeechToText();
    await _initializeTextToSpeech();
  }

  Future<void> _requestPermissions() async {
    await Permission.microphone.request();
    await Permission.speech.request();
  }

  Future<void> _initializeSpeechToText() async {
    _speech = stt.SpeechToText();
    bool available = await _speech.initialize(
      onError: (error) {
        setState(() {
          _isListening = false;
        });
        _showError('Speech recognition error: ${error.errorMsg}');
      },
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          setState(() {
            _isListening = false;
          });
        }
      },
    );

    setState(() {
      _isInitialized = available;
    });

    if (!available) {
      _showError('Speech recognition not available');
    }
  }

  Future<void> _initializeTextToSpeech() async {
    _flutterTts = FlutterTts();

    // Get available languages and engines
    List<dynamic> languages = await _flutterTts.getLanguages;
    List<dynamic> engines = await _flutterTts.getEngines;
    print('Available TTS languages: $languages');
    print('Available TTS engines: $engines');

    // Set default language and voice settings
    await _flutterTts.setLanguage('en-US');
    await _flutterTts.setSpeechRate(0.5); // Slower speech rate for clarity
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);

    // Set voice if available
    if (engines.isNotEmpty) {
      await _flutterTts.setEngine(engines[0]);
    }

    _flutterTts.setStartHandler(() {
      print('TTS started speaking');
      setState(() {
        _isSpeaking = true;
      });
    });

    _flutterTts.setCompletionHandler(() {
      print('TTS completed speaking');
      setState(() {
        _isSpeaking = false;
      });
    });

    _flutterTts.setProgressHandler((
      String text,
      int startOffset,
      int endOffset,
      String word,
    ) {
      print('TTS progress: $word');
    });

    _flutterTts.setErrorHandler((msg) {
      print('TTS error: $msg');
      setState(() {
        _isSpeaking = false;
      });
      _showError('Text-to-speech error: $msg');
    });

    _flutterTts.setCancelHandler(() {
      print('TTS cancelled');
      setState(() {
        _isSpeaking = false;
      });
    });

    _flutterTts.setPauseHandler(() {
      print('TTS paused');
    });

    _flutterTts.setContinueHandler(() {
      print('TTS continued');
    });
  }

  Future<void> _startListening() async {
    if (!_isInitialized || _isProcessing || _isSpeaking) return;

    setState(() {
      _isListening = true;
      if (!_pendingSend) _currentText = '';
    });

    await _speech.listen(
      onResult: (result) {
        _lastSpeechUpdate = DateTime.now();
        final recognized = result.recognizedWords.trim();
        setState(() {
          _currentText = recognized;
        });
        if (result.finalResult && recognized.isNotEmpty) {
          _scheduleAutoSend();
        }
      },
      listenFor: maxSessionDuration,
      pauseFor: silenceTimeout,
      partialResults: true,
      localeId: 'en_US',
      cancelOnError: false,
      listenMode: stt.ListenMode.dictation,
    );
    _monitorSilence();
  }

  void _scheduleAutoSend() {
    if (_pendingSend) return;
    _pendingSend = true;
    Future.delayed(const Duration(milliseconds: 400), () {
      if (!_isListening) return;
      _stopListening(auto: true);
    });
  }

  Future<void> _monitorSilence() async {
    while (_isListening && !_isProcessing) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (!_isListening) break;
      if (_lastSpeechUpdate != null) {
        final silence = DateTime.now().difference(_lastSpeechUpdate!);
        if (silence > silenceTimeout && _currentText.isNotEmpty) {
          _stopListening(auto: true);
          break;
        }
      }
    }
  }

  Future<void> _stopListening({bool auto = false}) async {
    await _speech.stop();
    setState(() {
      _isListening = false;
    });
    final text = _currentText.trim();
    if (text.isNotEmpty) {
      await _sendToGemini(text);
    } else if (!auto) {
      _showError('Did not catch anything, please try again.');
    }
    _pendingSend = false;
  }

  Future<void> _sendToGemini(String query) async {
    if (query.trim().isEmpty) return;

    setState(() {
      _isProcessing = true;
      _messages.add(
        ChatMessage(text: query, isUser: true, timestamp: DateTime.now()),
      );
    });

    try {
      print('Sending request to Gemini with query: $query'); // Debug log

      final response = await http.post(
        Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=${widget.geminiApiKey}',
        ),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': '$cowContext\n\nConversation input: $query'},
              ],
            },
          ],
          'generationConfig': {
            'temperature': 0.9,
            'topK': 1,
            'topP': 1,
            'maxOutputTokens': 2048,
            'stopSequences': [],
          },
          'safetySettings': [
            {
              'category': 'HARM_CATEGORY_HARASSMENT',
              'threshold': 'BLOCK_MEDIUM_AND_ABOVE',
            },
            {
              'category': 'HARM_CATEGORY_HATE_SPEECH',
              'threshold': 'BLOCK_MEDIUM_AND_ABOVE',
            },
            {
              'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT',
              'threshold': 'BLOCK_MEDIUM_AND_ABOVE',
            },
            {
              'category': 'HARM_CATEGORY_DANGEROUS_CONTENT',
              'threshold': 'BLOCK_MEDIUM_AND_ABOVE',
            },
          ],
        }),
      );

      print('Response status: ${response.statusCode}'); // Debug log
      print('Response body: ${response.body}'); // Debug log

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['candidates'] != null && data['candidates'].isNotEmpty) {
          final aiResponse =
              data['candidates'][0]['content']['parts'][0]['text'];

          setState(() {
            _messages.add(
              ChatMessage(
                text: aiResponse,
                isUser: false,
                timestamp: DateTime.now(),
              ),
            );
          });

          print('AI Response: $aiResponse'); // Debug log
          await _speakResponse(aiResponse);
        } else {
          throw Exception('No response from Gemini AI');
        }
      } else {
        print('Error response: ${response.body}');
        throw Exception(
          'Failed to get response from Gemini: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('Error in _sendToGemini: $e'); // Debug log
      final errorMessage = 'Sorry, I encountered an error: $e';
      setState(() {
        _messages.add(
          ChatMessage(
            text: errorMessage,
            isUser: false,
            timestamp: DateTime.now(),
          ),
        );
      });
      await _speakResponse(errorMessage);
    } finally {
      setState(() {
        _isProcessing = false;
        _currentText = '';
      });
      // Auto-restart listening for continuous conversation
      Future.delayed(autoRestartDelay, () {
        if (mounted) _startListening();
      });
    }
  }

  Future<void> _speakResponse(String text) async {
    if (text.trim().isEmpty) return;

    print(
      'Starting TTS for text: ${text.substring(0, text.length > 50 ? 50 : text.length)}...',
    );

    // Stop any ongoing speech
    await _flutterTts.stop();

    // Auto-detect language and set appropriate TTS language
    await _detectAndSetLanguage(text);

    // Speak the text
    try {
      final result = await _flutterTts.speak(text);
      print('TTS speak result: $result');

      if (result == 0) {
        print('TTS failed to start');
        _showError('Failed to start text-to-speech');
      }
    } catch (e) {
      print('TTS speak error: $e');
      _showError('Text-to-speech error: $e');
    }
  }

  Future<void> _detectAndSetLanguage(String text) async {
    try {
      // Simple language detection based on script
      if (RegExp(r'[\u0900-\u097F]').hasMatch(text)) {
        // Hindi/Devanagari script
        print('Detected Hindi text, setting TTS to hi-IN');
        await _flutterTts.setLanguage('hi-IN');
      } else if (RegExp(r'[\u0980-\u09FF]').hasMatch(text)) {
        // Bengali script
        print('Detected Bengali text, setting TTS to bn-IN');
        await _flutterTts.setLanguage('bn-IN');
      } else if (RegExp(r'[\u0A00-\u0A7F]').hasMatch(text)) {
        // Punjabi script
        print('Detected Punjabi text, setting TTS to pa-IN');
        await _flutterTts.setLanguage('pa-IN');
      } else {
        // Default to English
        print('Detected English text, setting TTS to en-US');
        await _flutterTts.setLanguage('en-US');
      }
    } catch (e) {
      print('Language detection error: $e');
      // Fallback to English
      await _flutterTts.setLanguage('en-US');
    }
  }

  Future<void> _stopSpeaking() async {
    await _flutterTts.stop();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primaryColor, AppColors.primaryColorLight],
            ),
          ),
        ),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          ' ${widget.tagId}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          if (_isSpeaking)
            IconButton(
              icon: const Icon(Icons.stop, color: Colors.white),
              onPressed: _stopSpeaking,
            ),
        ],
      ),
      body: Column(
        children: [
          // Chat Messages
          Expanded(
            child: _messages.isEmpty ? _buildWelcomeScreen() : _buildChatList(),
          ),

          // Voice Input Section
          _buildVoiceInputSection(),
        ],
      ),
    );
  }

  Widget _buildWelcomeScreen() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.mic, size: 64, color: AppColors.primaryColor),
          ),
          const SizedBox(height: 24),
          Text(
            'Ask me anything about cow ${widget.tagId}',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryTextColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Tap the microphone button and speak your question. I can help with health information, treatment history, milk safety, and farming advice.',
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.secondaryTextColor,
            ),
            textAlign: TextAlign.center,
          ),
          if (!_isInitialized)
            const Padding(
              padding: EdgeInsets.only(top: 16),
              child: Text(
                'Initializing voice services...',
                style: TextStyle(color: Colors.orange, fontSize: 14),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildChatList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        return _buildMessageBubble(message);
      },
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: message.isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: AppColors.primaryColor,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.smart_toy, color: Colors.white, size: 18),
            ),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: message.isUser
                    ? AppColors.primaryColor
                    : AppColors.surfaceColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  color: message.isUser
                      ? Colors.white
                      : AppColors.primaryTextColor,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          if (message.isUser) ...[
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(left: 8),
              decoration: BoxDecoration(
                color: AppColors.accentGreen,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person, color: Colors.white, size: 18),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVoiceInputSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Current text display
          if (_currentText.isNotEmpty || _isProcessing)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.backgroundColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primaryColor.withOpacity(0.3),
                ),
              ),
              child: Text(
                _isProcessing ? 'Processing your question...' : _currentText,
                style: TextStyle(
                  color: AppColors.primaryTextColor,
                  fontSize: 14,
                  fontStyle: _isProcessing
                      ? FontStyle.italic
                      : FontStyle.normal,
                ),
              ),
            ),

          // Voice button and status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Manual stop listening button (only shown when listening)
              if (_isListening)
                GestureDetector(
                  onTap: () => _stopListening(auto: false),
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withOpacity(0.3),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.stop,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),

              // Voice input button
              GestureDetector(
                onTap: _isInitialized && !_isProcessing
                    ? (_isListening
                          ? () => _stopListening(auto: false)
                          : _startListening)
                    : null,
                child: AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _isListening ? _pulseAnimation.value : 1.0,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: _isListening
                                ? [Colors.red, Colors.red.withOpacity(0.8)]
                                : _isProcessing
                                ? [
                                    Colors.orange,
                                    Colors.orange.withOpacity(0.8),
                                  ]
                                : [
                                    AppColors.primaryColor,
                                    AppColors.primaryColorLight,
                                  ],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color:
                                  (_isListening
                                          ? Colors.red
                                          : AppColors.primaryColor)
                                      .withOpacity(0.3),
                              blurRadius: 15,
                              spreadRadius: _isListening ? 5 : 0,
                            ),
                          ],
                        ),
                        child: Icon(
                          _isListening
                              ? Icons.mic
                              : _isProcessing
                              ? Icons.hourglass_empty
                              : Icons.mic,
                          color: Colors.white,
                          size: 36,
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Speaking indicator and stop button
              if (_isSpeaking)
                GestureDetector(
                  onTap: _stopSpeaking,
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppColors.accentGreen,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accentGreen.withOpacity(0.3),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.volume_off,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                )
              else if (_isListening || _isProcessing) ...[
                const SizedBox(width: 60), // Placeholder for alignment
              ],
            ],
          ),

          // Status text
          const SizedBox(height: 12),
          Text(
            _isListening
                ? 'Listening… pause ~${silenceTimeout.inSeconds}s to auto-send'
                : _isProcessing
                ? 'Processing your question... Please wait'
                : _isSpeaking
                ? 'Speaking response... Tap speaker button to stop'
                : !_isInitialized
                ? 'Initializing voice services...'
                : 'Tap mic and talk. After answer, just speak follow-ups.',
            style: TextStyle(
              color: AppColors.secondaryTextColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _speech.stop();
    _flutterTts.stop();
    super.dispose();
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}
