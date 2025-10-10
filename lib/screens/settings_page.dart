import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

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
        title:
            const Text('Settings', style: TextStyle(color: AppTheme.brandText)),
      ),
      body: ListView(
        children: [
          _tile(
            icon: Icons.palette_outlined,
            title: 'Theme',
            subtitle: 'Light',
            onTap: () {},
          ),
          _tile(
            icon: Icons.lock_outline,
            title: 'Privacy',
            subtitle: 'Manage profile visibility',
            onTap: () {},
          ),
          _tile(
            icon: Icons.description_outlined,
            title: 'Terms & Policies',
            subtitle: 'Legal and privacy information',
            onTap: () {},
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text('App version 1.0.0',
                style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _tile({
    required IconData icon,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppTheme.brandPrimary),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: subtitle == null ? null : Text(subtitle),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}
