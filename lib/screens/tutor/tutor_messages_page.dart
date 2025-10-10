import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme.dart';
import '../../services/functions_service.dart';

class TutorMessagesPage extends StatefulWidget {
  const TutorMessagesPage({super.key});

  @override
  State<TutorMessagesPage> createState() => _TutorMessagesPageState();
}

class _TutorMessagesPageState extends State<TutorMessagesPage> {
  int _selectedIndex = 2;

  Future<List<Map<String, dynamic>>> _loadClassMessages() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const [];
    }
    try {
      final classesSnap = await FirebaseFirestore.instance
          .collection('classes')
          .where('tutorId', isEqualTo: uid)
          .get();
      final mapById = {for (final d in classesSnap.docs) d.id: d.data()};
      final classIds = mapById.keys.toList();
      final out = <Map<String, dynamic>>[];
      for (final classId in classIds) {
        // compute live student count from enrollments (active/pending)
        int studentCount = 0;
        try {
          final enrSnap = await FirebaseFirestore.instance
              .collection('enrollments')
              .where('classId', isEqualTo: classId)
              .where('status', whereIn: ['active', 'pending']).get();
          studentCount = enrSnap.docs.length;
        } catch (_) {}
        final ann = await FirebaseFirestore.instance
            .collection('classes')
            .doc(classId)
            .collection('announcements')
            .orderBy('created_at_ts', descending: true)
            .limit(1)
            .get();
        final cdata = mapById[classId] ?? <String, dynamic>{};
        out.add({
          'classId': classId,
          'className': (cdata['name'] as String?) ?? 'Class',
          'type': (cdata['type'] as String?) ?? 'Group',
          'students': studentCount,
          'lastMessage': ann.docs.isNotEmpty
              ? ((ann.docs.first.data()['message'] as String?) ?? '')
              : '',
          'time': ann.docs.isNotEmpty
              ? (() {
                  final a = ann.docs.first.data();
                  final ts = a['created_at_ts'];
                  if (ts is Timestamp) return ts.toDate().toIso8601String();
                  return (a['created_at'] as String?) ?? '';
                })()
              : '',
        });
      }
      return out;
    } catch (e) {
      return const [];
    }
  }

  Stream<List<Map<String, dynamic>>> _individualThreadsStream() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return Stream<List<Map<String, dynamic>>>.value(const []);
    }
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('messages')
        .orderBy('sentAt', descending: true)
        .snapshots()
        .map((snap) {
      final byPeer = <String, List<Map<String, dynamic>>>{};
      for (final d in snap.docs) {
        final m = d.data();
        final pid = (m['peerId'] as String?) ?? (m['from'] as String?) ?? '';
        if (pid.isEmpty) continue;
        byPeer.putIfAbsent(pid, () => []).add(m);
      }
      final threads = byPeer.entries.map((e) {
        final last = e.value.first;
        return {
          'peerId': e.key,
          'lastText': (last['text'] as String?) ?? '',
          'sentAt': (last['sentAt'] as String?) ?? '',
          'hasUnread': e.value.any((x) => !(x['read'] as bool? ?? false)),
        };
      }).toList();
      return threads;
    });
  }

  void _onBottomNavTap(int index) {
    setState(() => _selectedIndex = index);
    switch (index) {
      case 0:
        context.go('/tutor');
        break;
      case 1:
        context.go('/tutor/classes');
        break;
      case 2:
        break;
      case 3:
        context.go('/tutor/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppTheme.brandSurface,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0.5,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/tutor'),
          ),
          title: const Text('Messages'),
          actions: [
            TextButton.icon(
              onPressed: () => _showComposeDialog(),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('New Message'),
            ),
          ],
          bottom: const TabBar(
            labelColor: AppTheme.brandPrimary,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppTheme.brandPrimary,
            tabs: [
              Tab(text: 'Class Messages'),
              Tab(text: 'Individual'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Class Messages Tab
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _loadClassMessages(),
              builder: (context, snap) {
                if (snap.hasError) {
                  return const Center(
                      child: Text('Failed to load class messages'));
                }
                final items = snap.data ?? const [];
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final message = items[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                (message['className'] as String?) ?? 'Class',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: _getTypeColor(
                                        (message['type'] as String?) ?? 'Group')
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                (message['type'] as String?) ?? 'Group',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: _getTypeColor(
                                      (message['type'] as String?) ?? 'Group'),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              '${message['students']} students',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              (message['lastMessage'] as String?) ?? '',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 13),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              (message['time'] as String?) ?? '',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.send),
                          onPressed: () => _composeClassMessage(message),
                          color: AppTheme.brandPrimary,
                        ),
                        onTap: () => _viewClassMessages(message),
                      ),
                    );
                  },
                );
              },
            ),

            // Individual Messages Tab
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: _individualThreadsStream(),
              builder: (context, snap) {
                if (snap.hasError) {
                  return const Center(
                      child: Text('Failed to load conversations'));
                }
                final threads = snap.data ?? const [];
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: threads.length,
                  itemBuilder: (context, index) {
                    final message = threads[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: CircleAvatar(
                          backgroundColor:
                              AppTheme.brandPrimary.withValues(alpha: 0.1),
                          child: Text(
                            () {
                              final pid = (message['peerId'] as String?) ?? '';
                              if (pid.isEmpty) return 'ST';
                              return (pid.length >= 2
                                      ? pid.substring(0, 2)
                                      : pid.substring(0, 1))
                                  .toUpperCase();
                            }(),
                            style: const TextStyle(
                              color: AppTheme.brandPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          (message['peerId'] as String?) ?? 'Student',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              (message['lastText'] as String?) ?? '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 13),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              message['sentAt'] as String? ?? '',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                        trailing: (message['hasUnread'] as bool? ?? false)
                            ? Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: AppTheme.brandPrimary,
                                  shape: BoxShape.circle,
                                ),
                              )
                            : null,
                        onTap: () => _openIndividualChat(message),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: _onBottomNavTap,
          backgroundColor: Colors.white,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Dashboard',
            ),
            NavigationDestination(
              icon: Icon(Icons.class_outlined),
              selectedIcon: Icon(Icons.class_),
              label: 'Classes',
            ),
            NavigationDestination(
              icon: Icon(Icons.chat_bubble_outline),
              selectedIcon: Icon(Icons.chat_bubble),
              label: 'Messages',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'Group':
        return Colors.blue;
      case 'Individual':
        return Colors.orange;
      case 'Online':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  void _showComposeDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'New Message',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.group, color: AppTheme.brandPrimary),
                title: const Text('Message a Class'),
                subtitle: const Text('Send message to all students in a class'),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Show class selection dialog
                },
              ),
              ListTile(
                leading: const Icon(Icons.person, color: AppTheme.brandPrimary),
                title: const Text('Message Individual Student'),
                subtitle: const Text('Send direct message to a student'),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Show student selection dialog
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _composeClassMessage(Map<String, dynamic> classInfo) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final messageController = TextEditingController();
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.group, color: AppTheme.brandPrimary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Message to Class ${classInfo['classId']} students',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${classInfo['students']} students will receive this message',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: messageController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Type your message...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.attach_file),
                      onPressed: () {
                        // TODO: Implement file attachment
                      },
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final text = messageController.text.trim();
                        if (text.isEmpty) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Message is empty')),
                          );
                          return;
                        }
                        try {
                          // send to all students of this class
                          final classId = classInfo['classId'] as String;
                          final enrSnap = await FirebaseFirestore.instance
                              .collection('enrollments')
                              .where('classId', isEqualTo: classId)
                              .where('status',
                                  whereIn: ['active', 'pending']).get();
                          final fn = FunctionsService();
                          for (final d in enrSnap.docs) {
                            final sid = (d.data()['studentId'] as String?);
                            if (sid != null && sid.isNotEmpty) {
                              await fn.sendMessageToUser(
                                  toUserId: sid, text: text);
                            }
                          }
                          await FirebaseFirestore.instance
                              .collection('classes')
                              .doc(classId)
                              .collection('announcements')
                              .add({
                            'title': 'Class Message',
                            'message': text,
                            'created_at': DateTime.now().toIso8601String(),
                            'created_at_ts': FieldValue.serverTimestamp(),
                            'status': 'sent'
                          });
                          if (mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Message sent to class')),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Failed: $e')),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.send, size: 18),
                      label: const Text('Send'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.brandPrimary,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _viewClassMessages(Map<String, dynamic> classInfo) {
    final classId = classInfo['classId'] as String?;
    if (classId == null || classId.isEmpty) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.6,
        child: Column(
          children: [
            const SizedBox(height: 12),
            const Text('Class Message History',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('classes')
                    .doc(classId)
                    .collection('announcements')
                    .orderBy('created_at', descending: true)
                    .snapshots(),
                builder: (context, snap) {
                  final docs = snap.data?.docs ?? [];
                  if (docs.isEmpty) {
                    return const Center(child: Text('No messages yet'));
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final a = docs[index].data();
                      return ListTile(
                        title: Text((a['message'] as String?) ?? ''),
                        subtitle: Text((a['created_at'] as String?) ?? ''),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openIndividualChat(Map<String, dynamic> message) {
    final peerId = message['peerId'] as String?;
    if (peerId == null || peerId.isEmpty) return;
    context.push('/chat/$peerId');
  }
}
