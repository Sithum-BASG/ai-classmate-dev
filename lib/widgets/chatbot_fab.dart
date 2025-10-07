import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme.dart';
import '../services/functions_service.dart';

class ChatbotPage extends StatefulWidget {
  const ChatbotPage({super.key});

  @override
  State<ChatbotPage> createState() => _ChatbotPageState();
}

class _ChatbotPageState extends State<ChatbotPage> {
  final TextEditingController _messageController = TextEditingController();
  final FunctionsService _fn = FunctionsService();
  final List<Map<String, dynamic>> _messages = [
    {
      'sender': 'bot',
      'message':
          'Hello! I\'m your AI Study Assistant. How can I help you today?',
      'time': '10:00 AM',
    },
  ];
  bool _isSending = false;
  final ScrollController _scrollController = ScrollController();
  List<Map<String, String>> _hints = const [];

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 80,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _streamReply(String reply) async {
    // Append reply text in small chunks for a simple streaming effect
    final idx = _messages.lastIndexWhere((m) => m['sender'] == 'bot');
    if (idx == -1) return;
    const int chunk = 4;
    for (int i = 0; i < reply.length; i += chunk) {
      if (!mounted) return;
      final part = reply.substring(i, (i + chunk).clamp(0, reply.length));
      setState(() {
        _messages[idx]['message'] =
            (_messages[idx]['message'] as String) + part;
      });
      _scrollToBottom();
      await Future.delayed(const Duration(milliseconds: 14));
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;
    if (_isSending) return;
    setState(() => _isSending = true);

    final userText = _messageController.text;
    FocusScope.of(context).unfocus();
    setState(() {
      _messages.add({
        'sender': 'user',
        'message': userText,
        'time': 'Now',
      });
      _messages.add({
        'sender': 'bot_typing',
        'message': '...',
        'time': 'Now',
      });
    });
    _scrollToBottom();

    _messageController.clear();

    try {
      final result = await _fn.chatbotReply(userText);
      final reply =
          (result['reply'] as String?) ?? 'Sorry, I could not respond.';
      if (!mounted) return;
      setState(() {
        // remove typing indicator and insert empty bot message for streaming
        _messages.removeWhere((m) => m['sender'] == 'bot_typing');
        _messages.add({'sender': 'bot', 'message': '', 'time': 'Now'});
        final rawHints = (result['hints'] as List?) ?? const [];
        _hints = rawHints
            .whereType<Map>()
            .map((m) => m.cast<String, dynamic>())
            .map((m) => {
                  'label': (m['label'] as String?) ?? 'Open',
                  'route': (m['route'] as String?) ?? '/',
                })
            .toList();
        _isSending = false;
      });
      _scrollToBottom();
      await _streamReply(reply);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.removeWhere((m) => m['sender'] == 'bot_typing');
        _messages.add({
          'sender': 'bot',
          'message': 'Sorry, I had trouble replying. Please try again.',
          'time': 'Now',
        });
        _isSending = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.brandSurface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.brandText),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'AI Assistant',
          style: TextStyle(
            color: AppTheme.brandText,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.brandText),
            onPressed: () {
              setState(() {
                _messages.clear();
                _messages.add({
                  'sender': 'bot',
                  'message':
                      'Hello! I\'m your AI Study Assistant. How can I help you today?',
                  'time': 'Now',
                });
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              controller: _scrollController,
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final sender = (message['sender'] as String?) ?? 'bot';
                final isBot = sender == 'bot' || sender == 'bot_typing';

                return Align(
                  alignment:
                      isBot ? Alignment.centerLeft : Alignment.centerRight,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.75,
                    ),
                    decoration: BoxDecoration(
                      color: isBot ? Colors.white : AppTheme.brandPrimary,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sender == 'bot_typing'
                              ? 'Typing…'
                              : message['message'],
                          style: TextStyle(
                            color: isBot ? AppTheme.brandText : Colors.white,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          message['time'],
                          style: TextStyle(
                            color: isBot ? Colors.grey : Colors.white70,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          if (_hints.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: _hints
                      .map((h) => ActionChip(
                            label: Text(h['label'] ?? 'Open'),
                            onPressed: () {
                              final route = h['route'] ?? '/';
                              context.go(route);
                            },
                          ))
                      .toList(),
                ),
              ),
            ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Ask me anything...',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      filled: true,
                      fillColor: AppTheme.brandSurface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    onSubmitted: (_) {
                      if (!_isSending) _sendMessage();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: const BoxDecoration(
                    color: AppTheme.brandPrimary,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: _isSending ? null : _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
