import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../screens/home_page.dart';
import '../screens/student_dashboard_page.dart';
import '../screens/search_page.dart';
import '../screens/messages_page.dart';
import '../screens/profile_page.dart';
import '../widgets/chatbot_fab.dart';

// Tutor screens
import '../screens/tutor/tutor_dashboard_page.dart';
import '../screens/tutor/tutor_classes_page.dart';
import '../screens/tutor/tutor_students_page.dart';
import '../screens/tutor/tutor_messages_page.dart';
import '../screens/tutor/tutor_profile_page.dart';
import '../screens/tutor/tutor_edit_profile_page.dart';
import '../screens/tutor/create_class_page.dart';
import '../screens/tutor/tutor_class_details_page.dart';
import '../screens/tutor/tutor_student_details_page.dart';
import '../screens/tutor/tutor_subscription_page.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  debugLogDiagnostics: true,
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomePage(),
    ),

    // Student Routes
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

    // Tutor Routes
    GoRoute(
      path: '/tutor',
      builder: (context, state) => const TutorDashboardPage(),
    ),
    GoRoute(
      path: '/tutor/classes',
      builder: (context, state) => const TutorClassesPage(),
    ),
    GoRoute(
      path: '/tutor/students',
      builder: (context, state) => const TutorStudentsPage(),
    ),
    GoRoute(
      path: '/tutor/student/:id',
      builder: (context, state) {
        final studentId = state.pathParameters['id'] ?? '';
        return TutorStudentDetailsPage(studentId: studentId);
      },
    ),
    GoRoute(
      path: '/tutor/messages',
      builder: (context, state) => const TutorMessagesPage(),
    ),
    GoRoute(
      path: '/tutor/profile',
      builder: (context, state) => const TutorProfilePage(),
    ),
    GoRoute(
      path: '/tutor/profile/edit',
      builder: (context, state) => const TutorEditProfilePage(),
    ),
    GoRoute(
      path: '/tutor/subscription',
      builder: (context, state) => const TutorSubscriptionPage(),
    ),
    GoRoute(
      path: '/tutor/class/new',
      builder: (context, state) => const CreateClassPage(),
    ),
    GoRoute(
      path: '/tutor/class/:id',
      builder: (context, state) {
        final classId = state.pathParameters['id'] ?? '';
        return TutorClassDetailsPage(classId: classId);
      },
    ),
    GoRoute(
      path: '/tutor/class/:id/edit',
      builder: (context, state) {
        final classId = state.pathParameters['id'] ?? '';
        return CreateClassPage(classId: classId);
      },
    ),

    // Admin Routes
    GoRoute(
      path: '/admin',
      builder: (context, state) => const AdminDashboardPage(),
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
