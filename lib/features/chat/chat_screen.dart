import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/models/chat_message_model.dart';
import '../../shared/providers/app_providers.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<String> _suggestedPrompts = [
    'Where should I eat nearby?',
    'I have 2 hours. What should I explore?',
    'Find a peaceful place for photography.',
    'What local food should I try?',
  ];

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOut,
        );
      });
    }
  }

  void _sendMessage([String? text]) {
    final messageText = text ?? _messageController.text;
    if (messageText.trim().isEmpty) return;

    ref.read(chatProvider.notifier).sendMessage(messageText);
    _messageController.clear();
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);

    // Auto-scroll to bottom on new message
    ref.listen(chatProvider, (prev, next) {
      if (prev?.messages.length != next.messages.length || next.isLoading) {
        _scrollToBottom();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ask WanderAI'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep, color: AppColors.primary),
            onPressed: () {
              ref.read(chatProvider.notifier).clearChat();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages List
          Expanded(
            child: chatState.messages.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(20),
                    itemCount: chatState.messages.length,
                    itemBuilder: (context, index) {
                      final msg = chatState.messages[index];
                      return _buildChatBubble(msg);
                    },
                  ),
          ),

          // Typing Indicator
          if (chatState.isLoading) _buildTypingIndicator(),

          // Suggested chips (only shown when conversation is fresh)
          if (chatState.messages.length <= 1 && !chatState.isLoading)
            _buildSuggestionsList(),

          // Input field
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildChatBubble(ChatMessage message) {
    final isUser = message.isUser;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Align(
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: 0.85,
          child: Row(
            mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isUser) ...[
                const CircleAvatar(
                  backgroundColor: AppColors.primary,
                  radius: 14,
                  child: Icon(Icons.auto_awesome, color: Colors.white, size: 14),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isUser ? AppColors.primary : AppColors.card,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isUser ? 16 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 16),
                    ),
                    border: isUser
                        ? null
                        : Border.all(color: AppColors.border, width: 0.5),
                  ),
                  child: isUser
                      ? Text(
                          message.content,
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                        )
                      : FormattedMarkdownText(text: message.content),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestionsList() {
    return Container(
      height: 48,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _suggestedPrompts.length,
        itemBuilder: (context, index) {
          final prompt = _suggestedPrompts[index];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ActionChip(
              label: Text(
                prompt,
                style: const TextStyle(fontSize: 12, color: AppColors.primary),
              ),
              onPressed: () => _sendMessage(prompt),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.divider, width: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                hintText: 'Ask WanderAI anything...',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                contentPadding: EdgeInsets.symmetric(horizontal: 12),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send_rounded, color: AppColors.primary),
            onPressed: () => _sendMessage(),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Row(
          children: [
            const CircleAvatar(
              backgroundColor: AppColors.primary,
              radius: 12,
              child: Icon(Icons.auto_awesome, color: Colors.white, size: 12),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border, width: 0.5),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 1.5, color: AppColors.primary),
                  ),
                  SizedBox(width: 10),
                  Text('Typing...', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.chat_bubble_outline, size: 48, color: AppColors.textMuted),
          const SizedBox(height: 16),
          Text('No messages yet', style: AppTextStyles.titleMedium),
          const SizedBox(height: 8),
          Text(
            'Ask WanderAI for food recommendations or travel schedules.',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Custom Markdown Text Renderer
// ─────────────────────────────────────────────

class FormattedMarkdownText extends StatelessWidget {
  final String text;

  const FormattedMarkdownText({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    final lines = text.split('\n');
    final List<Widget> children = [];

    for (var line in lines) {
      final trimmed = line.trim();

      if (trimmed.isEmpty) {
        children.add(const SizedBox(height: 8));
        continue;
      }

      // Check for headers (e.g. #, ##, ###, **)
      if (trimmed.startsWith('###') || trimmed.startsWith('##') || trimmed.startsWith('#')) {
        final content = trimmed.replaceAll(RegExp(r'^#+\s*'), '');
        children.add(Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 4),
          child: Text(
            content,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary),
          ),
        ));
      }
      // Check for bullet list (e.g. *, -, •)
      else if (trimmed.startsWith('*') || trimmed.startsWith('-') || trimmed.startsWith('•')) {
        final content = trimmed.substring(1).trim();
        children.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('• ', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
              Expanded(child: _parseRichText(content)),
            ],
          ),
        ));
      }
      // Standard line
      else {
        children.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: _parseRichText(trimmed),
        ));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: children,
    );
  }

  // Parse bold markdown tags: **text**
  Widget _parseRichText(String rawLine) {
    final List<TextSpan> spans = [];
    final regex = RegExp(r'\*\*(.*?)\*\*');
    int start = 0;

    for (final match in regex.allMatches(rawLine)) {
      if (match.start > start) {
        spans.add(TextSpan(
          text: rawLine.substring(start, match.start),
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
        ));
      }
      spans.add(TextSpan(
        text: match.group(1),
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ));
      start = match.end;
    }

    if (start < rawLine.length) {
      spans.add(TextSpan(
        text: rawLine.substring(start),
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
      ));
    }

    return RichText(
      text: TextSpan(children: spans),
    );
  }
}
