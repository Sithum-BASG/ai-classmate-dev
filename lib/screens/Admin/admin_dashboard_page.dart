import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme.dart';
import 'package:cloud_functions/cloud_functions.dart' as cloud_functions;
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'admin_tutor_approvals_page.dart';
import 'admin_class_management_page.dart';
import 'admin_payment_verification_page.dart';
import 'admin_announcements_page.dart';
import 'admin_analytics_page.dart';
import 'admin_user_management_page.dart';
import 'admin_settings_page.dart';
import 'admin_profile_page.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 900;
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: AppTheme.brandSurface,
      drawer: isMobile ? _buildMobileDrawer() : null,
      appBar: isMobile
          ? AppBar(
              title: Text(_getPageTitle(),
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w600)),
              leading: Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              ),
              actions: [
                TextButton.icon(
                  onPressed: _seedDemoData,
                  icon: const Icon(Icons.dataset, color: AppTheme.brandText),
                  label: const Text('Seed',
                      style: TextStyle(color: AppTheme.brandText)),
                ),
                IconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  onPressed: () {},
                ),
                IconButton(
                  icon: const Icon(Icons.home_outlined),
                  onPressed: () => context.go('/'),
                ),
              ],
            )
          : null,
      body: isDesktop
          ? Row(
              children: [
                // Desktop Sidebar
                Container(
                  width: 260,
                  color: AppTheme.brandPrimary,
                  child: _buildSidebarContent(),
                ),
                // Main Content
                Expanded(
                  child: Column(
                    children: [
                      // Top Bar for Desktop
                      Container(
                        height: 60,
                        color: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          children: [
                            Text(
                              _getPageTitle(),
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const Spacer(),
                            TextButton.icon(
                              onPressed: _seedDemoData,
                              icon: const Icon(Icons.dataset, size: 18),
                              label: const Text('Seed Demo Data'),
                            ),
                            Stack(
                              children: [
                                IconButton(
                                  icon:
                                      const Icon(Icons.notifications_outlined),
                                  onPressed: () {},
                                ),
                                Positioned(
                                  right: 8,
                                  top: 8,
                                  child: Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color:
                                          Theme.of(context).colorScheme.error,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 12),
                            IconButton(
                              icon: const Icon(Icons.arrow_back),
                              onPressed: () => context.go('/'),
                            ),
                            const SizedBox(width: 12),
                            TextButton(
                              onPressed: () => context.go('/'),
                              child: const Text('Home'),
                            ),
                          ],
                        ),
                      ),
                      // Page Content
                      Expanded(child: _buildPageContent()),
                    ],
                  ),
                ),
              ],
            )
          : _buildPageContent(),
    );
  }

  Future<void> _seedDemoData() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Seed Demo Data'),
        content: const Text(
            'This will create demo tutors, students, and classes. Proceed?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Seed')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await firebase_auth.FirebaseAuth.instance.currentUser?.getIdToken(true);
      final callable =
          cloud_functions.FirebaseFunctions.instanceFor(region: 'asia-south1')
              .httpsCallable('seedTestData');
      final res = await callable.call();
      final data = (res.data as Map?)?.cast<String, dynamic>() ?? {};
      final tutorsRaw = (data['tutors'] as List?) ?? const [];
      final studentsRaw = (data['students'] as List?) ?? const [];
      final tutors =
          tutorsRaw.map((e) => (e as Map).cast<String, dynamic>()).toList();
      final students =
          studentsRaw.map((e) => (e as Map).cast<String, dynamic>()).toList();
      final lines = <String>[];
      if (tutors.isNotEmpty) {
        lines.add('Tutors:');
        for (final t in tutors) {
          lines.add('• ${t['fullName']} — ${t['email']} / ${t['password']}');
        }
      }
      if (students.isNotEmpty) {
        lines.add('');
        lines.add('Students:');
        for (final s in students) {
          lines.add('• ${s['fullName']} — ${s['email']} / ${s['password']}');
        }
      }
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Seed Complete'),
          content: SingleChildScrollView(child: Text(lines.join('\n'))),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'))
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Seed failed: $e'),
            backgroundColor: Theme.of(context).colorScheme.error),
      );
    }
  }

  Widget _buildMobileDrawer() {
    return Drawer(
      backgroundColor: AppTheme.brandPrimary,
      child: _buildSidebarContent(),
    );
  }

  Widget _buildSidebarContent() {
    return Column(
      children: [
        // Logo Section
        Container(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.school,
                  color: AppTheme.brandText,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'ClassMate Admin',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (MediaQuery.of(context).size.width < 600)
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
            ],
          ),
        ),
        const Divider(color: Colors.white24, height: 1),
        const SizedBox(height: 20),
        // Navigation Items
        Expanded(
          child: ListView(
            children: [
              _buildNavItem(Icons.dashboard, 'Dashboard', 0),
              _buildNavItem(Icons.how_to_reg, 'Tutor Approvals', 1),
              _buildNavItem(Icons.class_, 'Class Management', 2),
              _buildNavItem(Icons.payment, 'Payment Verification', 3),
              _buildNavItem(Icons.campaign, 'Announcements', 4),
              _buildNavItem(Icons.analytics, 'Analytics & Reports', 5),
              _buildNavItem(Icons.people, 'User Management', 6),
              _buildNavItem(Icons.settings, 'Settings', 7),
              _buildNavItem(Icons.person_outline, 'Profile', 8),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _selectedIndex == index;
    final isMobile = MediaQuery.of(context).size.width < 600;

    return InkWell(
      onTap: () {
        setState(() => _selectedIndex = index);
        if (isMobile) {
          Navigator.pop(context);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color:
              isSelected ? Colors.white.withOpacity(0.1) : Colors.transparent,
          border: Border(
            left: BorderSide(
              color: isSelected ? Colors.white : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  String _getPageTitle() {
    switch (_selectedIndex) {
      case 0:
        return 'Dashboard';
      case 1:
        return 'Tutor Approvals';
      case 2:
        return 'Class Management';
      case 3:
        return 'Payment Verification';
      case 4:
        return 'Announcements';
      case 5:
        return 'Analytics & Reports';
      case 6:
        return 'User Management';
      case 7:
        return 'Settings';
      case 8:
        return 'Admin Profile';
      default:
        return 'Dashboard';
    }
  }

  Widget _buildPageContent() {
    switch (_selectedIndex) {
      case 0:
        return _buildDashboard();
      case 1:
        return const AdminTutorApprovalsPage();
      case 2:
        return const AdminClassManagementPage();
      case 3:
        return const AdminPaymentVerificationPage();
      case 4:
        return const AdminAnnouncementsPage();
      case 5:
        return const AdminAnalyticsPage();
      case 6:
        return const AdminUserManagementPage();
      case 7:
        return const AdminSettingsPage();
      case 8:
        return const AdminProfilePage();
      default:
        return _buildDashboard();
    }
  }

  Widget _buildDashboard() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final crossAxisCount = isMobile ? 2 : (screenWidth < 1200 ? 3 : 4);

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats Cards - Responsive Grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: isMobile ? 1.2 : 1.5,
            children: [
              _buildStatCard(
                Icons.people_outline,
                '247',
                'Total Students',
                AppTheme.brandPrimary,
              ),
              _buildStatCard(
                Icons.school,
                '38',
                'Active Tutors',
                AppTheme.brandSecondary,
              ),
              _buildStatCard(
                Icons.book,
                '145',
                'Total Classes',
                AppTheme.brandPrimaryDark,
              ),
              _buildStatCard(
                Icons.attach_money,
                'LKR 185K',
                'Monthly Revenue',
                AppTheme.brandSecondaryDark,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Pending Actions
          if (!isMobile)
            Row(
              children: [
                Expanded(
                  child: _buildPendingCard(
                    'Tutor Applications Pending',
                    '2 new tutors waiting for approval',
                    AppTheme.brandPrimary,
                    () => setState(() => _selectedIndex = 1),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildPendingCard(
                    'Classes Awaiting Approval',
                    '2 classes need review and approval',
                    AppTheme.brandSecondary,
                    () => setState(() => _selectedIndex = 2),
                  ),
                ),
              ],
            )
          else
            Column(
              children: [
                _buildPendingCard(
                  'Tutor Applications Pending',
                  '2 new tutors waiting for approval',
                  AppTheme.brandPrimary,
                  () => setState(() => _selectedIndex = 1),
                ),
                const SizedBox(height: 12),
                _buildPendingCard(
                  'Classes Awaiting Approval',
                  '2 classes need review and approval',
                  AppTheme.brandSecondary,
                  () => setState(() => _selectedIndex = 2),
                ),
              ],
            ),
          const SizedBox(height: 16),
          _buildPendingCard(
            'Payment Verifications Pending',
            '2 student payments need verification',
            AppTheme.brandSecondaryDark,
            () => setState(() => _selectedIndex = 3),
          ),

          const SizedBox(height: 24),

          // Recent Activity
          Container(
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
                Text(
                  'Recent Activity',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                _buildActivityItem(
                  'New tutor application',
                  'Dr. Anoja Perera',
                  '2 min ago',
                  AppTheme.brandPrimary,
                ),
                _buildActivityItem(
                  'Payment verified',
                  'Student payment LKR 2,500',
                  '15 min ago',
                  AppTheme.brandSecondary,
                ),
                _buildActivityItem(
                  'Class approved',
                  'Physics A/L Group Class',
                  '1 hour ago',
                  AppTheme.brandPrimaryDark,
                ),
                _buildActivityItem(
                  'Announcement sent',
                  'Platform maintenance notice',
                  '2 hours ago',
                  AppTheme.brandSecondaryDark,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    IconData icon,
    String value,
    String label,
    Color color,
  ) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: isMobile ? 24 : 32, color: color),
          const SizedBox(height: 8),
          FittedBox(
            child: Text(
              value,
              style: TextStyle(
                fontSize: isMobile ? 20 : 28,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: isMobile ? 11 : 14,
              color: AppTheme.mutedText,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPendingCard(
    String title,
    String subtitle,
    Color color,
    VoidCallback onTap,
  ) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(isMobile ? 16 : 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border(left: BorderSide(color: color, width: 4)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: isMobile ? 14 : 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: isMobile ? 12 : 14,
                      color: AppTheme.mutedText,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 12 : 16,
                  vertical: isMobile ? 8 : 12,
                ),
              ),
              child: Text(
                'Review',
                style: TextStyle(fontSize: isMobile ? 12 : 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(
    String title,
    String subtitle,
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
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: isMobile ? 13 : 14,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: isMobile ? 12 : 13,
                    color: AppTheme.mutedText,
                  ),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: TextStyle(
              fontSize: isMobile ? 11 : 12,
              color: AppTheme.mutedText,
            ),
          ),
        ],
      ),
    );
  }
}
