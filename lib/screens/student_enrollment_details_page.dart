import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme.dart';
import '../config/subjects.dart';
import '../config/areas.dart';

class StudentEnrollmentDetailsPage extends StatefulWidget {
  final String enrollmentId;
  const StudentEnrollmentDetailsPage({super.key, required this.enrollmentId});

  @override
  State<StudentEnrollmentDetailsPage> createState() =>
      _StudentEnrollmentDetailsPageState();
}

class _StudentEnrollmentDetailsPageState
    extends State<StudentEnrollmentDetailsPage> {
  final TextEditingController _proofController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _proofController.dispose();
    super.dispose();
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> get _enrollmentStream =>
      FirebaseFirestore.instance
          .collection('enrollments')
          .doc(widget.enrollmentId)
          .snapshots();

  Future<DocumentSnapshot<Map<String, dynamic>>?> _loadLatestInvoice(
      String enrollmentId) async {
    // Filter by studentId to satisfy security rules and avoid permission-denied on older data
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final q = await FirebaseFirestore.instance
        .collection('invoices')
        .where('enrollmentId', isEqualTo: enrollmentId)
        .where('studentId', isEqualTo: uid)
        .limit(1)
        .get();
    if (q.docs.isEmpty) return null;
    return q.docs.first;
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
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go('/student');
            }
          },
        ),
        title: const Text('My Class'),
        actions: [
          TextButton.icon(
            onPressed: () => _confirmUnenroll(context),
            icon: const Icon(Icons.logout, color: Colors.red),
            label: const Text('Unenroll', style: TextStyle(color: Colors.red)),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
          )
        ],
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _enrollmentStream,
        builder: (context, enrollSnap) {
          final enroll = enrollSnap.data?.data() ?? <String, dynamic>{};
          final classId = enroll['classId'] as String?;
          if (classId == null || classId.isEmpty) {
            return const Center(child: Text('Enrollment not found'));
          }
          final classRef =
              FirebaseFirestore.instance.collection('classes').doc(classId);
          return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: classRef.snapshots(),
            builder: (context, classSnap) {
              final c = classSnap.data?.data() ?? <String, dynamic>{};
              final name = (c['name'] as String?) ?? 'Class';
              final subject = (c['subject_code'] as String?) ?? '';
              final type = (c['type'] as String?) ?? 'Group';
              final mode = (c['mode'] as String?) ?? 'In-person';
              final area = (c['area_code'] as String?) ?? '';
              final grade = (c['grade'] as num?)?.toInt();
              final price = (c['price'] as num?)?.toInt() ?? 0;
              final desc = (c['description'] as String?) ?? '';

              return SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Class card
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
                          Row(
                            children: [
                              const Icon(Icons.place,
                                  size: 16, color: Colors.grey),
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

                    const SizedBox(height: 20),

                    // Payment proof
                    FutureBuilder<DocumentSnapshot<Map<String, dynamic>>?>(
                      future: _loadLatestInvoice(widget.enrollmentId),
                      builder: (context, invSnap) {
                        if (invSnap.hasError) {
                          return Padding(
                            padding: const EdgeInsets.all(8),
                            child: Text(
                                'Failed to load invoice: ${invSnap.error}',
                                style: const TextStyle(color: Colors.red)),
                          );
                        }
                        final inv = invSnap.data?.data();
                        final status =
                            (inv?['status'] as String?) ?? 'awaiting_proof';
                        final amount =
                            (inv?['amountDue'] as num?)?.toInt() ?? 0;
                        final due = (inv?['dueDate'] as String?) ?? '';
                        final invoiceId = (inv?['invoiceId'] as String?) ?? '';
                        return Container(
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
                              const Text('Payment',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600)),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Amount Due: LKR $amount'),
                                  _statusPill(status),
                                ],
                              ),
                              const SizedBox(height: 4),
                              if (due.isNotEmpty)
                                Text('Due: $due',
                                    style: const TextStyle(fontSize: 12)),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _proofController,
                                decoration: const InputDecoration(
                                  labelText: 'Payment proof URL',
                                  hintText: 'Paste image/receipt link',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Align(
                                alignment: Alignment.centerRight,
                                child: FilledButton(
                                  onPressed: _submitting
                                      ? null
                                      : () => _submitProof(context, invoiceId,
                                          _proofController.text.trim()),
                                  child: _submitting
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white),
                                        )
                                      : const Text('Submit Proof'),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
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

  Future<void> _submitProof(
      BuildContext context, String invoiceId, String proofUrl) async {
    if (invoiceId.isEmpty || proofUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid proof URL')),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      await FirebaseAuth.instance.currentUser?.getIdToken(true);
      final callable = FirebaseFunctions.instanceFor(region: 'asia-south1')
          .httpsCallable('submitPaymentProof');
      await callable.call({'invoiceId': invoiceId, 'proofUrl': proofUrl});
      if (!mounted) return;
      _proofController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment proof submitted')),
      );
    } on FirebaseFunctionsException catch (e) {
      if (!mounted) return;
      final msg = '[${e.code}] ${e.message ?? e.details ?? e.toString()}';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit: $msg')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit: $e')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Widget _statusPill(String status) {
    Color color = Colors.grey;
    switch (status) {
      case 'awaiting_proof':
        color = Colors.orange;
        break;
      case 'under_review':
        color = Colors.blue;
        break;
      case 'approved':
        color = Colors.green;
        break;
      case 'rejected':
        color = Colors.red;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6)),
      child: Text(status,
          style: TextStyle(
              color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }

  Future<void> _confirmUnenroll(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unenroll from class'),
        content: const Text('Are you sure you want to unenroll?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Unenroll')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await FirebaseAuth.instance.currentUser?.getIdToken(true);
      final callable = FirebaseFunctions.instanceFor(region: 'asia-south1')
          .httpsCallable('unenrollFromClass');
      await callable.call({'enrollmentId': widget.enrollmentId});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You have unenrolled from this class')),
      );
      context.pop();
    } on FirebaseFunctionsException catch (e) {
      if (!mounted) return;
      final msg = '[${e.code}] ${e.message ?? e.details ?? e.toString()}';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to unenroll: $msg')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to unenroll: $e')),
      );
    }
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
