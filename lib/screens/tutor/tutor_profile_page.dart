import 'package:flutter/material.dart';
import 'dart:io';
import 'package:go_router/go_router.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme.dart';
import '../../config/areas.dart';
import '../../config/subjects.dart';

class TutorProfilePage extends StatefulWidget {
  const TutorProfilePage({super.key});

  @override
  State<TutorProfilePage> createState() => _TutorProfilePageState();
}

class _TutorProfilePageState extends State<TutorProfilePage> {
  int _selectedIndex = 3;
  String? _profileImagePath;

  String _areaNameForCode(String? code) {
    if (code == null || code.isEmpty) return '-';
    final match = kAreaOptions.firstWhere(
      (a) => a.code == code,
      orElse: () => const AreaOption(code: '', name: ''),
    );
    return match.name.isNotEmpty ? match.name : code;
  }

  String _subjectsLabel(List<dynamic>? values) {
    if (values == null || values.isEmpty) return '-';
    final codeToLabel = {for (final s in kSubjectOptions) s.code: s.label};
    return values
        .map((v) => v is String ? (codeToLabel[v] ?? v) : v?.toString() ?? '')
        .where((s) => s.isNotEmpty)
        .join(', ');
  }

  void _onBottomNavTap(int index) {
    setState(() => _selectedIndex = index);
    switch (index) {
      case 0:
        context.go('/tutor');
        break;
      case 1:
        context.go('/tutor/classes');
        break;
      case 2:
        context.go('/tutor/messages');
        break;
      case 3:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final Stream<DocumentSnapshot<Map<String, dynamic>>>? docStream =
        user == null
            ? null
            : FirebaseFirestore.instance
                .collection('tutor_profiles')
                .doc(user.uid)
                .snapshots();

    return Scaffold(
      backgroundColor: AppTheme.brandSurface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/tutor'),
        ),
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _navigateToEditProfile(),
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: docStream,
        builder: (context, snapshot) {
          if (user == null) {
            return const Center(child: Text('Please sign in as a tutor.'));
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Failed to load profile'),
                    const SizedBox(height: 8),
                    Text('${snapshot.error}',
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.error)),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () => setState(() {}),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data?.data() ?? <String, dynamic>{};
          return _buildProfileContent(context, user, data);
        },
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onBottomNavTap,
        backgroundColor: Colors.white,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.class_outlined),
            selectedIcon: Icon(Icons.class_),
            label: 'Classes',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            selectedIcon: Icon(Icons.chat_bubble),
            label: 'Messages',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildProfileContent(
      BuildContext context, User user, Map<String, dynamic> data) {
    final fullName =
        (data['full_name'] as String?) ?? (user.displayName ?? 'Tutor');
    final subjects = _subjectsLabel(data['subjects_taught'] as List?);
    final areaName = _areaNameForCode(data['area_code'] as String?);
    final status = (data['status'] as String?) ?? 'pending';
    // Compute rating live from ratings subcollection
    final String tutorId = user.uid;
    final experience = (data['experience'] as String?) ?? '-';
    final qualifications = (data['qualifications'] as String?) ?? '-';
    final about = (data['about'] as String?) ?? '-';
    final totalStudents = (data['total_students'] is num)
        ? (data['total_students'] as num).toInt()
        : 0;
    final activeClasses = (data['active_classes'] is num)
        ? (data['active_classes'] as num).toInt()
        : 0;

    return SingleChildScrollView(
      child: Column(
        children: [
          // Profile Header
          Container(
            width: double.infinity,
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 30),
            child: Column(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: AppTheme.brandPrimary.withOpacity(0.1),
                      backgroundImage: _profileImagePath != null
                          ? FileImage(File(_profileImagePath!))
                          : null,
                      child: _profileImagePath == null
                          ? const Icon(
                              Icons.person,
                              size: 60,
                              color: AppTheme.brandPrimary,
                            )
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppTheme.brandPrimary,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 3,
                          ),
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 20,
                          ),
                          onPressed: () => _showImagePickerOptions(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  fullName,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.brandText,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user.email ?? '',
                  style: TextStyle(fontSize: 13, color: AppTheme.mutedText),
                ),
                const SizedBox(height: 4),
                Text(
                  subjects,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: status == 'approved'
                        ? Colors.green.withOpacity(0.1)
                        : status == 'rejected'
                            ? Colors.red.withOpacity(0.1)
                            : Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status[0].toUpperCase() + status.substring(1),
                    style: TextStyle(
                      color: status == 'approved'
                          ? Colors.green[700]
                          : status == 'rejected'
                              ? Colors.red[700]
                              : Colors.orange[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('tutor_profiles')
                      .doc(tutorId)
                      .collection('ratings')
                      .snapshots(),
                  builder: (context, snap) {
                    final docs = snap.data?.docs ?? [];
                    double avg = 0.0;
                    for (final d in docs) {
                      avg += (d.data()['rating'] as num?)?.toDouble() ?? 0;
                    }
                    final count = docs.length;
                    avg = count == 0 ? 0.0 : avg / count;
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ...List.generate(5, (index) {
                          return Icon(
                            index < avg.floor()
                                ? Icons.star
                                : Icons.star_border,
                            size: 20,
                            color: Colors.amber,
                          );
                        }),
                        const SizedBox(width: 8),
                        Text(
                          '${avg.toStringAsFixed(1)} ($count reviews)',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () => _navigateToEditProfile(),
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Edit Profile'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.brandPrimary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Stats Cards
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    Icons.people,
                    totalStudents.toString(),
                    'Total Students',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    Icons.class_,
                    activeClasses.toString(),
                    'Active Classes',
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Profile Information
          Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Profile Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _buildInfoRow('Experience:', experience),
                _buildInfoRow('Location:', areaName),
                _buildInfoRow('Qualifications:', qualifications),
                const SizedBox(height: 12),
                const Text(
                  'About:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  about,
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),

          // Quick Actions
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
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
                      'Quick Actions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.notifications_outlined),
                      onPressed: () => context.push('/tutor/announcements'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ListTile(
                  leading:
                      const Icon(Icons.payment, color: AppTheme.brandPrimary),
                  title: const Text('Payment & Subscription'),
                  subtitle: const Text('Manage your subscription'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.go('/tutor/subscription'),
                ),
                ListTile(
                  leading: const Icon(Icons.star, color: Colors.amber),
                  title: const Text('Reviews & Ratings'),
                  subtitle: const Text('View student feedback'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.go('/tutor/reviews'),
                ),
                ListTile(
                  leading: const Icon(Icons.settings, color: Colors.grey),
                  title: const Text('Settings'),
                  subtitle: const Text('App settings and preferences'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {},
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text(
                    'Logout',
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () => _showLogoutDialog(),
                ),
              ],
            ),
          ),

          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildStatCard(IconData icon, String value, String label) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: AppTheme.brandPrimary, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
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
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Choose Profile Photo',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildImageOption(
                  Icons.camera_alt,
                  'Camera',
                  () {
                    Navigator.pop(context);
                    // TODO: Implement camera
                  },
                ),
                _buildImageOption(
                  Icons.photo_library,
                  'Gallery',
                  () {
                    Navigator.pop(context);
                    // TODO: Implement gallery
                  },
                ),
                if (_profileImagePath != null)
                  _buildImageOption(
                    Icons.delete,
                    'Remove',
                    () {
                      Navigator.pop(context);
                      setState(() {
                        _profileImagePath = null;
                      });
                    },
                    color: Colors.red,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageOption(IconData icon, String label, VoidCallback onTap,
      {Color? color}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: color ?? AppTheme.brandPrimary,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: color ?? AppTheme.brandText,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToEditProfile() {
    context.push('/tutor/profile/edit');
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              context.go('/');
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
