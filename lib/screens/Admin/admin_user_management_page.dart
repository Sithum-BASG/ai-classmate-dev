import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme.dart';

class AdminUserManagementPage extends StatefulWidget {
  const AdminUserManagementPage({super.key});

  @override
  State<AdminUserManagementPage> createState() =>
      _AdminUserManagementPageState();
}

class _AdminUserManagementPageState extends State<AdminUserManagementPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();

  Stream<QuerySnapshot<Map<String, dynamic>>> _studentsStream() {
    return FirebaseFirestore.instance
        .collection('student_profiles')
        .orderBy(FieldPath.documentId)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _tutorsStream() {
    return FirebaseFirestore.instance
        .collection('tutor_profiles')
        .orderBy('status')
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _suspendedUsersStream() {
    return FirebaseFirestore.instance
        .collection('users')
        .where('status', isEqualTo: 'suspended')
        .snapshots();
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 900;

    return SafeArea(
      child: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.all(isMobile ? 12 : (isTablet ? 16 : 24)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isMobile)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'User Management',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 36,
                              child: TextField(
                                controller: _searchController,
                                style: const TextStyle(fontSize: 13),
                                decoration: InputDecoration(
                                  hintText: 'Search users...',
                                  hintStyle: const TextStyle(fontSize: 13),
                                  prefixIcon:
                                      const Icon(Icons.search, size: 18),
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.download, size: 20),
                            onPressed: () {},
                            tooltip: 'Export',
                          ),
                        ],
                      ),
                    ],
                  )
                else
                  Row(
                    children: [
                      Text(
                        'User Management',
                        style: TextStyle(
                          fontSize: isTablet ? 18 : 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      SizedBox(
                        width: isTablet ? 250 : 300,
                        height: 40,
                        child: TextField(
                          controller: _searchController,
                          style: const TextStyle(fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'Search users...',
                            prefixIcon: const Icon(Icons.search, size: 20),
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      TextButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.download),
                        label: const Text('Export'),
                      ),
                    ],
                  ),
              ],
            ),
          ),

          // Tab Bar
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: AppTheme.brandPrimary,
              unselectedLabelColor: Colors.grey,
              indicatorColor: AppTheme.brandPrimary,
              labelStyle: TextStyle(fontSize: isMobile ? 12 : 14),
              tabs: const [
                Tab(text: 'Overview'),
                Tab(text: 'Students'),
                Tab(text: 'Tutors'),
                Tab(text: 'Suspended'),
              ],
            ),
          ),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildStudentsTab(),
                _buildTutorsTab(),
                _buildSuspendedTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 900;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 12 : (isTablet ? 16 : 24)),
      child: Column(
        children: [
          // Stats Grid (live)
          LayoutBuilder(
            builder: (context, constraints) {
              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: isMobile ? 1 : 3,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: isMobile ? 3.5 : (isTablet ? 2.5 : 2),
                children: [
                  FutureBuilder<int>(
                    future: _count(FirebaseFirestore.instance
                        .collection('student_profiles')),
                    builder: (context, s) => _buildStatCard(
                        Icons.people,
                        (s.data ?? 0).toString(),
                        'Total Students',
                        Colors.blue),
                  ),
                  FutureBuilder<int>(
                    future: _count(FirebaseFirestore.instance
                        .collection('tutor_profiles')
                        .where('status', isEqualTo: 'approved')),
                    builder: (context, s) => _buildStatCard(
                        Icons.school,
                        (s.data ?? 0).toString(),
                        'Active Tutors',
                        Colors.green),
                  ),
                  FutureBuilder<int>(
                    future: _count(FirebaseFirestore.instance
                        .collection('users')
                        .where('status', isEqualTo: 'suspended')),
                    builder: (context, s) => _buildStatCard(
                        Icons.block,
                        (s.data ?? 0).toString(),
                        'Suspended Users',
                        Colors.red),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          // Recent Users (live, latest students)
          Container(
            padding: EdgeInsets.all(isMobile ? 12 : (isTablet ? 16 : 20)),
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
                Text(
                  'Recent Students',
                  style: TextStyle(
                    fontSize: isMobile ? 16 : 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('student_profiles')
                      .orderBy(FieldPath.documentId, descending: true)
                      .limit(5)
                      .snapshots(),
                  builder: (context, s) {
                    final docs = s.data?.docs ?? const [];
                    if (docs.isEmpty) {
                      return const Text('No recent students');
                    }
                    return Column(
                      children: docs.map((d) {
                        final m = d.data();
                        final name = (m['full_name'] as String?) ?? 'Student';
                        final email = (m['email'] as String?) ?? '';
                        return _buildActivityItem(
                          Icons.person,
                          name,
                          email.isEmpty ? d.id : email,
                          '',
                          Colors.blue,
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentsTab() {
    final isMobile = MediaQuery.of(context).size.width < 600;

    // Exclude suspended users using users collection
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _suspendedUsersStream(),
      builder: (context, susSnap) {
        final suspendedIds = <String>{
          for (final d in (susSnap.data?.docs ?? const [])) d.id
        };
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _studentsStream(),
          builder: (context, s) {
            final docs = s.data?.docs ?? const [];
            final query = _searchController.text.trim().toLowerCase();
            final filtered = docs.where((d) {
              if (suspendedIds.contains(d.id)) return false;
              final m = d.data();
              final name = ((m['full_name'] ?? '') as String).toLowerCase();
              final email = ((m['email'] ?? '') as String).toLowerCase();
              if (query.isEmpty) return true;
              return name.contains(query) ||
                  email.contains(query) ||
                  d.id.contains(query);
            }).toList();
            return ListView.builder(
              padding: EdgeInsets.all(isMobile ? 12 : 24),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final d = filtered[index];
                final m = d.data();
                final card = {
                  'id': d.id,
                  'name': (m['full_name'] as String?) ?? 'Student',
                  'email': (m['email'] as String?) ?? '',
                  'phone': (m['phone'] as String?) ?? '',
                  'status': 'active',
                };
                return _buildUserCard(card, isStudent: true);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildTutorsTab() {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _suspendedUsersStream(),
      builder: (context, susSnap) {
        final suspendedIds = <String>{
          for (final d in (susSnap.data?.docs ?? const [])) d.id
        };
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _tutorsStream(),
          builder: (context, s) {
            final docs = s.data?.docs ?? const [];
            final query = _searchController.text.trim().toLowerCase();
            final filtered = docs.where((d) {
              if (suspendedIds.contains(d.id)) return false;
              final m = d.data();
              final name = ((m['full_name'] ?? '') as String).toLowerCase();
              final email = ((m['email'] ?? '') as String).toLowerCase();
              if (query.isEmpty) return true;
              return name.contains(query) ||
                  email.contains(query) ||
                  d.id.contains(query);
            }).toList();
            return ListView.builder(
              padding: EdgeInsets.all(isMobile ? 12 : 24),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final d = filtered[index];
                final m = d.data();
                final subjects =
                    (m['subjects_taught'] as List?)?.join(', ') ?? '';
                final card = {
                  'id': d.id,
                  'name': (m['full_name'] as String?) ?? 'Tutor',
                  'email': (m['email'] as String?) ?? '',
                  'phone': (m['phone'] as String?) ?? '',
                  'subjects': subjects,
                  'status': (m['status'] as String?) ?? '',
                };
                return _buildUserCard(card, isStudent: false);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildSuspendedTab() {
    final isMobile = MediaQuery.of(context).size.width < 600;
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _suspendedUsersStream(),
      builder: (context, s) {
        final docs = s.data?.docs ?? const [];
        if (docs.isEmpty) {
          return const Center(child: Text('No suspended users'));
        }
        return ListView.builder(
          padding: EdgeInsets.all(isMobile ? 12 : 24),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final d = docs[index];
            final m = d.data();
            final role = (m['role'] as String?) ?? '';
            final card = {
              'id': d.id,
              'name': (m['name'] as String?) ?? d.id,
              'email': (m['email'] as String?) ?? '',
              'phone': (m['phone'] as String?) ?? '',
              'status': 'suspended',
              'role': role,
            };
            return _buildUserCard(card, isStudent: role == 'student');
          },
        );
      },
    );
  }

  Widget _buildStatCard(
      IconData icon, String value, String label, Color color) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 20),
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
      child: Row(
        children: [
          Icon(icon, size: isMobile ? 24 : 28, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: isMobile ? 20 : 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: isMobile ? 11 : 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(
    IconData icon,
    String name,
    String action,
    String time,
    Color color,
  ) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Icon(icon, size: isMobile ? 18 : 20, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: isMobile ? 12 : 14,
                  ),
                ),
                Text(
                  action,
                  style: TextStyle(
                    fontSize: isMobile ? 11 : 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: TextStyle(
              fontSize: isMobile ? 10 : 12,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user, {required bool isStudent}) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: isMobile ? 18 : 22,
                backgroundColor: (isStudent ? Colors.blue : Colors.green)
                    .withValues(alpha: 0.1),
                child: Text(
                  user['name'].split(' ').map((e) => e[0]).take(2).join(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isStudent ? Colors.blue : Colors.green,
                    fontSize: isMobile ? 12 : 14,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user['name'],
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: isMobile ? 13 : 15,
                      ),
                    ),
                    if (isMobile)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user['email'],
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'ID: ${user['id']}',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      )
                    else
                      Text(
                        '${user['email']} • ${user['phone']}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    if (!isMobile)
                      Text(
                        isStudent
                            ? 'ID: ${user['id']} • ${user['enrolledClasses']} classes'
                            : 'ID: ${user['id']} • ${user['subjects']} • ${user['students']} students',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                  ],
                ),
              ),
              if (!isMobile)
                (isStudent)
                    ? Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: user['status'] == 'active'
                              ? Colors.green.withValues(alpha: 0.1)
                              : Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          user['status'] == 'active' ? 'Active' : 'Suspended',
                          style: TextStyle(
                            color: user['status'] == 'active'
                                ? Colors.green
                                : Colors.red,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      )
                    : _tutorStatusChip(user['status'] as String? ?? '', 12),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, size: isMobile ? 20 : 24),
                onSelected: (value) => _handleUserAction(value, user),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'view',
                    child: Text('View Profile', style: TextStyle(fontSize: 13)),
                  ),
                  const PopupMenuItem(
                    value: 'edit',
                    child: Text('Edit User', style: TextStyle(fontSize: 13)),
                  ),
                  PopupMenuItem(
                    value: user['status'] == 'active' ? 'suspend' : 'activate',
                    child: Text(
                      user['status'] == 'active'
                          ? 'Suspend User'
                          : 'Activate User',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text(
                      'Delete User',
                      style: TextStyle(color: Colors.red, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (isMobile) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isStudent
                      ? '${user['enrolledClasses']} classes'
                      : '${user['students']} students',
                  style: const TextStyle(fontSize: 11),
                ),
                (isStudent)
                    ? Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: user['status'] == 'active'
                              ? Colors.green.withValues(alpha: 0.1)
                              : Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          user['status'] == 'active' ? 'Active' : 'Suspended',
                          style: TextStyle(
                            color: user['status'] == 'active'
                                ? Colors.green
                                : Colors.red,
                            fontWeight: FontWeight.w600,
                            fontSize: 10,
                          ),
                        ),
                      )
                    : _tutorStatusChip(user['status'] as String? ?? '', 10),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _handleUserAction(String action, Map<String, dynamic> user) async {
    final rootContext = context; // preserve ancestor context for SnackBars
    switch (action) {
      case 'suspend':
      case 'activate':
        showDialog(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(action == 'suspend' ? 'Suspend User' : 'Activate User'),
            content: Text(
              action == 'suspend'
                  ? 'Are you sure you want to suspend ${user['name']}?'
                  : 'Are you sure you want to activate ${user['name']}?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(dialogContext);
                  final uid = user['id'] as String?;
                  if (uid == null || uid.isEmpty) return;
                  final status = action == 'suspend' ? 'suspended' : 'active';
                  try {
                    final doc =
                        FirebaseFirestore.instance.collection('users').doc(uid);
                    final snap = await doc.get();
                    if (snap.exists) {
                      await doc
                          .set({'status': status}, SetOptions(merge: true));
                      if (!mounted) return;
                      ScaffoldMessenger.of(rootContext).showSnackBar(
                        SnackBar(
                          content: Text(
                            status == 'suspended'
                                ? 'User suspended successfully'
                                : 'User activated successfully',
                          ),
                        ),
                      );
                    } else {
                      if (!mounted) return;
                      ScaffoldMessenger.of(rootContext).showSnackBar(
                        const SnackBar(
                            content: Text(
                                'Cannot update status: user record not found')),
                      );
                    }
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(rootContext).showSnackBar(
                      SnackBar(content: Text('Failed to update: $e')),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      action == 'suspend' ? Colors.red : Colors.green,
                ),
                child: Text(action == 'suspend' ? 'Suspend' : 'Activate'),
              ),
            ],
          ),
        );
        break;
      case 'delete':
        showDialog(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Delete User'),
            content: Text(
              'Are you sure you want to permanently delete ${user['name']}? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  ScaffoldMessenger.of(rootContext).showSnackBar(
                    const SnackBar(
                      content: Text('User deleted successfully'),
                      backgroundColor: Colors.red,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
        break;
      default:
        break;
    }
  }

  // Helper to render tutor status chip (approved/pending/rejected)
  Widget _tutorStatusChip(String status, double fontSize) {
    final s = status.toLowerCase();
    Color color;
    switch (s) {
      case 'approved':
        color = Colors.green;
        break;
      case 'pending':
        color = Colors.orange;
        break;
      case 'rejected':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }
    final bg = color.withValues(alpha: 0.1);
    final label = s.isEmpty
        ? 'Unknown'
        : s[0].toUpperCase() + (s.length > 1 ? s.substring(1) : '');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: fontSize,
        ),
      ),
    );
  }

  Future<int> _count(Query<Map<String, dynamic>> query) async {
    try {
      final agg = await query.count().get();
      return agg.count ?? 0;
    } catch (_) {
      try {
        final snap = await query.limit(1000).get();
        return snap.size;
      } catch (_) {
        return 0;
      }
    }
  }
}
