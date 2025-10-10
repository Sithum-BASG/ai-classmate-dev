import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme.dart';

class HelpSupportPage extends StatelessWidget {
  const HelpSupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.brandSurface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.brandText),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              context.pop();
            } else {
              context.go('/profile');
            }
          },
        ),
        title: const Text('Help & Support',
            style: TextStyle(color: AppTheme.brandText)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _card(
            title: 'FAQs',
            body:
                'Find answers to common questions about enrollment, payments, and classes.',
            action: TextButton(
              onPressed: () => context.push('/chatbot'),
              child: const Text('Ask AI Assistant'),
            ),
          ),
          _card(
            title: 'Contact Support',
            body:
                'If you need further assistance, contact our support team via email.',
            action: TextButton(
              onPressed: () {},
              child: const Text('support@classmate.app'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _card({required String title, required String body, Widget? action}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(body, style: const TextStyle(fontSize: 14)),
            if (action != null) ...[
              const SizedBox(height: 8),
              action,
            ],
          ],
        ),
      ),
    );
  }
}
