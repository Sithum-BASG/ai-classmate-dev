import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme.dart';

class AdminSettingsPage extends StatefulWidget {
  const AdminSettingsPage({super.key});

  @override
  State<AdminSettingsPage> createState() => _AdminSettingsPageState();
}

class _AdminSettingsPageState extends State<AdminSettingsPage> {
  final _subscriptionFeeController = TextEditingController();
  final _commissionController = TextEditingController();
  bool _emailNotifications = false;
  bool _smsNotifications = false;
  bool _pushNotifications = false;
  bool _autoApprovalEnabled = false;
  bool _loading = true;

  @override
  void dispose() {
    _subscriptionFeeController.dispose();
    _commissionController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final platformDoc = await FirebaseFirestore.instance
          .collection('config')
          .doc('admin')
          .collection('meta')
          .doc('platform')
          .get();
      final p = platformDoc.data() ?? <String, dynamic>{};
      _subscriptionFeeController.text =
          ((p['subscriptionFee'] as num?)?.toString() ?? '');
      _commissionController.text =
          ((p['commissionPct'] as num?)?.toString() ?? '');
      _autoApprovalEnabled = (p['autoApprovalEnabled'] as bool?) ?? false;

      final notifDoc = await FirebaseFirestore.instance
          .collection('config')
          .doc('admin')
          .collection('meta')
          .doc('notifications')
          .get();
      final n = notifDoc.data() ?? <String, dynamic>{};
      _emailNotifications = (n['email'] as bool?) ?? false;
      _smsNotifications = (n['sms'] as bool?) ?? false;
      _pushNotifications = (n['push'] as bool?) ?? false;
    } catch (_) {
      // ignore load errors; keep defaults
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 900;

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 12 : (isTablet ? 16 : 24)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Admin Settings',
              style: TextStyle(
                fontSize: isMobile ? 18 : (isTablet ? 20 : 22),
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: isMobile ? 16 : 24),

            // Settings Layout
            if (_loading)
              const Center(child: CircularProgressIndicator())
            else if (isMobile)
              Column(
                children: [
                  _buildPlatformSettingsCard(isMobile, isTablet),
                  const SizedBox(height: 16),
                  _buildNotificationSettingsCard(isMobile, isTablet),
                  const SizedBox(height: 16),
                  _buildSystemMaintenanceCard(isMobile, isTablet),
                ],
              )
            else
              Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                          child:
                              _buildPlatformSettingsCard(isMobile, isTablet)),
                      const SizedBox(width: 16),
                      Expanded(
                          child: _buildNotificationSettingsCard(
                              isMobile, isTablet)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildSystemMaintenanceCard(isMobile, isTablet),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlatformSettingsCard(bool isMobile, bool isTablet) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Platform Settings',
            style: TextStyle(
              fontSize: isMobile ? 16 : 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _subscriptionFeeController,
            keyboardType: TextInputType.number,
            style: TextStyle(fontSize: isMobile ? 13 : 14),
            decoration: InputDecoration(
              labelText: 'Monthly Subscription Fee',
              labelStyle: TextStyle(fontSize: isMobile ? 12 : 14),
              prefixText: 'LKR ',
              prefixStyle: TextStyle(fontSize: isMobile ? 13 : 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: isMobile ? 12 : 16,
                vertical: isMobile ? 12 : 16,
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _commissionController,
            keyboardType: TextInputType.number,
            style: TextStyle(fontSize: isMobile ? 13 : 14),
            decoration: InputDecoration(
              labelText: 'Platform Commission (%)',
              labelStyle: TextStyle(fontSize: isMobile ? 12 : 14),
              suffixText: '%',
              suffixStyle: TextStyle(fontSize: isMobile ? 13 : 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: isMobile ? 12 : 16,
                vertical: isMobile ? 12 : 16,
              ),
            ),
          ),
          const SizedBox(height: 20),
          CheckboxListTile(
            title: Text(
              'Auto-approval for Tutors',
              style: TextStyle(fontSize: isMobile ? 13 : 15),
            ),
            subtitle: Text(
              'Enable automatic tutor approval',
              style: TextStyle(fontSize: isMobile ? 11 : 13),
            ),
            value: _autoApprovalEnabled,
            contentPadding: EdgeInsets.zero,
            dense: isMobile,
            onChanged: (value) {
              setState(() {
                _autoApprovalEnabled = value!;
              });
            },
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _savePlatformSettings,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.brandPrimary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: isMobile ? 14 : 16),
                minimumSize: Size.fromHeight(isMobile ? 44 : 48),
              ),
              child: Text(
                'Save Platform Settings',
                style: TextStyle(fontSize: isMobile ? 13 : 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationSettingsCard(bool isMobile, bool isTablet) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Notification Settings',
            style: TextStyle(
              fontSize: isMobile ? 16 : 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          SwitchListTile(
            title: Text(
              'Email notifications',
              style: TextStyle(fontSize: isMobile ? 13 : 15),
            ),
            value: _emailNotifications,
            contentPadding: EdgeInsets.zero,
            dense: isMobile,
            onChanged: (value) {
              setState(() {
                _emailNotifications = value;
              });
            },
          ),
          SwitchListTile(
            title: Text(
              'SMS notifications',
              style: TextStyle(fontSize: isMobile ? 13 : 15),
            ),
            value: _smsNotifications,
            contentPadding: EdgeInsets.zero,
            dense: isMobile,
            onChanged: (value) {
              setState(() {
                _smsNotifications = value;
              });
            },
          ),
          SwitchListTile(
            title: Text(
              'Push notifications',
              style: TextStyle(fontSize: isMobile ? 13 : 15),
            ),
            value: _pushNotifications,
            contentPadding: EdgeInsets.zero,
            dense: isMobile,
            onChanged: (value) {
              setState(() {
                _pushNotifications = value;
              });
            },
          ),
          if (isMobile) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveNotificationSettings,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.brandPrimary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  minimumSize: const Size.fromHeight(44),
                ),
                child: const Text(
                  'Save Notifications',
                  style: TextStyle(fontSize: 13),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSystemMaintenanceCard(bool isMobile, bool isTablet) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'System Maintenance',
            style: TextStyle(
              fontSize: isMobile ? 16 : 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          _buildMaintenanceItem(
            'Database Backup',
            'Last backup: 2 hours ago',
            'Run Backup',
            () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Backup started successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            isMobile,
          ),
          const Divider(height: 32),
          _buildMaintenanceItem(
            'Clear Cache',
            'Clear system cache to improve performance',
            'Clear Cache',
            () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Cache cleared successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            isMobile,
          ),
          const Divider(height: 32),
          _buildMaintenanceItem(
            'System Logs',
            'View system activity logs',
            'View Logs',
            () {
              _showSystemLogs();
            },
            isMobile,
          ),
          const Divider(height: 32),
          _buildMaintenanceItem(
            'Export Data',
            'Export all system data',
            'Export',
            () {
              _exportData();
            },
            isMobile,
          ),
        ],
      ),
    );
  }

  Widget _buildMaintenanceItem(
    String title,
    String subtitle,
    String buttonText,
    VoidCallback onPressed,
    bool isMobile,
  ) {
    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 36,
            child: ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.brandPrimary.withValues(alpha: 0.1),
                foregroundColor: AppTheme.brandPrimary,
                elevation: 0,
              ),
              child: Text(
                buttonText,
                style: const TextStyle(fontSize: 13),
              ),
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        ElevatedButton(
          onPressed: onPressed,
          child: Text(buttonText),
        ),
      ],
    );
  }

  void _savePlatformSettings() {
    final fee = num.tryParse(_subscriptionFeeController.text.trim()) ?? 0;
    final pct = num.tryParse(_commissionController.text.trim()) ?? 0;
    FirebaseFirestore.instance
        .collection('config')
        .doc('admin')
        .collection('meta')
        .doc('platform')
        .set({
      'subscriptionFee': fee,
      'commissionPct': pct,
      'autoApprovalEnabled': _autoApprovalEnabled,
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true)).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Platform settings saved successfully'),
          backgroundColor: Colors.green,
        ),
      );
    }).catchError((e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    });
  }

  void _saveNotificationSettings() {
    FirebaseFirestore.instance
        .collection('config')
        .doc('admin')
        .collection('meta')
        .doc('notifications')
        .set({
      'email': _emailNotifications,
      'sms': _smsNotifications,
      'push': _pushNotifications,
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true)).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notification settings saved successfully'),
          backgroundColor: Colors.green,
        ),
      );
    }).catchError((e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save notifications: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    });
  }

  void _showSystemLogs() {
    final isMobile = MediaQuery.of(context).size.width < 600;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          padding: EdgeInsets.all(isMobile ? 16 : 20),
          constraints: BoxConstraints(
            maxWidth: isMobile ? double.infinity : 600,
            maxHeight: 400,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'System Logs',
                    style: TextStyle(
                      fontSize: isMobile ? 16 : 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              Expanded(
                child: ListView(
                  children: [
                    _buildLogItem(
                        '[INFO] User login successful', '2024-12-15 10:30:45'),
                    _buildLogItem(
                        '[INFO] Payment processed', '2024-12-15 10:28:12'),
                    _buildLogItem('[WARNING] High server load detected',
                        '2024-12-15 10:15:00'),
                    _buildLogItem('[INFO] Database backup completed',
                        '2024-12-15 10:00:00'),
                    _buildLogItem(
                        '[ERROR] Failed email delivery', '2024-12-15 09:45:30'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {},
                    child: const Text('Export Logs'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogItem(String message, String timestamp) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message,
            style: TextStyle(
              fontSize: isMobile ? 12 : 14,
              fontFamily: 'monospace',
            ),
          ),
          Text(
            timestamp,
            style: TextStyle(
              fontSize: isMobile ? 10 : 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  void _exportData() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Data export started'),
        backgroundColor: Colors.blue,
      ),
    );
  }
}
