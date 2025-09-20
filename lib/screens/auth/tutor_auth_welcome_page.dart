import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme.dart';

class TutorAuthWelcomePage extends StatelessWidget {
  const TutorAuthWelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.brandSurface,
      appBar: AppBar(
        title: const Text(''),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 84,
                  height: 84,
                  decoration: const BoxDecoration(
                    color: AppTheme.brandSecondary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.menu_book_rounded,
                      color: Colors.white, size: 42),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Welcome Tutors!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.brandText),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Sign in or create an account to manage your classes',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: AppTheme.mutedText),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () => context.go('/tutor/auth/login'),
                  child: const Text('Login to Your Account'),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => context.go('/tutor/auth/register'),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.borderSubtle),
                    foregroundColor: AppTheme.brandText,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Create New Tutor Account'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
