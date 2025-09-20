import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme.dart';

class TutorPendingPage extends StatelessWidget {
  const TutorPendingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Account Pending Approval')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.hourglass_top,
                  size: 64, color: AppTheme.brandPrimary),
              const SizedBox(height: 16),
              const Text(
                'Your tutor account is awaiting approval.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              const Text(
                'You will be notified once an admin approves your account. You can continue exploring the app in the meantime.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => context.go('/'),
                child: const Text('Back to Home'),
              )
            ],
          ),
        ),
      ),
    );
  }
}
