import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:go_router/go_router.dart';
import '../theme.dart';

class StudentDashboardPage extends StatefulWidget {
  const StudentDashboardPage({super.key});

  @override
  State<StudentDashboardPage> createState() => _StudentDashboardPageState();
}

class _StudentDashboardPageState extends State<StudentDashboardPage> {
  int _selectedIndex = 0;
  String _userName = "...";
  final TextEditingController _searchController = TextEditingController();

  // Removed mock enrolled classes; will stream real enrollments

  final List<Map<String, dynamic>> _aiRecommendations = [
    {
      'type': 'schedule',
      'title': 'Recommended Study Schedule',
      'description':
          'Based on your performance, focus more on Organic Chemistry this week',
      'priority': 'High Priority',
      'icon': Icons.calendar_today,
      'color': const Color(0xFFFEE2E2),
      'borderColor': Colors.red.shade400,
    },
    {
      'type': 'tutor',
      'title': 'Perfect Tutor Match Found!',
      'description':
          'Mr. Jayasinghe specializes in A/L Biology and is available in your area',
      'priority': null,
      'icon': Icons.person_search,
      'color': const Color(0xFFE0F2FE),
      'borderColor': const Color(0xFF2563EB),
    },
  ];

  Future<List<Map<String, dynamic>>> _fetchTopRecommendedClasses() async {
    try {
      await FirebaseAuth.instance.currentUser?.getIdToken(true);
      final callable = FirebaseFunctions.instanceFor(region: 'asia-south1')
          .httpsCallable('getRecommendationsRealtime');
      final res = await callable.call({'limit': 2, 'debug': false});
      final data = (res.data as Map?)?.cast<String, dynamic>() ?? {};
      final results = ((data['results'] as List?) ?? [])
          .map((e) => (e as Map).cast<String, dynamic>())
          .toList();
      // Fetch classes for each result
      final out = <Map<String, dynamic>>[];
      for (final r in results) {
        final classId = (r['classId'] ?? r['class_id'])?.toString();
        final score = (r['score'] as num?)?.toDouble() ?? 0.0;
        if (classId == null || classId.isEmpty) continue;
        final snap = await FirebaseFirestore.instance
            .collection('classes')
            .doc(classId)
            .get();
        if (!snap.exists) continue;
        final c = snap.data() ?? <String, dynamic>{};
        out.add({'classId': classId, 'score': score, 'class': c});
      }
      out.sort(
          (a, b) => (b['score'] as double).compareTo(a['score'] as double));
      return out;
    } catch (_) {
      return const <Map<String, dynamic>>[];
    }
  }

  Widget _buildRecClassCard(Map<String, dynamic> item) {
    final c = (item['class'] as Map<String, dynamic>);
    final classId = item['classId'] as String;
    final name = (c['name'] as String?) ?? 'Class';
    final mode = (c['mode'] as String?) ?? 'In-person';
    final type = (c['type'] as String?) ?? 'Group';
    final grade = (c['grade'] as num?)?.toInt();
    final price = (c['price'] as num?)?.toInt() ?? 0;
    final tutorId = (c['tutorId'] as String?) ?? '';
    final score = (item['score'] as num).toDouble();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.go('/class/$classId'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (tutorId.isNotEmpty)
                          FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                            future: FirebaseFirestore.instance
                                .collection('tutor_profiles')
                                .doc(tutorId)
                                .get(),
                            builder: (context, tSnap) {
                              final t =
                                  tSnap.data?.data() ?? <String, dynamic>{};
                              final tn = (t['full_name'] as String?) ?? 'Tutor';
                              return Text('Tutor: $tn',
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.brandPrimary));
                            },
                          ),
                        const SizedBox(height: 2),
                        Text(name,
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text('$type · $mode',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[600])),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (grade != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text('Grade $grade',
                              style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blue)),
                        ),
                      const SizedBox(height: 6),
                      Text('LKR $price',
                          style: const TextStyle(
                              color: AppTheme.brandPrimary,
                              fontWeight: FontWeight.w700)),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.purple.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text('Score ${score.toStringAsFixed(2)}',
                            style: const TextStyle(
                                fontSize: 12, color: Colors.purple)),
                      ),
                    ],
                  )
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onBottomNavTap(int index) {
    setState(() => _selectedIndex = index);
    switch (index) {
      case 0:
        break;
      case 1:
        context.go('/search');
        break;
      case 2:
        context.go('/messages');
        break;
      case 3:
        context.go('/profile');
        break;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _myEnrollmentsStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Stream<QuerySnapshot<Map<String, dynamic>>>.empty();
    }
    return FirebaseFirestore.instance
        .collection('enrollments')
        .where('studentId', isEqualTo: user.uid)
        .where('status', whereIn: ['active', 'pending']).snapshots();
  }

  Widget _buildEnrollments() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _myEnrollmentsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(20),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final enrollDocs = snapshot.data?.docs ?? [];
        if (enrollDocs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(20),
            child: Text('You have no enrolled classes yet.'),
          );
        }
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: enrollDocs.map((e) {
              final ed = e.data();
              final classId = ed['classId'] as String? ?? '';
              return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                future: FirebaseFirestore.instance
                    .collection('classes')
                    .doc(classId)
                    .get(),
                builder: (context, clsSnap) {
                  final cd = clsSnap.data?.data() ?? <String, dynamic>{};
                  final name = (cd['name'] as String?) ?? 'Class';
                  final tutorId = (cd['tutorId'] as String?) ?? '';
                  final mode = (cd['mode'] as String?) ?? 'In-person';
                  final type = (cd['type'] as String?) ?? 'Group';
                  final grade = (cd['grade'] as num?)?.toInt();
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
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
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => context.go('/enrollment/${e.id}'),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (tutorId.isNotEmpty)
                                        FutureBuilder<
                                            DocumentSnapshot<
                                                Map<String, dynamic>>>(
                                          future: FirebaseFirestore.instance
                                              .collection('tutor_profiles')
                                              .doc(tutorId)
                                              .get(),
                                          builder: (context, tSnap) {
                                            final t = tSnap.data?.data() ??
                                                <String, dynamic>{};
                                            final tn =
                                                (t['full_name'] as String?) ??
                                                    'Tutor';
                                            return Text(
                                              'Tutor: $tn',
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w700,
                                                color: AppTheme.brandPrimary,
                                              ),
                                            );
                                          },
                                        ),
                                      const SizedBox(height: 2),
                                      Text(
                                        name,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '$type · $mode',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (grade != null)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            Colors.blue.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        'Grade $grade',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.blue,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Icon(Icons.event,
                                      size: 14, color: Colors.grey[600]),
                                  const SizedBox(width: 4),
                                  Text(mode,
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600])),
                                  const Spacer(),
                                  const SizedBox(),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Future<void> _loadUserName() async {
    final user = FirebaseAuth.instance.currentUser;
    String name = user?.displayName?.trim() ?? '';
    if (name.isEmpty && user != null) {
      try {
        final snap = await FirebaseFirestore.instance
            .collection('student_profiles')
            .doc(user.uid)
            .get();
        final data = snap.data();
        if (data != null) {
          name = (data['full_name'] as String?)?.trim() ?? '';
        }
      } catch (_) {
        // ignore and fallback
      }
    }
    if (name.isEmpty && user?.email != null) {
      name = user!.email!.split('@').first;
    }
    if (!mounted) return;
    setState(() => _userName = name.isEmpty ? 'Student' : name);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.brandSurface,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
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
                            Text(
                              'Hello, $_userName 👋',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.brandText,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Continue your Physics class with Mr. Kamal?',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: AppTheme.brandSurface,
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.notifications_outlined),
                            onPressed: () => context.go('/announcements'),
                            color: AppTheme.brandText,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Search Bar (navigates to /search)
                    GestureDetector(
                      onTap: () => context.go('/search'),
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppTheme.brandSurface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.subtleBorder),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 12),
                        child: Row(
                          children: [
                            Icon(Icons.search, color: Colors.grey[500]),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Search subjects, tutors...',
                                style: TextStyle(color: Colors.grey[500]),
                              ),
                            ),
                            Icon(Icons.tune, color: Colors.grey[500]),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // AI Recommendations Section
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'AI Recommendations',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.brandText,
                          ),
                        ),
                        TextButton(
                          onPressed: () => context.go('/search'),
                          child: const Text(
                            'See All',
                            style: TextStyle(color: AppTheme.brandPrimary),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    FutureBuilder<List<Map<String, dynamic>>>(
                      future: _fetchTopRecommendedClasses(),
                      builder: (context, recSnap) {
                        final items =
                            recSnap.data ?? const <Map<String, dynamic>>[];
                        if (recSnap.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }
                        if (items.isEmpty) {
                          return const Text('No recommendations yet.');
                        }
                        return Column(
                          children: items
                              .map((it) => Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          AppTheme.brandPrimary
                                              .withValues(alpha: 0.06),
                                          Colors.white,
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: _buildRecClassCard(it),
                                  ))
                              .toList(),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            // Removed duplicated AI Recommendations section

            // Enrolled Classes
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Your Enrolled Classes',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.brandText,
                      ),
                    ),
                    TextButton(
                      onPressed: () {},
                      child: const Text(
                        'View All Classes',
                        style: TextStyle(
                          color: AppTheme.brandPrimary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Enrollments List (live)
            SliverToBoxAdapter(
              child: _buildEnrollments(),
            ),

            const SliverToBoxAdapter(
              child: SizedBox(height: 80),
            ),
          ],
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppTheme.brandPrimary.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton(
          backgroundColor: AppTheme.brandPrimary,
          onPressed: () {
            // TODO: Open AI ChatBot
            context.go('/chatbot');
          },
          child: const Icon(Icons.chat, color: Colors.white),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onBottomNavTap,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.search),
            label: 'Search',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            selectedIcon: Icon(Icons.chat_bubble),
            label: 'Chats',
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
}
