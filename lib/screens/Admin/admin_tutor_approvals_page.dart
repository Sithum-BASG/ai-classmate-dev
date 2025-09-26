import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../theme.dart';

class AdminTutorApprovalsPage extends StatefulWidget {
  const AdminTutorApprovalsPage({super.key});

  @override
  State<AdminTutorApprovalsPage> createState() =>
      _AdminTutorApprovalsPageState();
}

class _AdminTutorApprovalsPageState extends State<AdminTutorApprovalsPage> {
  final CollectionReference<Map<String, dynamic>> _tutorProfiles =
      FirebaseFirestore.instance.collection('tutor_profiles');
  // final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isActionBusy = false;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 16 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            if (isMobile)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tutor Approvals',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.filter_list, size: 16),
                          label: const Text('Filter'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.download, size: 16),
                          label: const Text('Export'),
                        ),
                      ),
                    ],
                  ),
                ],
              )
            else
              Row(
                children: [
                  const Text(
                    'Tutor Registration Approvals',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.filter_list),
                    label: const Text('Filter'),
                  ),
                  const SizedBox(width: 12),
                  TextButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.download),
                    label: const Text('Export'),
                  ),
                ],
              ),
            const SizedBox(height: 24),

            // Stats (live counts)
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: isMobile ? 3 : 3,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: isMobile ? 1.2 : 2,
              children: [
                _buildCountCard(
                  icon: Icons.pending,
                  color: Colors.orange,
                  label: 'Pending',
                  query: _tutorProfiles.where('status', isEqualTo: 'pending'),
                ),
                _buildCountCard(
                  icon: Icons.check_circle,
                  color: Colors.green,
                  label: 'Approved',
                  query: _tutorProfiles.where('status', isEqualTo: 'approved'),
                ),
                _buildCountCard(
                  icon: Icons.cancel,
                  color: Colors.red,
                  label: 'Rejected',
                  query: _tutorProfiles.where('status', isEqualTo: 'rejected'),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Pending Tutors
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _tutorProfiles
                  .where('status', isEqualTo: 'pending')
                  .orderBy(FieldPath.documentId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                }
                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(
                      'No pending tutor applications',
                      style: TextStyle(color: AppTheme.mutedText),
                    ),
                  );
                }
                return Column(
                  children: docs.map((doc) {
                    final data = doc.data();
                    return _buildTutorCard(
                      {
                        'uid': doc.id,
                        'name': data['full_name'] ?? 'Unknown',
                        'email': data['email'] ?? '',
                        'phone': data['phone'] ?? '',
                        'subjects':
                            (data['subjects_taught'] as List?)?.join(', ') ??
                                '-',
                        'experience': data['experience'] ?? '-',
                        'qualifications': data['qualifications'] ?? '-',
                        'bio': data['bio'] ?? '-',
                        'area_code': data['area_code'] ?? '-',
                        'status': data['status'] ?? 'pending',
                      },
                      isMobile,
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // _buildStatCard removed; replaced by live count cards

  Widget _buildCountCard({
    required IconData icon,
    required Color color,
    required String label,
    required Query<Map<String, dynamic>> query,
  }) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        final count = snapshot.data?.size ?? 0;
        return Container(
          padding: EdgeInsets.all(isMobile ? 12 : 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: isMobile ? 20 : 24, color: color),
              const SizedBox(height: 4),
              FittedBox(
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: isMobile ? 18 : 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: isMobile ? 11 : 13,
                  color: AppTheme.mutedText,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTutorCard(Map<String, dynamic> tutor, bool isMobile) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          if (isMobile)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 25,
                      backgroundColor: AppTheme.brandPrimary.withOpacity(0.1),
                      child: Text(
                        (tutor['name'] as String?)?.isNotEmpty == true
                            ? (tutor['name'] as String)[0].toUpperCase()
                            : 'T',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.brandPrimary,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tutor['name'],
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            tutor['email'],
                            style: TextStyle(
                              color: AppTheme.mutedText,
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Pending Review',
                    style: TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            )
          else
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppTheme.brandPrimary.withOpacity(0.1),
                  child: Text(
                    (tutor['name'] as String?)?.isNotEmpty == true
                        ? (tutor['name'] as String)[0].toUpperCase()
                        : 'T',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.brandPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tutor['name'],
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(tutor['email'],
                          style: TextStyle(color: AppTheme.mutedText)),
                      Text(tutor['phone'],
                          style: TextStyle(color: AppTheme.mutedText)),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Pending Review',
                    style: TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 16),

          // Details
          _buildInfoRow('Subjects:', tutor['subjects'], isMobile),
          const SizedBox(height: 8),
          _buildInfoRow('Experience:', tutor['experience'], isMobile),
          const SizedBox(height: 8),
          _buildInfoRow('Qualifications:', tutor['qualifications'], isMobile),
          const SizedBox(height: 12),

          // Bio
          Text('Bio:',
              style: TextStyle(
                  fontWeight: FontWeight.w600, fontSize: isMobile ? 13 : 14)),
          const SizedBox(height: 4),
          Text(tutor['bio'], style: TextStyle(fontSize: isMobile ? 12 : 14)),
          const SizedBox(height: 16),

          // Actions
          if (isMobile)
            Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed:
                            _isActionBusy ? null : () => _approveTutor(tutor),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Approve'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed:
                            _isActionBusy ? null : () => _rejectTutor(tutor),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                        ),
                        child: const Text('Reject'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.visibility, size: 16),
                  label: const Text('View Full Profile'),
                ),
              ],
            )
          else
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed:
                        _isActionBusy ? null : () => _approveTutor(tutor),
                    icon: const Icon(Icons.check),
                    label: const Text('Approve'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isActionBusy ? null : () => _rejectTutor(tutor),
                    icon: const Icon(Icons.close),
                    label: const Text('Reject'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.visibility),
                  label: const Text('View Profile'),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, bool isMobile) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: isMobile ? 80 : 100,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: isMobile ? 12 : 14,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(fontSize: isMobile ? 12 : 14),
          ),
        ),
      ],
    );
  }

  Future<void> _approveTutor(Map<String, dynamic> tutor) async {
    final uid = tutor['uid'] as String?;
    if (uid == null) return;
    setState(() => _isActionBusy = true);
    try {
      await _tutorProfiles.doc(uid).update({
        'status': 'approved',
        'reviewed_by': FirebaseAuth.instance.currentUser?.uid,
        'reviewed_at': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${tutor['name']} has been approved'),
          backgroundColor: AppTheme.brandSecondary,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to approve: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isActionBusy = false);
    }
  }

  void _rejectTutor(Map<String, dynamic> tutor) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reject Tutor'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Are you sure you want to reject ${tutor['name']}?'),
            const SizedBox(height: 16),
            TextField(
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Reason for rejection',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _isActionBusy
                ? null
                : () async {
                    Navigator.pop(dialogContext);
                    final uid = tutor['uid'] as String?;
                    if (uid == null) return;
                    setState(() => _isActionBusy = true);
                    try {
                      await _tutorProfiles.doc(uid).update({
                        'status': 'rejected',
                        'reviewed_by': FirebaseAuth.instance.currentUser?.uid,
                        'reviewed_at': FieldValue.serverTimestamp(),
                      });
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Tutor rejected'),
                          backgroundColor: Theme.of(context).colorScheme.error,
                        ),
                      );
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to reject: $e'),
                          backgroundColor: Theme.of(context).colorScheme.error,
                        ),
                      );
                    } finally {
                      if (mounted) setState(() => _isActionBusy = false);
                    }
                  },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }
}
