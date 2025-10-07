import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme.dart';

class MessagesPage extends StatefulWidget {
  const MessagesPage({super.key});

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  Stream<QuerySnapshot<Map<String, dynamic>>> _messagesStream() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Stream<QuerySnapshot<Map<String, dynamic>>>.empty();
    }
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('messages')
        .orderBy('sentAt', descending: true)
        .snapshots();
  }

  String _formatTime(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    try {
      final dt = DateTime.tryParse(iso)?.toLocal();
      if (dt == null) return '';
      final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final min = dt.minute.toString().padLeft(2, '0');
      final ampm = dt.hour >= 12 ? 'PM' : 'AM';
      return '$hour:$min $ampm';
    } catch (_) {
      return '';
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
          onPressed: () => context.go('/student'),
        ),
        title: const Text(
          'Messages',
          style: TextStyle(
            color: AppTheme.brandText,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _messagesStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('No messages yet'));
          }
          // Group into chat threads by peerId
          final Map<String, List<QueryDocumentSnapshot<Map<String, dynamic>>>>
              byPeer = {};
          for (final d in docs) {
            final pid = (d.data()['peerId'] as String?) ?? '';
            if (pid.isEmpty) continue;
            byPeer.putIfAbsent(pid, () => []).add(d);
          }
          final threads = byPeer.entries.toList()
            ..sort((a, b) {
              final aIso = (a.value.first.data()['sentAt'] as String?) ?? '';
              final bIso = (b.value.first.data()['sentAt'] as String?) ?? '';
              final aMs = DateTime.tryParse(aIso)?.millisecondsSinceEpoch ?? 0;
              final bMs = DateTime.tryParse(bIso)?.millisecondsSinceEpoch ?? 0;
              return bMs.compareTo(aMs);
            });
          return ListView.separated(
            itemCount: threads.length,
            separatorBuilder: (context, index) => const Divider(
              height: 1,
              indent: 72,
            ),
            itemBuilder: (context, index) {
              final thread = threads[index];
              final last = thread.value.first;
              final m = last.data();
              final peerId = thread.key;
              final text = (m['text'] as String?) ?? '';
              final sentAt = (m['sentAt'] as String?) ?? '';
              final hasUnread = thread.value
                  .any((x) => !(x.data()['read'] as bool? ?? false));
              final initials = peerId.isNotEmpty
                  ? peerId.substring(0, 1).toUpperCase()
                  : '?';
              return Container(
                color: Colors.white,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  leading: CircleAvatar(
                    radius: 24,
                    backgroundColor:
                        AppTheme.brandPrimary.withValues(alpha: 0.1),
                    child: Text(
                      initials,
                      style: const TextStyle(
                        color: AppTheme.brandPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  title: Text(
                    peerId,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      text,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _formatTime(sentAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: hasUnread
                              ? AppTheme.brandPrimary
                              : Colors.grey[500],
                          fontWeight:
                              hasUnread ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                      if (hasUnread)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppTheme.brandPrimary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  onTap: () async {
                    // Mark all in this thread as read
                    final batch = FirebaseFirestore.instance.batch();
                    for (final doc in thread.value) {
                      batch.set(doc.reference, {'read': true},
                          SetOptions(merge: true));
                    }
                    await batch.commit();
                    if (!mounted) return;
                    context.push('/chat/$peerId');
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
