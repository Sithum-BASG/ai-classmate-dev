import 'package:flutter/material.dart';
import '../../theme.dart';

class AdminSupportTicketsPage extends StatefulWidget {
  const AdminSupportTicketsPage({super.key});

  @override
  State<AdminSupportTicketsPage> createState() =>
      _AdminSupportTicketsPageState();
}

class _AdminSupportTicketsPageState extends State<AdminSupportTicketsPage> {
  String _selectedFilter = 'All';

  final List<Map<String, dynamic>> _tickets = [
    {
      'id': 'TKT001',
      'subject': 'Payment not reflecting',
      'user': 'Sahan Fernando',
      'userType': 'Student',
      'priority': 'High',
      'status': 'Open',
      'created': '2024-12-15 10:30',
      'lastUpdate': '2 hours ago',
      'messages': 3,
      'description':
          'I made a payment yesterday but it\'s not showing in my account.',
    },
    {
      'id': 'TKT002',
      'subject': 'Cannot upload class materials',
      'user': 'Dr. Anoja Perera',
      'userType': 'Tutor',
      'priority': 'Medium',
      'status': 'In Progress',
      'created': '2024-12-14 15:45',
      'lastUpdate': '1 day ago',
      'messages': 5,
      'description':
          'Getting error when trying to upload PDF files for my class.',
    },
  ];

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
            // Header
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Support Tickets',
                    style: TextStyle(
                      fontSize: isMobile ? 18 : (isTablet ? 20 : 22),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (!isMobile) ...[
                  _buildFilterChip('All', _selectedFilter == 'All'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Open', _selectedFilter == 'Open'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Closed', _selectedFilter == 'Closed'),
                ],
              ],
            ),

            if (isMobile) ...[
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('All', _selectedFilter == 'All'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Open', _selectedFilter == 'Open'),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                        'In Progress', _selectedFilter == 'In Progress'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Closed', _selectedFilter == 'Closed'),
                  ],
                ),
              ),
            ],
            SizedBox(height: isMobile ? 16 : 24),

            // Stats
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: isMobile ? 2 : 4,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: isMobile ? 1.5 : 1.8,
              children: [
                _buildStatCard('12', 'Open', Colors.orange),
                _buildStatCard('5', 'In Progress', Colors.blue),
                _buildStatCard('3', 'Urgent', Colors.red),
                _buildStatCard('45', 'Resolved', Colors.green),
              ],
            ),
            SizedBox(height: isMobile ? 16 : 24),

            // Tickets List
            ..._tickets.map((ticket) => _buildTicketCard(ticket)),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: isSelected ? Colors.white : Colors.grey[700],
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = label;
        });
      },
      selectedColor: AppTheme.brandPrimary,
      backgroundColor: Colors.grey[200],
    );
  }

  Widget _buildStatCard(String value, String label, Color color) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: isMobile ? 20 : 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: isMobile ? 11 : 13,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketCard(Map<String, dynamic> ticket) {
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
            color: Colors.black.withValues(alpha: 0.05),
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
                    Row(
                      children: [
                        Text(
                          ticket['id'],
                          style: TextStyle(
                            fontSize: isMobile ? 11 : 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _getPriorityColor(ticket['priority'])
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            ticket['priority'],
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: _getPriorityColor(ticket['priority']),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ticket['subject'],
                      style: TextStyle(
                        fontSize: isMobile ? 14 : 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color:
                      _getStatusColor(ticket['status']).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  ticket['status'],
                  style: TextStyle(
                    fontSize: isMobile ? 10 : 12,
                    fontWeight: FontWeight.w600,
                    color: _getStatusColor(ticket['status']),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          Text(
            ticket['description'],
            style: TextStyle(
              fontSize: isMobile ? 12 : 14,
              color: Colors.grey[700],
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),

          // Footer
          Row(
            children: [
              Icon(
                Icons.person_outline,
                size: isMobile ? 14 : 16,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 4),
              Text(
                ticket['user'],
                style: TextStyle(
                  fontSize: isMobile ? 11 : 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                Icons.access_time,
                size: isMobile ? 14 : 16,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 4),
              Text(
                ticket['lastUpdate'],
                style: TextStyle(
                  fontSize: isMobile ? 11 : 12,
                  color: Colors.grey[600],
                ),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: () => _viewTicket(ticket),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.brandPrimary,
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 12 : 16,
                    vertical: isMobile ? 6 : 8,
                  ),
                ),
                child: Text(
                  'View',
                  style: TextStyle(fontSize: isMobile ? 12 : 14),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'open':
        return Colors.orange;
      case 'in progress':
        return Colors.blue;
      case 'closed':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  void _viewTicket(Map<String, dynamic> ticket) {
    // Navigate to ticket detail page
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Viewing ticket: ${ticket['id']}'),
      ),
    );
  }
}
