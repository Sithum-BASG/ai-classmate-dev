import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../screens/home_page.dart';
import '../screens/student_dashboard_page.dart';
import '../screens/search_page.dart';
import '../screens/messages_page.dart';
import '../screens/profile_page.dart';
import '../widgets/chatbot_fab.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  debugLogDiagnostics: true,
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomePage(),
    ),
    GoRoute(
      path: '/student',
      builder: (context, state) => const StudentDashboardPage(),
    ),
    GoRoute(
      path: '/search',
      builder: (context, state) => const SearchPage(),
    ),
    GoRoute(
      path: '/messages',
      builder: (context, state) => const MessagesPage(),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfilePage(),
    ),
    GoRoute(
      path: '/chatbot',
      builder: (context, state) => const ChatbotPage(),
    ),
    GoRoute(
      path: '/class/:id',
      builder: (context, state) {
        final classId = state.pathParameters['id'] ?? '';
        return ClassDetailPage(classId: classId);
      },
    ),
    GoRoute(
      path: '/admin',
      builder: (context, state) => const AdminDashboardPage(),
    ),
    GoRoute(
      path: '/tutor',
      builder: (context, state) => const TutorDashboardPage(),
    ),
  ],
);

// Placeholder pages
class ClassDetailPage extends StatelessWidget {
  final String classId;
  const ClassDetailPage({super.key, required this.classId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Class $classId')),
      body: Center(child: Text('Class Detail for ID: $classId')),
    );
  }
}

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
      ),
      body: const Center(child: Text('Admin Dashboard - Coming Soon')),
    );
  }
}

class TutorDashboardPage extends StatelessWidget {
  const TutorDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tutor Dashboard'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
      ),
      body: const Center(child: Text('Tutor Dashboard - Coming Soon')),
    );
  }
}
