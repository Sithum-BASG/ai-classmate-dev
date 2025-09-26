import 'package:flutter/material.dart';
import '../../theme.dart';

class AdminPaymentVerificationPage extends StatefulWidget {
  const AdminPaymentVerificationPage({super.key});

  @override
  State<AdminPaymentVerificationPage> createState() =>
      _AdminPaymentVerificationPageState();
}

class _AdminPaymentVerificationPageState
    extends State<AdminPaymentVerificationPage> {
  final List<Map<String, dynamic>> _pendingPayments = [
    {
      'studentId': 'STU001',
      'studentName': 'Sahan Fernando',
      'paymentId': 'PAY_001',
      'class': 'Physics A/L - Group Class',
      'tutor': 'Dr. Sarah Johnson',
      'amount': 2500,
      'bankSlipReference': 'BSL001234567',
      'paymentDate': '2024-12-14',
      'submitted': '2024-12-15',
      'proofImage': 'payment_proof_001.jpg',
      'status': 'pending',
    },
    {
      'studentId': 'STU002',
      'studentName': 'Nimasha Silva',
      'paymentId': 'PAY_002',
      'class': 'Mathematics A/L - Individual',
      'tutor': 'Mr. Kamal Perera',
      'amount': 3500,
      'bankSlipReference': 'BSL001234568',
      'paymentDate': '2024-12-14',
      'submitted': '2024-12-15',
      'proofImage': 'payment_proof_002.jpg',
      'status': 'pending',
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
            Text(
              'Payment Verification',
              style: TextStyle(
                fontSize: isMobile ? 18 : (isTablet ? 20 : 22),
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: isMobile ? 16 : 24),

            // Stats Grid
            LayoutBuilder(
              builder: (context, constraints) {
                return GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: isMobile ? 1 : 3,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: isMobile ? 4 : (isTablet ? 2.5 : 2),
                  children: [
                    _buildStatCard(
                        Icons.pending, '2', 'Pending', Colors.orange),
                    _buildStatCard(
                        Icons.check_circle, '156', 'Verified', Colors.green),
                    _buildStatCard(Icons.attach_money, 'LKR 847K', 'Processed',
                        Colors.blue),
                  ],
                );
              },
            ),
            SizedBox(height: isMobile ? 16 : 24),

            // Pending Payments
            ..._pendingPayments.map((payment) => _buildPaymentCard(payment)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
      IconData icon, String value, String label, Color color) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

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
      child: Row(
        children: [
          Icon(icon, size: isMobile ? 24 : 28, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: isMobile ? 18 : 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: isMobile ? 11 : 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentCard(Map<String, dynamic> payment) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 900;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(isMobile ? 12 : (isTablet ? 16 : 20)),
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
          if (isMobile)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor:
                          AppTheme.brandPrimary.withValues(alpha: 0.1),
                      child: Text(
                        payment['studentName']
                            .split(' ')
                            .map((e) => e[0])
                            .take(2)
                            .join(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.brandPrimary,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            payment['studentName'],
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'ID: ${payment['paymentId']}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Pending Verification',
                    style: TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            )
          else
            Row(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor: AppTheme.brandPrimary.withValues(alpha: 0.1),
                  child: Text(
                    payment['studentName']
                        .split(' ')
                        .map((e) => e[0])
                        .take(2)
                        .join(),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.brandPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        payment['studentName'],
                        style: TextStyle(
                          fontSize: isTablet ? 14 : 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Student ID: ${payment['studentId']}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: isTablet ? 12 : 13,
                        ),
                      ),
                      Text(
                        'Payment ID: ${payment['paymentId']}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: isTablet ? 12 : 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Pending',
                    style: TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.w600,
                      fontSize: isTablet ? 12 : 13,
                    ),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 16),

          // Payment Details
          Container(
            padding: EdgeInsets.all(isMobile ? 8 : 12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('Class:', payment['class'], isMobile),
                const SizedBox(height: 4),
                _buildDetailRow(
                    'Amount:', 'LKR ${payment['amount']}', isMobile),
                const SizedBox(height: 4),
                _buildDetailRow(
                    'Reference:', payment['bankSlipReference'], isMobile),
                const SizedBox(height: 4),
                _buildDetailRow('Date:', payment['paymentDate'], isMobile),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Payment Proof
          Container(
            padding: EdgeInsets.all(isMobile ? 8 : 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.file_present,
                  size: isMobile ? 20 : 24,
                  color: AppTheme.brandPrimary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    payment['proofImage'],
                    style: TextStyle(fontSize: isMobile ? 12 : 14),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                TextButton(
                  onPressed: () => _viewPaymentProof(payment),
                  child: Text(
                    'View',
                    style: TextStyle(fontSize: isMobile ? 12 : 14),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Action Buttons
          if (isMobile)
            Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _verifyPayment(payment),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        child: const Text('Verify',
                            style: TextStyle(fontSize: 13)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _rejectPayment(payment),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        child: const Text('Reject',
                            style: TextStyle(fontSize: 13)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => _issueRefund(payment),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.orange,
                      side: const BorderSide(color: Colors.orange),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: const Text('Issue Refund',
                        style: TextStyle(fontSize: 13)),
                  ),
                ),
              ],
            )
          else
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _verifyPayment(payment),
                    icon: Icon(Icons.check, size: isTablet ? 16 : 18),
                    label: Text('Verify',
                        style: TextStyle(fontSize: isTablet ? 13 : 14)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding:
                          EdgeInsets.symmetric(vertical: isTablet ? 10 : 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _rejectPayment(payment),
                    icon: Icon(Icons.close, size: isTablet ? 16 : 18),
                    label: Text('Reject',
                        style: TextStyle(fontSize: isTablet ? 13 : 14)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding:
                          EdgeInsets.symmetric(vertical: isTablet ? 10 : 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                if (!isTablet)
                  OutlinedButton.icon(
                    onPressed: () => _issueRefund(payment),
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Refund'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.orange,
                      side: const BorderSide(color: Colors.orange),
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 16),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, bool isMobile) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: isMobile ? 60 : 80,
          child: Text(
            label,
            style: TextStyle(
              fontSize: isMobile ? 11 : 12,
              color: Colors.grey[600],
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: isMobile ? 11 : 12,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
        ),
      ],
    );
  }

  void _verifyPayment(Map<String, dynamic> payment) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Payment verified successfully'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _rejectPayment(Map<String, dynamic> payment) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Reject Payment',
          style: TextStyle(fontSize: isMobile ? 16 : 18),
        ),
        content: SizedBox(
          width: isMobile ? double.maxFinite : 400,
          child: TextField(
            maxLines: 3,
            style: TextStyle(fontSize: isMobile ? 13 : 14),
            decoration: InputDecoration(
              labelText: 'Reason for rejection',
              labelStyle: TextStyle(fontSize: isMobile ? 12 : 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(fontSize: isMobile ? 13 : 14),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Payment rejected'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(
              'Reject',
              style: TextStyle(fontSize: isMobile ? 13 : 14),
            ),
          ),
        ],
      ),
    );
  }

  void _issueRefund(Map<String, dynamic> payment) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Issue Refund',
          style: TextStyle(fontSize: isMobile ? 16 : 18),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Issue refund for LKR ${payment['amount']} to ${payment['studentName']}?',
              style: TextStyle(fontSize: isMobile ? 13 : 14),
            ),
            const SizedBox(height: 16),
            TextField(
              style: TextStyle(fontSize: isMobile ? 13 : 14),
              decoration: InputDecoration(
                labelText: 'Refund reason',
                labelStyle: TextStyle(fontSize: isMobile ? 12 : 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(fontSize: isMobile ? 13 : 14),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Refund issued successfully'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: Text(
              'Issue Refund',
              style: TextStyle(fontSize: isMobile ? 13 : 14),
            ),
          ),
        ],
      ),
    );
  }

  void _viewPaymentProof(Map<String, dynamic> payment) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          padding: EdgeInsets.all(isMobile ? 16 : 20),
          constraints: BoxConstraints(
            maxWidth: isMobile ? double.infinity : 600,
            maxHeight: isMobile ? 400 : 500,
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Payment Proof',
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
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.image, size: 80, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('Payment proof image would display here'),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                payment['paymentId'],
                style: TextStyle(
                  fontSize: isMobile ? 12 : 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
