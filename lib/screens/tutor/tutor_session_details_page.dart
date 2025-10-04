import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme.dart';

class TutorSessionDetailsPage extends StatelessWidget {
  final String classId;
  final String sessionId;

  const TutorSessionDetailsPage(
      {super.key, required this.classId, required this.sessionId});

  Stream<DocumentSnapshot<Map<String, dynamic>>> get _sessionStream =>
      FirebaseFirestore.instance
          .collection('classes')
          .doc(classId)
          .collection('sessions')
          .doc(sessionId)
          .snapshots();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.brandSurface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('Session Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () =>
                context.push('/tutor/class/$classId/sessions/$sessionId/edit'),
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Delete Session'),
                  content: const Text(
                      'Are you sure you want to delete this session?'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel')),
                    FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      style:
                          FilledButton.styleFrom(backgroundColor: Colors.red),
                      child: const Text('Delete'),
                    )
                  ],
                ),
              );
              if (ok == true) {
                try {
                  await FirebaseFirestore.instance
                      .collection('classes')
                      .doc(classId)
                      .collection('sessions')
                      .doc(sessionId)
                      .delete();
                  // ignore: use_build_context_synchronously
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Session deleted')));
                  // ignore: use_build_context_synchronously
                  context.pop();
                } catch (e) {
                  // ignore: use_build_context_synchronously
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text('Failed: $e')));
                }
              }
            },
          )
        ],
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _sessionStream,
        builder: (context, snapshot) {
          final data = snapshot.data?.data() ?? <String, dynamic>{};
          final label = (data['label'] as String?) ?? '';
          final venue = (data['venue'] as String?) ?? '';
          DateTime? start;
          DateTime? end;
          final st = data['start_time'];
          final et = data['end_time'];
          if (st is Timestamp) start = st.toDate();
          if (et is Timestamp) end = et.toDate();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Container(
              padding: const EdgeInsets.all(20),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (label.isNotEmpty)
                    Text(label,
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                  if (label.isNotEmpty) const SizedBox(height: 12),
                  _row('Date', start != null ? _formatDateOnly(start) : '-'),
                  const SizedBox(height: 8),
                  _row('Start time', start != null ? _formatTime(start) : '-'),
                  const SizedBox(height: 8),
                  _row('End time', end != null ? _formatTime(end) : '-'),
                  const SizedBox(height: 8),
                  _row('Venue', venue.isNotEmpty ? venue : '—'),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _row(String k, String v) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(k, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Text(v, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      );

  String _formatDateOnly(DateTime dt) {
    final dayNames = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    final day = dayNames[dt.weekday % 7];
    final month = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$day $d/$month ${dt.year}';
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $ampm';
  }
}
