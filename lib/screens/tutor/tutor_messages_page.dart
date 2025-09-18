import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme.dart';

class TutorMessagesPage extends StatefulWidget {
  const TutorMessagesPage({super.key});

  @override
  State<TutorMessagesPage> createState() => _TutorMessagesPageState();
}

class _TutorMessagesPageState extends State<TutorMessagesPage> {
  int _selectedIndex = 2;

  final List<Map<String, dynamic>> _classMessages = [
    {
      'classId': '8',
      'className': 'Physics A/L',
      'type': 'Group',
      'students': 12,
      'lastMessage':
          'Remember to complete the homework exercises before next class.',
      'time': 'Sent 2 hours ago',
    },
    {
      'classId': '9',
      'className': 'Mathematics A/L',
      'type': 'Individual',
      'students': 1,
      'lastMessage':
          'Remember to complete the homework exercises before next class.',
      'time': 'Sent 2 hours ago',
    },
    {
      'classId': '10',
      'className': 'Chemistry A/L',
      'type': 'Group',
      'students': 5,
      'lastMessage':
          'Remember to complete the homework exercises before next class.',
      'time': 'Sent 2 hours ago',
    },
  ];

  final List<Map<String, dynamic>> _individualMessages = [
    {
      'studentId': '1',
      'studentName': 'John Silva',
      'lastMessage': 'Thank you for the extra notes!',
      'time': '1 hour ago',
      'unread': false,
    },
    {
      'studentId': '2',
      'studentName': 'Sarah Fernando',
      'lastMessage': 'Can we reschedule tomorrow\'s session?',
      'time': '3 hours ago',
      'unread': true,
    },
  ];

  void _onBottomNavTap(int index) {
    setState(() => _selectedIndex = index);
    switch (index) {
      case 0:
        context.go('/tutor');
        break;
      case 1:
        context.go('/tutor/classes');
        break;
      case 2:
        break;
      case 3:
        context.go('/tutor/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppTheme.brandSurface,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0.5,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/tutor'),
          ),
          title: const Text('Messages'),
          actions: [
            TextButton.icon(
              onPressed: () => _showComposeDialog(),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('New Message'),
            ),
          ],
          bottom: const TabBar(
            labelColor: AppTheme.brandPrimary,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppTheme.brandPrimary,
            tabs: [
              Tab(text: 'Class Messages'),
              Tab(text: 'Individual'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Class Messages Tab
            ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _classMessages.length,
              itemBuilder: (context, index) {
                final message = _classMessages[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    title: Row(
                      children: [
                        Text(
                          'Class ${message['classId']} - ${message['className']}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _getTypeColor(message['type'])
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            message['type'],
                            style: TextStyle(
                              fontSize: 10,
                              color: _getTypeColor(message['type']),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          '${message['students']} students',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          message['lastMessage'],
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          message['time'],
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: () => _composeClassMessage(message),
                      color: AppTheme.brandPrimary,
                    ),
                    onTap: () => _viewClassMessages(message),
                  ),
                );
              },
            ),

            // Individual Messages Tab
            ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _individualMessages.length,
              itemBuilder: (context, index) {
                final message = _individualMessages[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: CircleAvatar(
                      backgroundColor:
                          AppTheme.brandPrimary.withValues(alpha: 0.1),
                      child: Text(
                        message['studentName']
                            .split(' ')
                            .map((e) => e[0])
                            .take(2)
                            .join(),
                        style: const TextStyle(
                          color: AppTheme.brandPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      message['studentName'],
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          message['lastMessage'],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          message['time'],
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                    trailing: message['unread']
                        ? Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppTheme.brandPrimary,
                              shape: BoxShape.circle,
                            ),
                          )
                        : null,
                    onTap: () => _openIndividualChat(message),
                  ),
                );
              },
            ),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: _onBottomNavTap,
          backgroundColor: Colors.white,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Dashboard',
            ),
            NavigationDestination(
              icon: Icon(Icons.class_outlined),
              selectedIcon: Icon(Icons.class_),
              label: 'Classes',
            ),
            NavigationDestination(
              icon: Icon(Icons.chat_bubble_outline),
              selectedIcon: Icon(Icons.chat_bubble),
              label: 'Messages',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'Group':
        return Colors.blue;
      case 'Individual':
        return Colors.orange;
      case 'Online':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  void _showComposeDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'New Message',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.group, color: AppTheme.brandPrimary),
                title: const Text('Message a Class'),
                subtitle: const Text('Send message to all students in a class'),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Show class selection dialog
                },
              ),
              ListTile(
                leading: const Icon(Icons.person, color: AppTheme.brandPrimary),
                title: const Text('Message Individual Student'),
                subtitle: const Text('Send direct message to a student'),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Show student selection dialog
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _composeClassMessage(Map<String, dynamic> classInfo) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final messageController = TextEditingController();
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.group, color: AppTheme.brandPrimary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Message to Class ${classInfo['classId']} students',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${classInfo['students']} students will receive this message',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: messageController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Type your message...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.attach_file),
                      onPressed: () {
                        // TODO: Implement file attachment
                      },
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () {
                        // TODO: Send message
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Message sent to class')),
                        );
                      },
                      icon: const Icon(Icons.send, size: 18),
                      label: const Text('Send'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.brandPrimary,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _viewClassMessages(Map<String, dynamic> classInfo) {
    // TODO: Navigate to class messages history
  }

  void _openIndividualChat(Map<String, dynamic> message) {
    // TODO: Navigate to individual chat
  }
}
