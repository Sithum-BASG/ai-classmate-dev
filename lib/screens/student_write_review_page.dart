import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme.dart';

class StudentWriteReviewPage extends StatefulWidget {
  final String enrollmentId;
  const StudentWriteReviewPage({super.key, required this.enrollmentId});

  @override
  State<StudentWriteReviewPage> createState() => _StudentWriteReviewPageState();
}

class _StudentWriteReviewPageState extends State<StudentWriteReviewPage> {
  final TextEditingController _reviewController = TextEditingController();
  int _rating = 0;
  bool _saving = false;

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> _enrollment() {
    return FirebaseFirestore.instance
        .collection('enrollments')
        .doc(widget.enrollmentId)
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
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/enrollment/${widget.enrollmentId}');
            }
          },
        ),
        title: const Text('Rate your tutor'),
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _enrollment(),
        builder: (context, snap) {
          final e = snap.data?.data() ?? <String, dynamic>{};
          final classId = e['classId'] as String?;
          if (classId == null || classId.isEmpty) {
            return const Center(child: Text('Enrollment not found'));
          }
          return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            future: FirebaseFirestore.instance
                .collection('classes')
                .doc(classId)
                .get(),
            builder: (context, cSnap) {
              final c = cSnap.data?.data() ?? <String, dynamic>{};
              final tutorId = (c['tutorId'] as String?) ?? '';
              return Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
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
                          const Text('Your Rating',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          Row(
                            children: List.generate(5, (i) {
                              final star = i + 1;
                              final filled = _rating >= star;
                              return IconButton(
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                icon: Icon(
                                  filled ? Icons.star : Icons.star_border,
                                  color: filled
                                      ? AppTheme.brandPrimary
                                      : Colors.grey,
                                ),
                                onPressed: () => setState(() => _rating = star),
                              );
                            }),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _reviewController,
                            maxLines: 4,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              hintText: 'Share your experience (optional)',
                            ),
                          ),
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerRight,
                            child: FilledButton(
                              onPressed: _saving || _rating == 0
                                  ? null
                                  : () => _save(tutorId, classId),
                              child: _saving
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Text('Submit'),
                            ),
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _save(String tutorId, String classId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    setState(() => _saving = true);
    try {
      final ref = FirebaseFirestore.instance
          .collection('tutor_profiles')
          .doc(tutorId)
          .collection('ratings')
          .doc(widget.enrollmentId);
      final payload = {
        'enrollmentId': widget.enrollmentId,
        'studentId': uid,
        'classId': classId,
        'rating': _rating,
        'review': _reviewController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      };
      await ref.set(payload, SetOptions(merge: true));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thanks for your feedback!')));
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/enrollment/${widget.enrollmentId}');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
