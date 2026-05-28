import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import '../models/chatbot_model.dart';

class ChatbotService extends ChangeNotifier {
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<ChatMessage> get messages => _messages;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  late final String _groqApiKey;
  final String _groqUrl = 'https://api.groq.com/openai/v1/chat/completions';
  final String _model = 'llama-3.1-8b-instant';

  ChatbotService() {
    _groqApiKey = dotenv.env['GROQ_API_KEY'] ?? '';
  }

  // System instructions to ensure the health bot acts safely and structured
final String _systemPrompt = '''
    You are an AI Health Assistant providing structured educational information and first-aid guidance. 
    
    Strictly follow these response formatting and safety rules:
    1. Use Markdown headers (###) to separate sections like Symptoms, Actionable Advice, and Tips.
    2. Use standard bullet points (* or -) for lists, and nested bullet points for sub-items.
    3. Use bolding (**text**) generously to highlight critical key phrases, drug classes, or symptoms.
    4. Never diagnose a condition or prescribe specific medical dosages. Use inline code (e.g., `Consult a doctor`) if mentioning general medication categories.
    5. Always format your mandatory closing disclaimer inside a markdown blockquote (starting each line with >) so it stands out visually as a warning box.
    6. If comparing items or timelines, format them into a clean markdown table.
  ''';

  // Format bot response for better readability
  String _formatBotResponse(String rawResponse) {
    // Split by newlines and filter out excessive whitespace
    final lines = rawResponse.split('\n');
    final formattedLines = <String>[];
    bool inParagraph = false;

    for (var line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) {
        if (inParagraph) {
          formattedLines.add(''); // Add blank line between paragraphs
          inParagraph = false;
        }
      } else {
        formattedLines.add(trimmed);
        inParagraph = true;
      }
    }

    // Remove trailing empty lines
    while (formattedLines.isNotEmpty && formattedLines.last.isEmpty) {
      formattedLines.removeLast();
    }

    return formattedLines.join('\n');
  }

  // Send message to chatbot
  Future<void> sendMessage(String userMessage) async {
    // Add user message to UI
    _messages.add(
      ChatMessage(
        id: const Uuid().v4(),
        content: userMessage,
        isUser: true,
        timestamp: DateTime.now(),
      ),
    );

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Build conversation payload for context memory
      List<Map<String, String>> historyPayload = [
        {"role": "system", "content": _systemPrompt}
      ];

      // Add recent context history if needed, or just append the last few messages
      for (var msg in _messages) {
        historyPayload.add({
          "role": msg.isUser ? "user" : "assistant",
          "content": msg.content,
        });
      }

      final response = await http.post(
        Uri.parse(_groqUrl),
        headers: {
          'Authorization': 'Bearer $_groqApiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': _model,
          'messages': historyPayload,
          'temperature': 0.5,
          'max_tokens': 1024,
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        final String rawResponse = data['choices'][0]['message']['content'].toString();
        final String botResponse = _formatBotResponse(rawResponse);

        debugPrint('Raw API Response: $rawResponse');
        debugPrint('Formatted Bot Response: $botResponse');

        // Add bot message
        _messages.add(
          ChatMessage(
            id: const Uuid().v4(),
            content: botResponse,
            isUser: false,
            timestamp: DateTime.now(),
          ),
        );
      } else {
        final Map<String, dynamic> errorData = jsonDecode(response.body);
        throw Exception(errorData['error']['message'] ?? 'Unknown API Error');
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to get response: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Clear chat history
  void clearMessages() {
    _messages.clear();
    _errorMessage = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}