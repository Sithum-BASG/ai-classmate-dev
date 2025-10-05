import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme.dart';
import '../config/subjects.dart';
import '../config/areas.dart';

class StudentClassDetailsPage extends StatelessWidget {
  final String classId;
  const StudentClassDetailsPage({super.key, required this.classId});

  Stream<DocumentSnapshot<Map<String, dynamic>>> get _classStream =>
      FirebaseFirestore.instance.collection('classes').doc(classId).snapshots();

  Stream<QuerySnapshot<Map<String, dynamic>>> _sessionsStream() {
    return FirebaseFirestore.instance
        .collection('classes')
        .doc(classId)
        .collection('sessions')
        .orderBy('start_time')
        .snapshots();
  }

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
        title: const Text('Class Details'),
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _classStream,
        builder: (context, snapshot) {
          final c = snapshot.data?.data() ?? <String, dynamic>{};
          final name = (c['name'] as String?) ?? 'Class';
          final subject = (c['subject_code'] as String?) ?? '';
          final type = (c['type'] as String?) ?? 'Group';
          final mode = (c['mode'] as String?) ?? 'In-person';
          final area = (c['area_code'] as String?) ?? '';
          final grade = (c['grade'] as num?)?.toInt();
          final price = (c['price'] as num?)?.toInt() ?? 0;
          final desc = (c['description'] as String?) ?? '';
          final tutorId = (c['tutorId'] as String?) ?? '';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
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
                      Text(name,
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _chip(_subjectName(subject), Colors.grey),
                          const SizedBox(width: 8),
                          _chip(type, _typeColor(type)),
                          const SizedBox(width: 8),
                          _chip(mode, Colors.grey),
                          if (grade != null) ...[
                            const SizedBox(width: 8),
                            _chip('Grade $grade', Colors.blue),
                          ]
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (tutorId.isNotEmpty) ...[
                        Row(
                          children: [
                            const Icon(Icons.person,
                                size: 16, color: Colors.grey),
                            const SizedBox(width: 6),
                            FutureBuilder<
                                DocumentSnapshot<Map<String, dynamic>>>(
                              future: FirebaseFirestore.instance
                                  .collection('tutor_profiles')
                                  .doc(tutorId)
                                  .get(),
                              builder: (context, tSnap) {
                                final t =
                                    tSnap.data?.data() ?? <String, dynamic>{};
                                final tutorName =
                                    (t['full_name'] as String?) ?? 'Tutor';
                                return Text('Tutor: $tutorName');
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                      ],
                      Row(
                        children: [
                          const Icon(Icons.place, size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(_areaName(area)),
                          const Spacer(),
                          Text('LKR $price',
                              style: const TextStyle(
                                  color: AppTheme.brandPrimary,
                                  fontWeight: FontWeight.w700)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(desc, style: const TextStyle(fontSize: 14)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Upcoming Sessions',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: _sessionsStream(),
                  builder: (context, snap) {
                    final docs = snap.data?.docs ?? [];
                    if (docs.isEmpty) {
                      return const Text('No sessions scheduled yet.');
                    }
                    return Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: docs.map((d) {
                        final s = d.data();
                        final ts = s['start_time'];
                        DateTime? start;
                        if (ts is Timestamp) start = ts.toDate();
                        final label =
                            start != null ? _formatSession(start) : 'Session';
                        return Chip(label: Text(label));
                      }).toList(),
                    );
                  },
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => _enroll(context),
                    child: const Text('Enroll in this Class'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _enroll(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Enrollment'),
        content: const Text('Do you want to enroll in this class?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Enroll')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await FirebaseAuth.instance.currentUser?.getIdToken(true);
      final callable = FirebaseFunctions.instanceFor(region: 'asia-south1')
          .httpsCallable('enrollInClass');
      await callable.call({'classId': classId});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enrolled successfully')),
      );
    } on FirebaseFunctionsException catch (e) {
      final msg = '[${e.code}] ${e.message ?? e.details ?? e.toString()}';
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to enroll: $msg')));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to enroll: $e')));
    }
  }

  String _formatSession(DateTime dt) {
    final dayNames = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    final day = dayNames[dt.weekday % 7];
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '$day $hour:$minute $ampm';
  }

  String _subjectName(String? code) {
    if (code == null) return 'Subject';
    final match = kSubjectOptions.firstWhere(
      (s) => s.code == code,
      orElse: () => SubjectOption(code: code, label: code),
    );
    return match.label;
  }

  String _areaName(String? code) {
    if (code == null) return 'Any area';
    final match = kAreaOptions.firstWhere(
      (a) => a.code == code,
      orElse: () => AreaOption(code: code, name: code),
    );
    return match.name;
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'Group':
        return Colors.blue;
      case 'Individual':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label, style: TextStyle(fontSize: 11, color: color)),
    );
  }
}
