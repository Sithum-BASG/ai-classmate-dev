import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildInfoColumn(
                              'Students', '$students/$maxStudents'),
                          _buildInfoColumn('Price', 'Rs. $price'),
                          _buildInfoColumn('Total Income', 'Rs. $totalIncome',
                              isHighlighted: true),
                        ],
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
                  // TODO: Replace with real enrollments stream when available
                  ...const <Map<String, dynamic>>[].map((student) {
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
                              'ST',
                              style: const TextStyle(
                                color: AppTheme.brandPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Student Name',
                                    style:
                                        TextStyle(fontWeight: FontWeight.w600)),
                                Text('Grade',
                                    style: TextStyle(
                                        fontSize: 12, color: Colors.grey[600])),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text('status',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.blue,
                                    fontWeight: FontWeight.w600)),
                          ),
                          PopupMenuButton<String>(
                            onSelected: (value) {
                              // hook when enrollments wired
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'remove',
                                child: Text('Remove',
                                    style: TextStyle(color: Colors.red)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),

            const SizedBox(height: 20),

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
    // TODO: Navigate to message composition for class
    context.go('/tutor/messages/compose?classId=${widget.classId}');
  }

  void _manageStudents() {
    // TODO: Navigate to student management for this class
  }
}
