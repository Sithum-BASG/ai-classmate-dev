import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme.dart';

class TutorPendingPage extends StatelessWidget {
  final bool isRejected;
  const TutorPendingPage({super.key, this.isRejected = false});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            Text(isRejected ? 'Approval Rejected' : 'Account Pending Approval'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isRejected ? Icons.cancel_outlined : Icons.hourglass_top,
                size: 64,
                color: isRejected ? Colors.red : AppTheme.brandPrimary,
              ),
              const SizedBox(height: 16),
              Text(
                isRejected
                    ? 'Your tutor application was rejected.'
                    : 'Your tutor account is awaiting approval.',
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                isRejected
                    ? 'Please review your profile information and reapply for approval.'
                    : 'You will be notified once an admin approves your account. You can continue exploring the app in the meantime.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              if (isRejected) ...[
                ElevatedButton.icon(
                  onPressed: () => context.go('/tutor/profile/edit'),
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Edit Profile'),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => context.go('/tutor/reapply'),
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Reapply for Approval'),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => context.go('/'),
                  child: const Text('Back to Home'),
                ),
              ] else ...[
                ElevatedButton(
                  onPressed: () => context.go('/'),
                  child: const Text('Back to Home'),
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }
}
