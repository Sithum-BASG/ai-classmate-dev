import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screens/home_page.dart';
import '../screens/student_dashboard_page.dart';
import '../screens/search_page.dart';
import '../screens/messages_page.dart';
import '../screens/profile_page.dart';
import '../widgets/chatbot_fab.dart';
import '../screens/auth/student_auth_welcome_page.dart';
import '../screens/auth/login_page.dart';
import '../screens/auth/register_page.dart';
import '../screens/auth/tutor_auth_welcome_page.dart';
import '../screens/auth/tutor_login_page.dart';
import '../screens/auth/tutor_register_page.dart';
import '../screens/auth/tutor_pending_page.dart';
// Admin screens
import '../screens/Admin/admin_dashboard_page.dart';
import '../screens/Admin/admin_login_page.dart';

// Tutor screens
import '../screens/tutor/tutor_dashboard_page.dart';
import '../screens/tutor/tutor_classes_page.dart';
import '../screens/tutor/tutor_students_page.dart';
import '../screens/tutor/tutor_messages_page.dart';
import '../screens/tutor/tutor_profile_page.dart';
import '../screens/tutor/tutor_edit_profile_page.dart';
import '../screens/tutor/tutor_reapply_action_page.dart';
import '../screens/tutor/create_class_page.dart';
import '../screens/tutor/tutor_class_details_page.dart';
import '../screens/tutor/tutor_student_details_page.dart';
import '../screens/tutor/tutor_subscription_page.dart';
import '../screens/tutor/create_session_page.dart';
import '../screens/tutor/tutor_session_details_page.dart';

final FirebaseAuth _auth = FirebaseAuth.instance;

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  debugLogDiagnostics: true,
  refreshListenable: GoRouterRefreshStream(_auth.authStateChanges()),
  redirect: (context, state) {
    final bool loggedIn = _auth.currentUser != null;
    final String dest = state.matchedLocation;
    final bool goingToAuth = dest.startsWith('/auth');
    final bool goingToStudent = dest.startsWith('/student');
    final bool goingToTutor = dest == '/tutor';

    if (!loggedIn && goingToStudent) {
      return '/auth';
    }
    if (loggedIn && goingToAuth) {
      return '/student';
    }
    // Tutor: require login; approval gating handled in TutorDashboard
    if (!loggedIn && goingToTutor) {
      return '/tutor/auth';
    }
    return null;
  },
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomePage(),
    ),

    // Auth Routes
    GoRoute(
      path: '/auth',
      builder: (context, state) => const StudentAuthWelcomePage(),
    ),
    // Tutor Auth Routes
    GoRoute(
      path: '/tutor/auth',
      builder: (context, state) => const TutorAuthWelcomePage(),
    ),
    GoRoute(
      path: '/tutor/auth/login',
      builder: (context, state) => const TutorLoginPage(),
    ),
    GoRoute(
      path: '/tutor/auth/register',
      builder: (context, state) => const TutorRegisterPage(),
    ),
    GoRoute(
      path: '/tutor/pending',
      builder: (context, state) {
        final rejected = state.uri.queryParameters['rejected'] == '1';
        return TutorPendingPage(isRejected: rejected);
      },
    ),
    GoRoute(
      path: '/auth/login',
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      path: '/auth/register',
      builder: (context, state) => const RegisterPage(),
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
      path: '/tutor/reapply',
      builder: (context, state) => const TutorReapplyActionPage(),
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
    GoRoute(
      path: '/tutor/class/:id/sessions/new',
      builder: (context, state) {
        final classId = state.pathParameters['id'] ?? '';
        return CreateSessionPage(classId: classId);
      },
    ),
    GoRoute(
      path: '/tutor/class/:id/sessions/:sessionId',
      builder: (context, state) {
        final classId = state.pathParameters['id'] ?? '';
        final sessionId = state.pathParameters['sessionId'] ?? '';
        return TutorSessionDetailsPage(classId: classId, sessionId: sessionId);
      },
    ),
    GoRoute(
      path: '/tutor/class/:id/sessions/:sessionId/edit',
      builder: (context, state) {
        final classId = state.pathParameters['id'] ?? '';
        final sessionId = state.pathParameters['sessionId'] ?? '';
        return CreateSessionPage(classId: classId, sessionId: sessionId);
      },
    ),

    // Admin Routes
    GoRoute(
      path: '/admin',
      builder: (context, state) => const AdminLoginPage(),
    ),
    GoRoute(
      path: '/admin/dashboard',
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

// Not provided by go_router versions < 14; simple notifier that refreshes on a stream event.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
