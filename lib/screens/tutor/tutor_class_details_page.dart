import 'package:flutter/material.dart';
import 'dart:io';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/functions_service.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
// Fallback: open via Navigator to webview-less browser using canLaunchUrl
import 'package:url_launcher/url_launcher.dart' as launcher;
import '../../theme.dart';

class TutorClassDetailsPage extends StatefulWidget {
  final String classId;

  const TutorClassDetailsPage({
    super.key,
    required this.classId,
  });

  @override
  State<TutorClassDetailsPage> createState() => _TutorClassDetailsPageState();
}

class _TutorClassDetailsPageState extends State<TutorClassDetailsPage> {
  Stream<DocumentSnapshot<Map<String, dynamic>>> get _classStream =>
      FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.classId)
          .snapshots();

  Stream<QuerySnapshot<Map<String, dynamic>>> get _sessionsStream =>
      FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.classId)
          .collection('sessions')
          .orderBy('start_time')
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
          onPressed: () => context.go('/tutor/classes'),
        ),
        title: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: _classStream,
          builder: (context, snapshot) {
            final name = snapshot.data?.data()?['name'] as String?;
            return Text(name == null || name.isEmpty ? 'Class Details' : name);
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => context.go('/tutor/class/${widget.classId}/edit'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Class Info Card
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
              child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                stream: _classStream,
                builder: (context, snapshot) {
                  final data = snapshot.data?.data() ?? <String, dynamic>{};
                  final title = (data['name'] as String?) ?? 'Untitled Class';
                  final type = (data['type'] as String?) ?? 'Group';
                  final mode = (data['mode'] as String?) ?? 'In-person';
                  final description = (data['description'] as String?) ?? '';
                  final students =
                      (data['enrolled_count'] as num?)?.toInt() ?? 0;
                  final maxStudents =
                      (data['max_students'] as num?)?.toInt() ?? 0;
                  final price = (data['price'] as num?)?.toInt() ?? 0;
                  final totalIncome =
                      (data['total_income'] as num?)?.toInt() ?? 0;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'edit') {
                                context
                                    .go('/tutor/class/${widget.classId}/edit');
                              } else if (value == 'delete') {
                                _showDeleteConfirmation();
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit, size: 18),
                                    SizedBox(width: 8),
                                    Text('Edit'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete,
                                        size: 18, color: Colors.red),
                                    SizedBox(width: 8),
                                    Text('Delete',
                                        style: TextStyle(color: Colors.red)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _getTypeColor(type).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              type,
                              style: TextStyle(
                                fontSize: 12,
                                color: _getTypeColor(type),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(mode,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                )),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 20),
                      StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                        stream: FirebaseFirestore.instance
                            .collection('enrollments')
                            .where('classId', isEqualTo: widget.classId)
                            .where('status',
                                whereIn: ['active', 'pending']).snapshots(),
                        builder: (context, enrSnap) {
                          final liveStudents = (enrSnap.data?.docs.length ?? 0);
                          final liveIncome = liveStudents * price;
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildInfoColumn('Students',
                                  '${liveStudents == 0 ? students : liveStudents}/$maxStudents'),
                              _buildInfoColumn('Price', 'Rs. $price'),
                              _buildInfoColumn('Total Income',
                                  'Rs. ${liveIncome == 0 ? totalIncome : liveIncome}',
                                  isHighlighted: true),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Schedule:',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () => context.push(
                                '/tutor/class/${widget.classId}/sessions/new'),
                            icon: const Icon(Icons.add),
                            label: const Text('Create Session'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                        stream: _sessionsStream,
                        builder: (context, snap) {
                          final sess = snap.data?.docs ?? [];
                          if (sess.isEmpty) {
                            return const Text('No sessions yet');
                          }
                          return Wrap(
                            spacing: 12,
                            runSpacing: 8,
                            children: sess.map((d) {
                              final sdata = d.data();
                              DateTime? start;
                              final ts = sdata['start_time'];
                              if (ts is Timestamp) start = ts.toDate();
                              final rawLabel =
                                  (sdata['label'] as String?)?.trim();
                              final chipLabel =
                                  (rawLabel != null && rawLabel.isNotEmpty)
                                      ? rawLabel
                                      : 'Session';
                              final dateText = start != null
                                  ? _formatSessionDateOnly(start)
                                  : '';
                              return InputChip(
                                label: Text(
                                  dateText.isNotEmpty
                                      ? '$chipLabel · $dateText'
                                      : chipLabel,
                                  style: const TextStyle(fontSize: 12),
                                ),
                                backgroundColor: AppTheme.brandSurface,
                                onPressed: () => context.push(
                                    '/tutor/class/${widget.classId}/sessions/${d.id}'),
                                onDeleted: () => _confirmDeleteSession(
                                    d.id, rawLabel ?? chipLabel),
                              );
                            }).toList(),
                          );
                        },
                      ),
                    ],
                  );
                },
              ),
            ),

            const SizedBox(height: 20),

            // Enrolled Students
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Enrolled Students',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => _showAddStudentDialog(),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Add Student'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance
                        .collection('enrollments')
                        .where('classId', isEqualTo: widget.classId)
                        .where('status',
                            whereIn: ['active', 'pending']).snapshots(),
                    builder: (context, enrSnap) {
                      final enr = enrSnap.data?.docs ?? [];
                      if (enr.isEmpty) {
                        return const Text('No students enrolled yet.');
                      }
                      return Column(
                        children: enr.map((e) {
                          final ed = e.data();
                          final enrollmentId =
                              (ed['enrollmentId'] as String?) ?? e.id;
                          // status kept in UI via badge below
                          final name =
                              (ed['studentName'] as String?) ?? 'Student';
                          final initials = name.isNotEmpty
                              ? name
                                  .split(' ')
                                  .map((p) => p.isNotEmpty ? p[0] : '')
                                  .take(2)
                                  .join()
                                  .toUpperCase()
                              : 'ST';
                          // derive but not used further
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.brandSurface,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundColor:
                                      AppTheme.brandPrimary.withOpacity(0.1),
                                  child: Text(
                                    initials,
                                    style: const TextStyle(
                                      color: AppTheme.brandPrimary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(name,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w600)),
                                      const SizedBox(height: 2),
                                      _PaymentStatusBadge(
                                          enrollmentId: enrollmentId),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Row(children: [
                                  IconButton(
                                    tooltip: 'Message student',
                                    onPressed: () => _quickMessageStudent(
                                        studentName: name,
                                        studentId: ed['studentId'] as String?),
                                    icon: const Icon(Icons.chat_bubble_outline,
                                        size: 18),
                                  ),
                                  PopupMenuButton<String>(
                                    onSelected: (value) {
                                      if (value == 'remove') {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content:
                                                Text('Removal not implemented'),
                                          ),
                                        );
                                      }
                                    },
                                    itemBuilder: (context) => const [
                                      PopupMenuItem(
                                        value: 'remove',
                                        child: Text('Remove',
                                            style:
                                                TextStyle(color: Colors.red)),
                                      ),
                                    ],
                                  ),
                                ]),
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
            // Materials uploader (tutor only)
            _MaterialsSection(classId: widget.classId),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _messageClass(),
                    icon: const Icon(Icons.message),
                    label: const Text('Message Class'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _manageStudents(),
                    icon: const Icon(Icons.people),
                    label: const Text('Manage Students'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoColumn(String label, String value,
      {bool isHighlighted = false}) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isHighlighted ? Colors.green : AppTheme.brandText,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
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

  // Removed unused _formatSessionTime

  String _formatSessionDateOnly(DateTime dt) {
    final dayNames = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    final day = dayNames[dt.weekday % 7];
    final month = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$day $d/$month';
  }

  Future<void> _confirmDeleteSession(String sessionId, String label) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Session'),
        content: Text('Delete session "$label"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.classId)
          .collection('sessions')
          .doc(sessionId)
          .delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Session deleted')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete session: $e')),
        );
      }
    }
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Class'),
        content: const Text(
            'Are you sure you want to delete this class? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Class deleted')),
              );
              context.go('/tutor/classes');
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showAddStudentDialog() {
    // TODO: Implement add student dialog
  }

  // Removed unused _showRemoveStudentConfirmation

  void _messageClass() {
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Message entire class',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                minLines: 2,
                maxLines: 5,
                decoration: const InputDecoration(
                    hintText: 'Type your announcement',
                    border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              Row(children: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel')),
                const Spacer(),
                FilledButton.icon(
                    onPressed: () async {
                      final text = controller.text.trim();
                      if (text.isEmpty) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Message is empty')));
                        return;
                      }
                      try {
                        // Fetch class enrollments and send to each student
                        final enrSnap = await FirebaseFirestore.instance
                            .collection('enrollments')
                            .where('classId', isEqualTo: widget.classId)
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
                        // Log under class announcements for history
                        await FirebaseFirestore.instance
                            .collection('classes')
                            .doc(widget.classId)
                            .collection('announcements')
                            .add({
                          'title': 'Class Message',
                          'message': text,
                          'created_at': DateTime.now().toIso8601String(),
                          'status': 'sent'
                        });
                        if (mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Message sent to class')));
                        }
                      } catch (e) {
                        if (mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Failed: $e')));
                        }
                      }
                    },
                    icon: const Icon(Icons.send, size: 18),
                    label: const Text('Send'))
              ])
            ],
          ),
        ),
      ),
    );
  }

  void _manageStudents() {
    // TODO: Navigate to student management for this class
  }

  Future<void> _quickMessageStudent(
      {required String studentName, String? studentId}) async {
    final controller = TextEditingController();
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Message $studentName',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                    hintText: 'Type your message',
                    border: OutlineInputBorder()),
                minLines: 2,
                maxLines: 5,
              ),
              const SizedBox(height: 12),
              Row(children: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel')),
                const Spacer(),
                FilledButton.icon(
                    onPressed: () async {
                      final text = controller.text.trim();
                      if (text.isEmpty ||
                          (studentId == null || studentId.isEmpty)) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Invalid message or student')));
                        return;
                      }
                      try {
                        final fn = FunctionsService();
                        await fn.sendMessageToUser(
                            toUserId: studentId, text: text);
                        if (mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Message sent')));
                        }
                      } catch (e) {
                        if (mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Failed: $e')));
                        }
                      }
                    },
                    icon: const Icon(Icons.send, size: 18),
                    label: const Text('Send'))
              ])
            ],
          ),
        ),
      ),
    );
  }
}

class _MaterialsSection extends StatefulWidget {
  final String classId;
  const _MaterialsSection({required this.classId});

  @override
  State<_MaterialsSection> createState() => _MaterialsSectionState();
}

class _MaterialsSectionState extends State<_MaterialsSection> {
  bool _uploading = false;
  bool _allowDownload = true;

  Stream<QuerySnapshot<Map<String, dynamic>>> get _materialsStream =>
      FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.classId)
          .collection('materials')
          .orderBy('created_at', descending: true)
          .snapshots();

  Future<void> _pickAndUpload() async {
    try {
      final res = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        withData: true,
        type: FileType.any,
      );
      if (res == null || res.files.isEmpty) return;
      final file = res.files.single;
      setState(() => _uploading = true);

      final filename = file.name;
      final materialId = FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.classId)
          .collection('materials')
          .doc()
          .id;

      final storageRef = FirebaseStorage.instance
          .ref()
          .child('class_materials/${widget.classId}/$materialId/$filename');
      if (file.bytes != null) {
        await storageRef.putData(
          file.bytes!,
          SettableMetadata(contentType: 'application/octet-stream'),
        );
      } else if (file.path != null) {
        await storageRef.putFile(File(file.path!),
            SettableMetadata(contentType: 'application/octet-stream'));
      } else {
        throw Exception('No file data');
      }
      final url = await storageRef.getDownloadURL();

      await FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.classId)
          .collection('materials')
          .doc(materialId)
          .set({
        'name': filename,
        'fileUrl': url,
        'allowDownload': _allowDownload,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Upload failed: $e')));
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
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
          LayoutBuilder(builder: (context, constraints) {
            final bool isNarrow = constraints.maxWidth < 360;
            final Widget controls = Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Allow download'),
                const SizedBox(width: 6),
                Switch(
                  value: _allowDownload,
                  onChanged: (v) => setState(() => _allowDownload = v),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: _uploading ? null : _pickAndUpload,
                  icon: const Icon(Icons.upload),
                  label: Text(_uploading ? 'Uploading...' : 'Upload'),
                )
              ],
            );
            if (isNarrow) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Learning Materials',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Align(alignment: Alignment.centerRight, child: controls),
                ],
              );
            }
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    'Learning Materials',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                controls,
              ],
            );
          }),
          const SizedBox(height: 12),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _materialsStream,
            builder: (context, snap) {
              final items = snap.data?.docs ?? [];
              if (items.isEmpty) {
                return const Text('No materials uploaded yet.');
              }
              return Column(
                children: items.map((d) {
                  final m = d.data();
                  final name = (m['name'] as String?) ?? 'Material';
                  final allow = (m['allowDownload'] as bool?) ?? false;
                  final url = (m['fileUrl'] as String?) ?? '';
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        const Icon(Icons.insert_drive_file),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600),
                              ),
                              Text(
                                allow ? 'Download allowed' : 'View only',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: allow ? 'Download' : 'View',
                          icon: Icon(
                              allow ? Icons.download : Icons.remove_red_eye),
                          onPressed: url.isEmpty
                              ? null
                              : () async {
                                  final uri = Uri.parse(url);
                                  if (await launcher.canLaunchUrl(uri)) {
                                    await launcher.launchUrl(uri);
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
    );
  }
}

class _PaymentStatusBadge extends StatefulWidget {
  const _PaymentStatusBadge({required this.enrollmentId});
  final String enrollmentId;

  @override
  State<_PaymentStatusBadge> createState() => _PaymentStatusBadgeState();
}

class _PaymentStatusBadgeState extends State<_PaymentStatusBadge> {
  String? _status; // awaiting_proof | under_review | approved | rejected
  bool _loading = true;
  final _fn = FunctionsService();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final status = await _fn.getEnrollmentPaymentStatus(widget.enrollmentId);
      if (!mounted) return;
      setState(() {
        _status = status ?? 'awaiting_proof';
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _status = 'awaiting_proof';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Text('loading',
            style: TextStyle(fontSize: 11, color: Colors.grey)),
      );
    }
    final color = _status == 'approved'
        ? Colors.green
        : (_status == 'under_review'
            ? Colors.blue
            : (_status == 'rejected' ? Colors.red : Colors.orange));
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6)),
      child: Text(_status ?? 'awaiting_proof',
          style: TextStyle(
              fontSize: 11, color: color, fontWeight: FontWeight.w600)),
    );
  }
}
