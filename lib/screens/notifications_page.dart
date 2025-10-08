import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme.dart';

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  State<NotificationSettingsPage> createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  bool _classReminders = true;
  bool _announcements = true;
  bool _messages = true;

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
        title: const Text('Notifications',
            style: TextStyle(color: AppTheme.brandText)),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 8),
          _tileSwitch(
            title: 'Class reminders',
            subtitle: 'Session reminders and schedule changes',
            value: _classReminders,
            onChanged: (v) => setState(() => _classReminders = v),
          ),
          _tileSwitch(
            title: 'Announcements',
            subtitle: 'Important updates from admins',
            value: _announcements,
            onChanged: (v) => setState(() => _announcements = v),
          ),
          _tileSwitch(
            title: 'Messages',
            subtitle: 'New chat messages from tutors',
            value: _messages,
            onChanged: (v) => setState(() => _messages = v),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'System-level notification permissions can be changed from device settings.',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          )
        ],
      ),
    );
  }

  Widget _tileSwitch({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
      ),
    );
  }
}
