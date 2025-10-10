import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:url_launcher/url_launcher.dart' as launcher;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import '../theme.dart';
import '../config/subjects.dart';
import '../config/areas.dart';
// local rating summary widget declared below

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
  final TextEditingController _reviewController = TextEditingController();
  bool _submitting = false;
  bool _uploading = false;
  String? _uploadedUrl;
  // rating state now handled on dedicated review page

  @override
  void dispose() {
    _proofController.dispose();
    _reviewController.dispose();
    super.dispose();
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> get _enrollmentStream =>
      FirebaseFirestore.instance
          .collection('enrollments')
          .doc(widget.enrollmentId)
          .snapshots();

  Future<Map<String, dynamic>?> _ensureCurrentMonthInvoice(
      String enrollmentId) async {
    // Use callable so backend creates invoice for the current month (idempotent)
    await FirebaseAuth.instance.currentUser?.getIdToken(true);
    final callable = FirebaseFunctions.instanceFor(region: 'asia-south1')
        .httpsCallable('getOrCreateCurrentMonthInvoice');
    final res = await callable.call({'enrollmentId': enrollmentId});
    final map = (res.data as Map?)?.cast<String, dynamic>();
    return map;
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
              final tutorId = (c['tutorId'] as String?) ?? '';

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
                          const SizedBox(height: 8),
                          if (tutorId.isNotEmpty)
                            Row(
                              children: [
                                const Icon(Icons.person,
                                    size: 16, color: Colors.grey),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: FutureBuilder<
                                      DocumentSnapshot<Map<String, dynamic>>>(
                                    future: FirebaseFirestore.instance
                                        .collection('tutor_profiles')
                                        .doc(tutorId)
                                        .get(),
                                    builder: (context, tSnap) {
                                      final t = tSnap.data?.data() ??
                                          <String, dynamic>{};
                                      final tutorName =
                                          (t['full_name'] as String?) ??
                                              'Tutor';
                                      return Text(tutorName,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w600));
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                _TutorRatingSummaryEnroll(tutorId: tutorId),
                                const SizedBox(width: 8),
                                TextButton(
                                  onPressed: () =>
                                      _showTutorProfile(context, tutorId),
                                  child: const Text('View Profile'),
                                ),
                              ],
                            ),
                          const SizedBox(height: 12),
                          Text(desc, style: const TextStyle(fontSize: 14)),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Learning Materials (visible to enrolled student)
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
                          const Text('Learning Materials',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                            stream: FirebaseFirestore.instance
                                .collection('classes')
                                .doc(classId)
                                .collection('materials')
                                .orderBy('created_at', descending: true)
                                .snapshots(),
                            builder: (context, matSnap) {
                              final mats = matSnap.data?.docs ?? [];
                              if (mats.isEmpty) {
                                return const Text(
                                  'No materials uploaded yet.',
                                  style: TextStyle(fontSize: 13),
                                );
                              }
                              return Column(
                                children: mats.map((d) {
                                  final m = d.data();
                                  final name =
                                      (m['name'] as String?) ?? 'Material';
                                  final url = (m['fileUrl'] as String?) ?? '';
                                  final allow =
                                      (m['allowDownload'] as bool?) ?? false;
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.insert_drive_file),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(name,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w600)),
                                              Text(
                                                  allow
                                                      ? 'Download allowed'
                                                      : 'View only',
                                                  style: const TextStyle(
                                                      fontSize: 12)),
                                            ],
                                          ),
                                        ),
                                        IconButton(
                                          tooltip: 'View',
                                          icon:
                                              const Icon(Icons.remove_red_eye),
                                          onPressed: url.isEmpty
                                              ? null
                                              : () {
                                                  final nameParam =
                                                      Uri.encodeComponent(name);
                                                  final urlParam =
                                                      Uri.encodeComponent(url);
                                                  context.push(
                                                      '/material/view?name=$nameParam&url=$urlParam');
                                                },
                                        ),
                                        IconButton(
                                          tooltip: 'Download',
                                          icon: const Icon(Icons.download),
                                          onPressed: (!allow || url.isEmpty)
                                              ? null
                                              : () async {
                                                  final uri = Uri.parse(url);
                                                  final ok =
                                                      await launcher.launchUrl(
                                                    uri,
                                                    mode: launcher.LaunchMode
                                                        .externalApplication,
                                                  );
                                                  if (!ok && mounted) {
                                                    ScaffoldMessenger.of(
                                                            context)
                                                        .showSnackBar(
                                                      const SnackBar(
                                                          content: Text(
                                                              'Unable to download material')),
                                                    );
                                                  }
                                                },
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Payment proof
                    FutureBuilder<Map<String, dynamic>?>(
                      future: _ensureCurrentMonthInvoice(widget.enrollmentId),
                      builder: (context, invSnap) {
                        if (invSnap.hasError) {
                          return Padding(
                            padding: const EdgeInsets.all(8),
                            child: Text(
                                'Failed to load invoice: ${invSnap.error}',
                                style: const TextStyle(color: Colors.red)),
                          );
                        }
                        final inv = invSnap.data;
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
                              _buildUploadArea(context, invoiceId),
                              const SizedBox(height: 8),
                              Align(
                                alignment: Alignment.centerRight,
                                child: FilledButton(
                                  onPressed: _submitting
                                      ? null
                                      : (_uploadedUrl == null ||
                                              invoiceId.isEmpty)
                                          ? null
                                          : () => _submitProof(context,
                                              invoiceId, _uploadedUrl!),
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

                    const SizedBox(height: 20),

                    // Message + Review buttons (only visible to owning student)
                    if (tutorId.isNotEmpty &&
                        (FirebaseAuth.instance.currentUser?.uid ==
                            (enroll['studentId'] as String?)))
                      Row(
                        children: [
                          const Spacer(),
                          OutlinedButton.icon(
                            onPressed: () => context.push('/chat/$tutorId'),
                            icon: const Icon(Icons.chat_bubble_outline),
                            label: const Text('Message Tutor'),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                            onPressed: () => context.push(
                                '/enrollment/${widget.enrollmentId}/review'),
                            icon: const Icon(Icons.rate_review),
                            label: const Text('Write / Edit Review'),
                          ),
                        ],
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

  Widget _buildUploadArea(BuildContext context, String invoiceId) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_uploadedUrl != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(_uploadedUrl!, height: 140, fit: BoxFit.cover),
          ),
        if (_uploadedUrl != null) const SizedBox(height: 8),
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: _uploading ? null : () => _pickAndUpload(invoiceId),
              icon: const Icon(Icons.upload),
              label:
                  Text(_uploadedUrl == null ? 'Upload image' : 'Replace image'),
            ),
            if (_uploading) ...[
              const SizedBox(width: 12),
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            ]
          ],
        ),
        if (_uploadedUrl == null)
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Text('JPEG/PNG. Max ~5MB',
                style: TextStyle(fontSize: 12, color: Colors.black54)),
          )
      ],
    );
  }

  Future<void> _pickAndUpload(String invoiceId) async {
    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(
          source: ImageSource.gallery, maxWidth: 1600, imageQuality: 85);
      if (file == null) return;
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      setState(() {
        _uploading = true;
      });

      final nameParts = file.name.split('.');
      final ext = nameParts.isNotEmpty ? nameParts.last.toLowerCase() : 'jpg';
      final safeExt =
          ['jpg', 'jpeg', 'png', 'webp', 'heic'].contains(ext) ? ext : 'jpg';
      final filename = '${DateTime.now().millisecondsSinceEpoch}.$safeExt';
      final ref = FirebaseStorage.instance
          .ref()
          .child('payment_proofs/$uid/$invoiceId/$filename');
      final metadata = SettableMetadata(contentType: 'image/$safeExt');
      await ref.putFile(File(file.path), metadata);
      final url = await ref.getDownloadURL();

      setState(() {
        _uploadedUrl = url;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload failed: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _uploading = false;
        });
      }
    }
  }

  // Rating submission now handled in StudentWriteReviewPage

  Future<void> _submitProof(
      BuildContext context, String invoiceId, String proofUrl) async {
    if (invoiceId.isEmpty || proofUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload a payment proof image')),
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
      setState(() {
        _uploadedUrl = null;
      });
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

  void _showTutorProfile(BuildContext context, String tutorId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                controller: scrollController,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.person, color: AppTheme.brandPrimary),
                        const SizedBox(width: 8),
                        FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                          future: FirebaseFirestore.instance
                              .collection('tutor_profiles')
                              .doc(tutorId)
                              .get(),
                          builder: (context, snap) {
                            final data =
                                snap.data?.data() ?? <String, dynamic>{};
                            final name =
                                (data['full_name'] as String?) ?? 'Tutor';
                            return Text(name,
                                style: const TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.w700));
                          },
                        ),
                        const Spacer(),
                        _TutorRatingSummaryEnroll(tutorId: tutorId),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(),
                    const SizedBox(height: 8),
                    // Tutor details block
                    FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                      future: FirebaseFirestore.instance
                          .collection('tutor_profiles')
                          .doc(tutorId)
                          .get(),
                      builder: (context, pSnap) {
                        final p = pSnap.data?.data() ?? <String, dynamic>{};
                        final subjects =
                            (p['subjects_taught'] as List?)?.cast<String>() ??
                                const <String>[];
                        final areaCode = (p['area_code'] as String?) ?? '';
                        final about = (p['about'] as String?) ?? '';
                        final qualifications =
                            (p['qualifications'] as String?) ?? '';
                        final experience = (p['experience'] as String?) ?? '';
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.place,
                                    size: 16, color: Colors.grey),
                                const SizedBox(width: 6),
                                Text(_areaName(areaCode),
                                    style: const TextStyle(fontSize: 13)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (subjects.isNotEmpty) ...[
                              const Text('Subjects',
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600)),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: subjects
                                    .map((s) => Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.grey
                                                .withValues(alpha: 0.1),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: Text(_subjectName(s),
                                              style: const TextStyle(
                                                  fontSize: 12)),
                                        ))
                                    .toList(),
                              ),
                              const SizedBox(height: 10),
                            ],
                            if (about.isNotEmpty) ...[
                              const Text('About',
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600)),
                              const SizedBox(height: 4),
                              Text(about, style: const TextStyle(fontSize: 13)),
                              const SizedBox(height: 10),
                            ],
                            if (qualifications.isNotEmpty) ...[
                              const Text('Qualifications',
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600)),
                              const SizedBox(height: 4),
                              Text(qualifications,
                                  style: const TextStyle(fontSize: 13)),
                              const SizedBox(height: 10),
                            ],
                            if (experience.isNotEmpty) ...[
                              const Text('Experience',
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600)),
                              const SizedBox(height: 4),
                              Text(experience,
                                  style: const TextStyle(fontSize: 13)),
                              const SizedBox(height: 10),
                            ],
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    const Text('Recent Reviews',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: FirebaseFirestore.instance
                          .collection('tutor_profiles')
                          .doc(tutorId)
                          .collection('ratings')
                          .orderBy('updatedAt', descending: true)
                          .limit(10)
                          .snapshots(),
                      builder: (context, snap) {
                        final docs = snap.data?.docs ?? [];
                        if (docs.isEmpty) {
                          return const Text('No reviews yet.');
                        }
                        return Column(
                          children: docs.map((d) {
                            final r = d.data();
                            final rating = (r['rating'] as num?)?.toInt() ?? 0;
                            final review = (r['review'] as String?) ?? '';
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.04),
                                    blurRadius: 3,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: List.generate(5, (i) {
                                      final filled = rating >= i + 1;
                                      return Icon(
                                        filled ? Icons.star : Icons.star_border,
                                        size: 16,
                                        color: filled
                                            ? AppTheme.brandPrimary
                                            : Colors.grey,
                                      );
                                    }),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                        review.isEmpty ? 'No comment' : review,
                                        style: const TextStyle(fontSize: 13)),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _TutorRatingSummaryEnroll extends StatelessWidget {
  final String tutorId;
  const _TutorRatingSummaryEnroll({required this.tutorId});

  @override
  Widget build(BuildContext context) {
    final ratingsRef = FirebaseFirestore.instance
        .collection('tutor_profiles')
        .doc(tutorId)
        .collection('ratings');
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: ratingsRef.snapshots(),
      builder: (context, snap) {
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Text('No ratings', style: TextStyle(fontSize: 12));
        }
        double avg = 0;
        for (final d in docs) {
          final r = (d.data()['rating'] as num?)?.toDouble() ?? 0;
          avg += r;
        }
        avg = avg / docs.length;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.star, size: 14, color: AppTheme.brandPrimary),
            const SizedBox(width: 3),
            Text(avg.toStringAsFixed(1), style: const TextStyle(fontSize: 12)),
            const SizedBox(width: 3),
            Text('(${docs.length})', style: const TextStyle(fontSize: 12)),
          ],
        );
      },
    );
  }
}
