import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme.dart';

class StudentAuthWelcomePage extends StatelessWidget {
  const StudentAuthWelcomePage({super.key});

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
          constraints: BoxConstraints(
            maxWidth: AppTheme.getContentMaxWidth(context),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppTheme.getHorizontalPadding(context),
              vertical: 28,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 84,
                  height: 84,
                  decoration: const BoxDecoration(
                    color: AppTheme.brandPrimary,
                    shape: BoxShape.circle,
                  ),
                  child:
                      const Icon(Icons.school, color: Colors.white, size: 42),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Welcome to ClassMate!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.brandText,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Find the perfect tutor for your academic success in Sri Lanka',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.mutedText,
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () => context.go('/auth/login'),
                  child: const Text('Login to Your Account'),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => context.go('/auth/register'),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.borderSubtle),
                    foregroundColor: AppTheme.brandText,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Create New Account'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
