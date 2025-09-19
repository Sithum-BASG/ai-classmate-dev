import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

  final List<Map<String, dynamic>> _enrolledClasses = [
    {
      'id': '1',
      'title': 'Physics A/L',
      'tutorName': 'Mr. Silva',
      'schedule': 'Tomorrow 5 PM',
      'progressCurrent': 12,
      'progressTotal': 20,
      'rating': 4.5,
      'nextSession': 'Tomorrow',
      'status': 'upcoming',
    },
    {
      'id': '2',
      'title': 'Chemistry A/L',
      'tutorName': 'Dr. Perera',
      'schedule': 'Wed 6 PM',
      'progressCurrent': 8,
      'progressTotal': 15,
      'rating': 4.8,
      'nextSession': 'Wednesday',
      'status': 'active',
    },
  ];

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
                        Stack(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: AppTheme.brandSurface,
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.notifications_outlined),
                                onPressed: () {
                                  // TODO: Navigate to notifications
                                },
                                color: AppTheme.brandText,
                              ),
                            ),
                            Positioned(
                              right: 10,
                              top: 10,
                              child: Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Search Bar
                    Container(
                      decoration: BoxDecoration(
                        color: AppTheme.brandSurface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search subjects, tutors...',
                          hintStyle: TextStyle(color: Colors.grey[400]),
                          prefixIcon:
                              Icon(Icons.search, color: Colors.grey[400]),
                          suffixIcon: IconButton(
                            icon: Icon(Icons.tune, color: Colors.grey[600]),
                            onPressed: () {
                              // TODO: Open filter bottom sheet
                            },
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
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
                          onPressed: () {},
                          child: const Text(
                            'See All',
                            style: TextStyle(color: AppTheme.brandPrimary),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...List.generate(_aiRecommendations.length, (index) {
                      final recommendation = _aiRecommendations[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: recommendation['color'],
                          borderRadius: BorderRadius.circular(12),
                          border: Border(
                            left: BorderSide(
                              color: recommendation['borderColor'],
                              width: 4,
                            ),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  recommendation['icon'],
                                  size: 20,
                                  color: recommendation['borderColor'],
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    recommendation['title'],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                                if (recommendation['priority'] != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: recommendation['borderColor'],
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      recommendation['priority'],
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              recommendation['description'],
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[700],
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 32,
                              child: OutlinedButton(
                                onPressed: () {
                                  // TODO: Handle button press
                                },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor:
                                      recommendation['borderColor'],
                                  side: BorderSide(
                                    color: recommendation['borderColor'],
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                ),
                                child: Text(
                                  recommendation['type'] == 'schedule'
                                      ? 'View Schedule'
                                      : 'View Profile',
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),

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

            // Classes List
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final classData = _enrolledClasses[index];
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
                          onTap: () => context.go('/class/${classData['id']}'),
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
                                        Text(
                                          classData['title'],
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'with ${classData['tutorName']}',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: classData['status'] == 'upcoming'
                                            ? Colors.orange
                                                .withValues(alpha: 0.1)
                                            : Colors.green
                                                .withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        classData['nextSession'],
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color:
                                              classData['status'] == 'upcoming'
                                                  ? Colors.orange
                                                  : Colors.green,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Icon(Icons.schedule,
                                        size: 14, color: Colors.grey[600]),
                                    const SizedBox(width: 4),
                                    Text(
                                      classData['schedule'],
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    const Spacer(),
                                    Row(
                                      children: [
                                        const Icon(Icons.star,
                                            size: 14, color: Colors.amber),
                                        const SizedBox(width: 2),
                                        Text(
                                          classData['rating'].toString(),
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: LinearProgressIndicator(
                                    value: classData['progressCurrent'] /
                                        classData['progressTotal'],
                                    backgroundColor: Colors.grey[200],
                                    valueColor:
                                        const AlwaysStoppedAnimation<Color>(
                                      AppTheme.brandPrimary,
                                    ),
                                    minHeight: 6,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${classData['progressCurrent']} of ${classData['progressTotal']} lessons completed',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                  childCount: _enrolledClasses.length,
                ),
              ),
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
