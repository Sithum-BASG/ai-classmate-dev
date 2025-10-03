import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../../theme.dart';

class TutorDashboardPage extends StatefulWidget {
  const TutorDashboardPage({super.key});

  @override
  State<TutorDashboardPage> createState() => _TutorDashboardPageState();
}

class _TutorDashboardPageState extends State<TutorDashboardPage> {
  int _selectedIndex = 0;
  final String _tutorName = "Mr. Kamal Silva";
  final int _activeStudents = 5;
  final double _monthlyIncome = 48000;
  final DateTime _nextPaymentDate = DateTime(2025, 1, 15);
  Future<QuerySnapshot<Map<String, dynamic>>>? _myClassesFuture;

  // Removed mock _todaySchedule in favor of live Firestore data

  void _onBottomNavTap(int index) {
    setState(() => _selectedIndex = index);
    switch (index) {
      case 0:
        break;
      case 1:
        context.push('/tutor/classes');
        break;
      case 2:
        context.push('/tutor/messages');
        break;
      case 3:
        context.push('/tutor/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _checkApproved(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final approved = snapshot.data == true;
        if (!approved) {
          return Scaffold(
            backgroundColor: AppTheme.brandSurface,
            appBar: AppBar(title: const Text('Tutor Dashboard')),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.hourglass_top,
                        size: 64, color: AppTheme.brandPrimary),
                    const SizedBox(height: 12),
                    const Text('Your tutor account is awaiting approval.',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    const Text('Please check back later or contact support.'),
                    const SizedBox(height: 16),
                    TextButton(
                        onPressed: () => context.go('/'),
                        child: const Text('Back to Home')),
                  ],
                ),
              ),
            ),
          );
        }
        return _approvedDashboard(context);
      },
    );
  }

  Future<bool> _checkApproved() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('tutor_profiles')
          .doc(user.uid)
          .get();
      final data = doc.data();
      if (data == null) return false;
      final status = (data['status'] as String?) ?? '';
      if (status == 'approved') return true;
      if (status == 'rejected') {
        if (mounted) {
          // Redirect to rejection screen with actions
          // ignore: use_build_context_synchronously
          context.go('/tutor/pending?rejected=1');
        }
        return false;
      }
    } catch (_) {}
    return false;
  }

  Future<QuerySnapshot<Map<String, dynamic>>> _loadMyClasses() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Stream<QuerySnapshot<Map<String, dynamic>>>.empty()
          .first; // returns an empty snapshot
    }
    return FirebaseFirestore.instance
        .collection('classes')
        .where('tutorId', isEqualTo: user.uid)
        .where('status', whereIn: ['draft', 'published']).get();
  }

  Future<List<Map<String, dynamic>>> _fetchTodaySessions(
      Map<String, Map<String, dynamic>> classById) async {
    final publishedIds = classById.entries
        .where((e) => (e.value['status'] as String?) == 'published')
        .map((e) => e.key)
        .toList();
    if (publishedIds.isEmpty) return [];

    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1));

    // Fetch per-class to satisfy rules and avoid whereIn/10 limit
    final List<Map<String, dynamic>> items = [];
    for (final classId in publishedIds) {
      final snap = await FirebaseFirestore.instance
          .collection('classes')
          .doc(classId)
          .collection('sessions')
          .where('start_time', isGreaterThanOrEqualTo: start)
          .where('start_time', isLessThan: end)
          .get();
      for (final d in snap.docs) {
        final s = d.data();
        final ts = s['start_time'];
        DateTime? startDt;
        if (ts is Timestamp) startDt = ts.toDate();
        if (startDt == null) continue;
        final c = classById[classId] ?? <String, dynamic>{};
        items.add({
          'classId': classId,
          'start': startDt,
          'name': (c['name'] as String?) ?? 'Class',
          'type': (c['type'] as String?) ?? 'Group',
          'students': (c['enrolled_count'] as num?)?.toInt() ?? 0,
        });
      }
    }
    items.sort(
        (a, b) => (a['start'] as DateTime).compareTo(b['start'] as DateTime));
    return items;
  }

  Widget _approvedDashboard(BuildContext context) {
    _myClassesFuture ??= _loadMyClasses();
    return Scaffold(
      backgroundColor: AppTheme.brandSurface,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'ClassMate Tutor',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.brandText,
                              ),
                            ),
                            Text(
                              _tutorName,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.black87,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              'Manage your teaching business',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.notifications_outlined),
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Stats Row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => context.push('/tutor/students'),
                        borderRadius: BorderRadius.circular(12),
                        child: _buildStatCard(
                          Icons.people,
                          _activeStudents.toString(),
                          'Active Students',
                          Colors.blue,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        Icons.attach_money,
                        'LKR ${(_monthlyIncome / 1000).toStringAsFixed(0)}K',
                        'Monthly Income',
                        Colors.green,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Subscription Status
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.green.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: Colors.green[700],
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Subscription Status',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Active',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Monthly Platform Fee: LKR 5,000',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Next payment due: ${_nextPaymentDate.day.toString().padLeft(2, '0')}/${_nextPaymentDate.month.toString().padLeft(2, '0')}/${_nextPaymentDate.year}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Today's Schedule
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Today's Schedule",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => context.push('/tutor/class/new'),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('New Class'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.brandText,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Schedule List (live from Firestore)
              FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
                future: _myClassesFuture,
                builder: (context, classesSnap) {
                  if (classesSnap.connectionState != ConnectionState.done) {
                    return const Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  final classDocs = classesSnap.data?.docs ?? [];
                  if (classDocs.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Text('No classes yet.'),
                    );
                  }
                  // Map for quick lookup
                  final Map<String, Map<String, dynamic>> classById = {
                    for (final d in classDocs) d.id: d.data(),
                  };
                  return FutureBuilder<List<Map<String, dynamic>>>(
                    future: _fetchTodaySessions(classById),
                    builder: (context, sessSnap) {
                      if (sessSnap.connectionState != ConnectionState.done) {
                        return const Padding(
                          padding: EdgeInsets.all(20),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      final sessions = sessSnap.data ?? const [];
                      if (sessions.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20),
                          child: Text('No sessions today.'),
                        );
                      }
                      return Column(
                        children: sessions.map((item) {
                          final classId = item['classId'] as String;
                          final name = item['name'] as String;
                          final type = item['type'] as String;
                          final students = item['students'] as int;
                          final startDt = item['start'] as DateTime;
                          final hour =
                              startDt.hour % 12 == 0 ? 12 : startDt.hour % 12;
                          final minute =
                              startDt.minute.toString().padLeft(2, '0');
                          final ampm = startDt.hour >= 12 ? 'PM' : 'AM';
                          final timeLabel = '$hour:$minute $ampm';
                          return Container(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: const Border(
                                left: BorderSide(
                                  color: AppTheme.brandPrimary,
                                  width: 4,
                                ),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ListTile(
                              onTap: () =>
                                  context.push('/tutor/class/$classId'),
                              title: Text(
                                name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600),
                              ),
                              subtitle: Row(
                                children: [
                                  Icon(Icons.access_time,
                                      size: 14, color: Colors.grey[600]),
                                  const SizedBox(width: 4),
                                  Text(timeLabel),
                                  const SizedBox(width: 12),
                                  Icon(Icons.people,
                                      size: 14, color: Colors.grey[600]),
                                  const SizedBox(width: 4),
                                  Text('$students students'),
                                ],
                              ),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _getTypeColor(type)
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  type,
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: _getTypeColor(type),
                                      fontWeight: FontWeight.w600),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    },
                  );
                },
              ),

              const SizedBox(height: 80),
            ],
          ),
        ),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/tutor/students'),
        backgroundColor: AppTheme.brandPrimary,
        child: const Icon(Icons.people, color: Colors.white),
        tooltip: 'View Students',
      ),
    );
  }

  Widget _buildStatCard(
      IconData icon, String value, String label, Color color) {
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
        children: [
          Icon(icon, color: color, size: 28),
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
}
