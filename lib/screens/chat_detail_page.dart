import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../services/functions_service.dart';
import '../theme.dart';

class ChatDetailPage extends StatefulWidget {
  const ChatDetailPage({super.key, required this.peerId});
  final String peerId; // tutor uid

  @override
  State<ChatDetailPage> createState() => _ChatDetailPageState();
}

class _ChatDetailPageState extends State<ChatDetailPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scroll = ScrollController();
  final FunctionsService _fn = FunctionsService();

  Stream<QuerySnapshot<Map<String, dynamic>>> _chatStream() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Stream<QuerySnapshot<Map<String, dynamic>>>.empty();
    }
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('messages')
        .orderBy('sentAt', descending: false)
        .limit(500)
        .snapshots();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    try {
      await _fn.sendMessageToUser(toUserId: widget.peerId, text: text);
      await Future.delayed(const Duration(milliseconds: 50));
      if (mounted)
        _scroll.animateTo(_scroll.position.maxScrollExtent + 80,
            duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to send: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.brandSurface,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('Chat'),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _chatStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                // Filter messages that belong to this peer (compat with old messages w/o peerId)
                final all = snapshot.data?.docs ?? [];
                final docs = all.where((d) {
                  final m = d.data();
                  final pid = (m['peerId'] as String?) ?? '';
                  final from = (m['from'] as String?) ?? '';
                  final to = (m['to'] as String?) ?? '';
                  return pid == widget.peerId ||
                      from == widget.peerId ||
                      to == widget.peerId;
                }).toList();
                final myUid = FirebaseAuth.instance.currentUser?.uid ?? '';
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scroll.hasClients) {
                    _scroll.jumpTo(_scroll.position.maxScrollExtent);
                  }
                });
                return ListView.builder(
                  controller: _scroll,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final m = docs[index].data();
                    final from = (m['from'] as String?) ?? '';
                    final text = (m['text'] as String?) ?? '';
                    final isMe = from == myUid;
                    return Align(
                      alignment:
                          isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.75),
                        decoration: BoxDecoration(
                          color: isMe
                              ? AppTheme.brandPrimary.withValues(alpha: 0.9)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            if (!isMe)
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                          ],
                        ),
                        child: Text(
                          text,
                          style: TextStyle(
                            color: isMe ? Colors.white : AppTheme.brandText,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        hintText: 'Type a message...',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      minLines: 1,
                      maxLines: 4,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _send,
                    icon: const Icon(Icons.send),
                    color: AppTheme.brandPrimary,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
