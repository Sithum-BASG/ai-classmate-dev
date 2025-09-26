import 'package:flutter/material.dart';
import '../../theme.dart';

class AdminTutorApprovalsPage extends StatefulWidget {
  const AdminTutorApprovalsPage({super.key});

  @override
  State<AdminTutorApprovalsPage> createState() =>
      _AdminTutorApprovalsPageState();
}

class _AdminTutorApprovalsPageState extends State<AdminTutorApprovalsPage> {
  final List<Map<String, dynamic>> _pendingTutors = [
    {
      'id': 'DAP',
      'name': 'Dr. Anoja Perera',
      'email': 'anoja.perera@email.com',
      'phone': '+94 77 123 4567',
      'subjects': 'Mathematics A/L, Physics A/L',
      'experience': '10 years',
      'qualifications': 'PhD in Mathematics, University of Colombo',
      'bio':
          'Experienced mathematics tutor with strong background in A/L preparation.',
      'locations': ['Colombo 03', 'Colombo 07'],
      'documents': ['cv.pdf', 'certificate.pdf'],
      'appliedDate': '2024-12-15',
      'status': 'pending',
    },
  ];

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

            // Stats
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: isMobile ? 3 : 3,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: isMobile ? 1.2 : 2,
              children: [
                _buildStatCard(Icons.pending, '2', 'Pending', Colors.orange),
                _buildStatCard(
                    Icons.check_circle, '25', 'Approved', Colors.green),
                _buildStatCard(Icons.cancel, '3', 'Rejected', Colors.red),
              ],
            ),
            const SizedBox(height: 24),

            // Pending Tutors
            ..._pendingTutors.map((tutor) => _buildTutorCard(tutor, isMobile)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
      IconData icon, String value, String label, Color color) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
              value,
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
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
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
            color: Colors.black.withValues(alpha: 0.05),
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
                      backgroundColor:
                          AppTheme.brandPrimary.withValues(alpha: 0.1),
                      child: Text(
                        tutor['id'],
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
                              color: Colors.grey[600],
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
                    color: Colors.orange.withValues(alpha: 0.1),
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
                  backgroundColor: AppTheme.brandPrimary.withValues(alpha: 0.1),
                  child: Text(
                    tutor['id'],
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
                          style: TextStyle(color: Colors.grey[600])),
                      Text(tutor['phone'],
                          style: TextStyle(color: Colors.grey[600])),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
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
                        onPressed: () => _approveTutor(tutor),
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
                        onPressed: () => _rejectTutor(tutor),
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
                    onPressed: () => _approveTutor(tutor),
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
                    onPressed: () => _rejectTutor(tutor),
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

  void _approveTutor(Map<String, dynamic> tutor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${tutor['name']} has been approved'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _rejectTutor(Map<String, dynamic> tutor) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Tutor rejected'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }
}
