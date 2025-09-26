import 'package:flutter/material.dart';
import '../../theme.dart';

class AdminAnnouncementsPage extends StatefulWidget {
  const AdminAnnouncementsPage({super.key});

  @override
  State<AdminAnnouncementsPage> createState() => _AdminAnnouncementsPageState();
}

class _AdminAnnouncementsPageState extends State<AdminAnnouncementsPage> {
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  String _selectedAudience = 'All Users';

  final List<Map<String, dynamic>> _recentAnnouncements = [
    {
      'title': 'Platform Maintenance Scheduled',
      'audience': 'All Users',
      'message':
          'System will be under maintenance on Dec 20th from 2:00 AM to 4:00 AM',
      'date': '2024-12-15',
      'status': 'Active',
    },
    {
      'title': 'New Payment Methods Available',
      'audience': 'Students',
      'message':
          'We now accept payments via mobile banking and digital wallets',
      'date': '2024-12-14',
      'status': 'Active',
    },
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
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
              'Announcements',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: isMobile ? 16 : 24),

            // Create Announcement Form
            Container(
              padding: EdgeInsets.all(isMobile ? 12 : (isTablet ? 16 : 20)),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.campaign,
                        color: AppTheme.brandPrimary,
                        size: isMobile ? 20 : 24,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Create New Announcement',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _titleController,
                    style: TextStyle(fontSize: isMobile ? 13 : 14),
                    decoration: InputDecoration(
                      labelText: 'Announcement Title',
                      labelStyle: TextStyle(fontSize: isMobile ? 12 : 14),
                      hintText: 'Enter announcement title',
                      hintStyle: TextStyle(fontSize: isMobile ? 12 : 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: AppTheme.borderSubtle,
                        ),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 12 : 16,
                        vertical: isMobile ? 12 : 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _messageController,
                    maxLines: isMobile ? 3 : 4,
                    style: TextStyle(fontSize: isMobile ? 13 : 14),
                    decoration: InputDecoration(
                      labelText: 'Message',
                      labelStyle: TextStyle(fontSize: isMobile ? 12 : 14),
                      hintText: 'Enter your announcement message',
                      hintStyle: TextStyle(fontSize: isMobile ? 12 : 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: AppTheme.borderSubtle,
                        ),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 12 : 16,
                        vertical: isMobile ? 12 : 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedAudience,
                    style: TextStyle(
                      fontSize: isMobile ? 13 : 14,
                      color: Colors.black,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Target Audience',
                      labelStyle: TextStyle(fontSize: isMobile ? 12 : 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: AppTheme.borderSubtle,
                        ),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 12 : 16,
                        vertical: isMobile ? 12 : 16,
                      ),
                    ),
                    items: [
                      'All Users',
                      'Students Only',
                      'Tutors Only',
                      'Specific Classes',
                    ].map((audience) {
                      return DropdownMenuItem(
                        value: audience,
                        child: Text(
                          audience,
                          style: TextStyle(fontSize: isMobile ? 13 : 14),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedAudience = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: isMobile ? 44 : 48,
                    child: ElevatedButton.icon(
                      onPressed: _sendAnnouncement,
                      icon: Icon(Icons.send, size: isMobile ? 18 : 20),
                      label: Text(
                        'Send Announcement',
                        style: TextStyle(fontSize: isMobile ? 13 : 15),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.brandPrimary,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: isMobile ? 20 : 24),

            // Recent Announcements
            Text(
              'Recent Announcements',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            ..._recentAnnouncements
                .map((announcement) => _buildAnnouncementCard(announcement)),
          ],
        ),
      ),
    );
  }

  Widget _buildAnnouncementCard(Map<String, dynamic> announcement) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      announcement['title'],
                      style: TextStyle(
                        fontSize: isMobile ? 14 : 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'To: ${announcement['audience']}',
                      style: TextStyle(
                        fontSize: isMobile ? 11 : 13,
                        color: AppTheme.mutedText,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 8 : 12,
                  vertical: isMobile ? 4 : 6,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.brandPrimary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  announcement['status'],
                  style: TextStyle(
                    color: AppTheme.brandPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: isMobile ? 10 : 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Text(
            announcement['message'],
            style: TextStyle(
              fontSize: isMobile ? 12 : 14,
              color: AppTheme.mutedText,
            ),
          ),
          const SizedBox(height: 12),

          // Footer
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                announcement['date'],
                style: TextStyle(
                  fontSize: isMobile ? 11 : 12,
                  color: AppTheme.mutedText,
                ),
              ),
              if (isMobile)
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, size: 20),
                  onSelected: (value) {
                    if (value == 'delete') {
                      _deleteAnnouncement(announcement);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Text('Edit', style: TextStyle(fontSize: 13)),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text(
                        'Delete',
                        style: TextStyle(color: Colors.red, fontSize: 13),
                      ),
                    ),
                  ],
                )
              else
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text('Edit', style: TextStyle(fontSize: 13)),
                    ),
                    TextButton.icon(
                      onPressed: () => _deleteAnnouncement(announcement),
                      icon: Icon(
                        Icons.delete,
                        size: 16,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      label:
                          const Text('Delete', style: TextStyle(fontSize: 13)),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _sendAnnouncement() {
    if (_titleController.text.isEmpty || _messageController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please fill all fields'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Announcement sent successfully'),
        backgroundColor: AppTheme.brandSecondary,
      ),
    );

    setState(() {
      _recentAnnouncements.insert(0, {
        'title': _titleController.text,
        'audience': _selectedAudience,
        'message': _messageController.text,
        'date': DateTime.now().toString().split(' ')[0],
        'status': 'Active',
      });
    });

    _titleController.clear();
    _messageController.clear();
  }

  void _deleteAnnouncement(Map<String, dynamic> announcement) {
    setState(() {
      _recentAnnouncements.remove(announcement);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Announcement deleted'),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }
}
