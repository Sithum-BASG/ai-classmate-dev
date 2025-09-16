import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme.dart';

class MessagesPage extends StatelessWidget {
  const MessagesPage({super.key});

  final List<Map<String, dynamic>> _messages = const [
    {
      'name': 'Mr. Silva',
      'message': 'Physics Notes.pdf (2MB)',
      'time': '2:30 PM',
      'hasAttachment': true,
      'attachmentType': 'pdf',
      'unread': true,
      'avatar': 'S',
    },
    {
      'name': 'Dr. Perera',
      'message': 'Great work on the chemistry assignment!',
      'time': '11:45 AM',
      'hasAttachment': false,
      'attachmentType': null,
      'unread': false,
      'avatar': 'P',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.brandSurface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.brandText),
          onPressed: () => context.go('/student'),
        ),
        title: const Text(
          'Messages',
          style: TextStyle(
            color: AppTheme.brandText,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: ListView.separated(
        itemCount: _messages.length,
        separatorBuilder: (context, index) => const Divider(
          height: 1,
          indent: 72,
        ),
        itemBuilder: (context, index) {
          final message = _messages[index];
          return Container(
            color: Colors.white,
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 8,
              ),
              leading: CircleAvatar(
                radius: 24,
                backgroundColor: AppTheme.brandPrimary.withValues(alpha: 0.1),
                child: Text(
                  message['avatar'],
                  style: const TextStyle(
                    color: AppTheme.brandPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              title: Text(
                message['name'],
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    if (message['hasAttachment'])
                      Container(
                        margin: const EdgeInsets.only(right: 4),
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: _getAttachmentColor(message['attachmentType']),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Icon(
                          _getAttachmentIcon(message['attachmentType']),
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    Expanded(
                      child: Text(
                        message['message'],
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    message['time'],
                    style: TextStyle(
                      fontSize: 12,
                      color: message['unread']
                          ? AppTheme.brandPrimary
                          : Colors.grey[500],
                      fontWeight:
                          message['unread'] ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                  if (message['unread'])
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppTheme.brandPrimary,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
              onTap: () {
                // TODO: Navigate to chat detail
              },
            ),
          );
        },
      ),
    );
  }

  IconData _getAttachmentIcon(String? type) {
    switch (type) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
        return Icons.description;
      case 'image':
        return Icons.image;
      case 'video':
        return Icons.video_library;
      default:
        return Icons.attach_file;
    }
  }

  Color _getAttachmentColor(String? type) {
    switch (type) {
      case 'pdf':
        return Colors.red;
      case 'doc':
        return Colors.blue;
      case 'image':
        return Colors.green;
      case 'video':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}
