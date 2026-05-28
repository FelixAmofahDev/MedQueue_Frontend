import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import '../../services/chatbot_service.dart';
import '../../utils/app_colors.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({Key? key}) : super(key: key);

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('AI Health Assistant'),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () {
              context.read<ChatbotService>().clearMessages();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Chat cleared')),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Consumer<ChatbotService>(
              builder: (context, chatbotService, _) {
                if (chatbotService.messages.isEmpty) {
                  return _buildWelcomeScreen();
                }

                // Add 1 extra slot to the length if loading or if there's an error message
                final int itemCount = chatbotService.messages.length + 
                    (chatbotService.isLoading ? 1 : 0) + 
                    (chatbotService.errorMessage != null ? 1 : 0);

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: itemCount,
                  itemBuilder: (context, index) {
                    // 1. Render historic messages
                    if (index < chatbotService.messages.length) {
                      final message = chatbotService.messages[index];
                      return _MessageBubble(
                        content: message.content,
                        isUser: message.isUser,
                        timestamp: message.timestamp,
                      );
                    }

                    // 2. Render loading indicator bubble if it's the next index
                    if (chatbotService.isLoading && index == chatbotService.messages.length) {
                      return const _LoadingBubble();
                    }

                    // 3. Render error message if it exists
                    if (chatbotService.errorMessage != null) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Center(
                          child: Text(
                            chatbotService.errorMessage!,
                            style: const TextStyle(color: Colors.red, fontSize: 13),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                );
              },
            ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildWelcomeScreen() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.local_hospital_outlined,
                size: 60,
                color: AppColors.primaryGreen,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Health Information Assistant',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              'Ask me about common symptoms, first aid, and health tips.',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textGray,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            const Text(
              'Try asking about:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 12),
            _SuggestionChip(text: 'Headache relief', onTapped: _scrollToBottom),
            const SizedBox(height: 8),
            _SuggestionChip(text: 'Fever management', onTapped: _scrollToBottom),
            const SizedBox(height: 8),
            _SuggestionChip(text: 'Cold remedies', onTapped: _scrollToBottom),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warningOrange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.warningOrange.withOpacity(0.3),
                ),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: AppColors.warningOrange),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This is for educational purposes only. Always consult a doctor for proper diagnosis.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.warningOrange,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Consumer<ChatbotService>(
      builder: (context, chatbotService, _) {
        return Container(
          color: Colors.white,
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  decoration: InputDecoration(
                    hintText: 'Ask about symptoms...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: const BorderSide(color: AppColors.borderColor),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  maxLines: null,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (value) {
                    if (value.trim().isNotEmpty) {
                      context.read<ChatbotService>().sendMessage(value.trim());
                      _messageController.clear();
                      _scrollToBottom();
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: const BoxDecoration(
                  color: AppColors.primaryBlue,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.send, color: Colors.white),
                  onPressed: chatbotService.isLoading
                      ? null
                      : () {
                          if (_messageController.text.trim().isNotEmpty) {
                            context.read<ChatbotService>().sendMessage(_messageController.text.trim());
                            _messageController.clear();
                            _scrollToBottom();
                          }
                        },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final String content;
  final bool isUser;
  final DateTime timestamp;

  const _MessageBubble({
    required this.content,
    required this.isUser,
    required this.timestamp,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser)
            Padding(
              padding: const EdgeInsets.only(right: 8, top: 4),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.local_hospital_outlined,
                  size: 16,
                  color: AppColors.primaryGreen,
                ),
              ),
            ),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser ? AppColors.primaryBlue : AppColors.backgroundGray,
                borderRadius: BorderRadius.circular(16),
              ),
              // 2. Use MarkdownBody instead of standard Text
              child: MarkdownBody(
  data: content,
  // Selectable text allows users to copy specific lines/medical terms from the bot
  selectable: true, 
  styleSheet: MarkdownStyleSheet(
    // 1. Regular paragraphs
    p: TextStyle(
      fontSize: 14,
      color: isUser ? Colors.white : AppColors.textDark,
      height: 1.5, // Slightly looser line-height for easier reading
    ),
    
    // 2. Bold text (**text**)
    strong: TextStyle(
      fontWeight: FontWeight.w700,
      color: isUser ? Colors.white : AppColors.textDark,
    ),
    
    // 3. Italics (*text*)
    em: TextStyle(
      fontStyle: FontStyle.italic,
      color: isUser ? Colors.white70 : AppColors.textGray,
    ),

    // 4. Headers (LLMs frequently use #, ##, or ### for section titles)
    h1: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isUser ? Colors.white : AppColors.textDark, height: 1.6),
    h2: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isUser ? Colors.white : AppColors.textDark, height: 1.5),
    h3: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: isUser ? Colors.white : AppColors.textDark, height: 1.4),

    // 5. Lists & Bullets
    listBullet: TextStyle(
      color: isUser ? Colors.white70 : AppColors.primaryGreen,
      fontSize: 14,
    ),
    listBulletPadding: const EdgeInsets.only(right: 8, top: 2),
    
    // 6. Global Block Spacing (Spacing between paragraphs, headers, and lists)
    blockSpacing: 12.0,

    // 7. Blockquotes (Useful for the bot's Warnings/Disclaimers)
    blockquote: TextStyle(
      color: isUser ? Colors.white70 : AppColors.textGray,
      fontSize: 13,
    ),
    blockquotePadding: const EdgeInsets.all(12),
    blockquoteDecoration: BoxDecoration(
      color: isUser ? Colors.white.withOpacity(0.1) : AppColors.warningOrange.withOpacity(0.05),
      borderRadius: BorderRadius.circular(8),
      border: Border(
        left: BorderSide(
          color: isUser ? Colors.white54 : AppColors.warningOrange,
          width: 4,
        ),
      ),
    ),

    // 8. Inline Code (e.g., `dosage: 500mg`)
    code: TextStyle(
      fontFamily: 'monospace',
      fontSize: 13,
      color: isUser ? Colors.white : const Color(0xFFD63384), // Distinct pink/red monospace color
      backgroundColor: isUser ? Colors.white.withOpacity(0.15) : Colors.black.withOpacity(0.05),
    ),

    // 9. Multi-line Code Blocks (``` code ```)
    codeblockPadding: const EdgeInsets.all(12),
    codeblockDecoration: BoxDecoration(
      color: isUser ? Colors.black.withOpacity(0.2) : const Color(0xFF2d3748), // Dark slate fallback
      borderRadius: BorderRadius.circular(8),
    ),

    tableHead: TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.bold,
      color: isUser ? Colors.white : AppColors.textDark,
    ),
    tableBody: TextStyle(
      fontSize: 13,
      color: isUser ? Colors.white : AppColors.textDark,
    ),
    tableBorder: TableBorder.all(
      color: isUser ? Colors.white30 : AppColors.borderColor,
      width: 1,
    ),
    tableCellsPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    
  ),
),
            ),
          ),
          if (isUser)
            Padding(
              padding: const EdgeInsets.only(left: 8, top: 4),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person,
                  size: 16,
                  color: AppColors.primaryBlue,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _LoadingBubble extends StatelessWidget {
  const _LoadingBubble({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.local_hospital_outlined, size: 16, color: AppColors.primaryGreen),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.backgroundGray,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryGreen),
            ),
          ),
        ],
      ),
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  final String text;
  final VoidCallback onTapped;

  const _SuggestionChip({
    required this.text,
    required this.onTapped,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        context.read<ChatbotService>().sendMessage(text);
        onTapped();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.primaryBlue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.primaryBlue.withOpacity(0.3)),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.primaryBlue,
          ),
        ),
      ),
    );
  }
}