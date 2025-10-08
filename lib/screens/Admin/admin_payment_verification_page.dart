import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
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
  Stream<QuerySnapshot<Map<String, dynamic>>> _pendingPaymentsStream() {
    return FirebaseFirestore.instance
        .collection('payments')
        .where('verifyStatus', isEqualTo: 'pending')
        .orderBy('paidAt', descending: true)
        .snapshots();
  }

// duplicate removed

  String _initialsOf(dynamic name) {
    final s = (name as String?)?.trim() ?? '';
    if (s.isEmpty) return 'S';
    final parts = s.split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    return parts.take(2).map((e) => e[0]).join().toUpperCase();
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
                    StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: FirebaseFirestore.instance
                          .collection('payments')
                          .where('verifyStatus', isEqualTo: 'pending')
                          .snapshots(),
                      builder: (context, s) {
                        final v = (s.data?.size ?? 0).toString();
                        return _buildStatCard(
                            Icons.pending, v, 'Pending', Colors.orange);
                      },
                    ),
                    StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: FirebaseFirestore.instance
                          .collection('payments')
                          .where('verifyStatus', isEqualTo: 'verified')
                          .snapshots(),
                      builder: (context, s) {
                        final v = (s.data?.size ?? 0).toString();
                        return _buildStatCard(
                            Icons.check_circle, v, 'Verified', Colors.green);
                      },
                    ),
                    FutureBuilder<String>(
                      future: _sumProcessedAmount(),
                      builder: (context, s) {
                        final v = s.data ?? 'LKR 0';
                        return _buildStatCard(
                            Icons.attach_money, v, 'Processed', Colors.blue);
                      },
                    ),
                  ],
                );
              },
            ),
            SizedBox(height: isMobile ? 16 : 24),

            // Pending Payments
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _pendingPaymentsStream(),
              builder: (context, snap) {
                if (snap.hasError) {
                  return Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text('Failed to load payments: ${snap.error}',
                        style: const TextStyle(color: Colors.red)),
                  );
                }
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final items = snap.data!.docs.map((d) => d.data()).toList();
                if (items.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text('No pending payments'),
                  );
                }
                return Column(
                  children: items.map((p) => _buildPaymentCard(p)).toList(),
                );
              },
            ),
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
                        _initialsOf(payment['studentName']),
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
                            (payment['studentName'] as String?) ?? 'Student',
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
                    _initialsOf(payment['studentName']),
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
                        (payment['studentName'] as String?) ?? 'Student',
                        style: TextStyle(
                          fontSize: isTablet ? 14 : 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Student ID: ${payment['studentId'] ?? ''}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: isTablet ? 12 : 13,
                        ),
                      ),
                      Text(
                        'Payment ID: ${payment['paymentId'] ?? ''}',
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
                _buildDetailRow(
                    'Invoice:', payment['invoiceId'] ?? '', isMobile),
                const SizedBox(height: 4),
                _buildDetailRow(
                    'Amount:',
                    'LKR ${payment['paidAmount'] ?? payment['amountDue'] ?? 0}',
                    isMobile),
                const SizedBox(height: 4),
                _buildDetailRow(
                    'Reference:', payment['reference'] ?? '-', isMobile),
                const SizedBox(height: 4),
                _buildDetailRow(
                    'Date:',
                    (payment['paidAt'] ?? payment['createdAt'] ?? '')
                        .toString(),
                    isMobile),
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
                    (payment['proofUrl'] ?? '-') as String,
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

  Future<void> _verifyPayment(Map<String, dynamic> payment) async {
    final id = (payment['paymentId'] ?? '') as String;
    if (id.isEmpty) return;
    try {
      final callable = FirebaseFunctions.instanceFor(region: 'asia-south1')
          .httpsCallable('reviewPayment');
      await callable.call({'paymentId': id, 'approve': true});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Payment verified'), backgroundColor: Colors.green),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Failed to verify: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _rejectPayment(Map<String, dynamic> payment) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final reasonCtrl = TextEditingController();

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
            controller: reasonCtrl,
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
            onPressed: () async {
              Navigator.pop(context);
              try {
                final id = (payment['paymentId'] ?? '') as String;
                final callable =
                    FirebaseFunctions.instanceFor(region: 'asia-south1')
                        .httpsCallable('reviewPayment');
                await callable.call({
                  'paymentId': id,
                  'approve': false,
                  'reason': reasonCtrl.text.trim()
                });
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Payment rejected'),
                      backgroundColor: Colors.red),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text('Failed to reject: $e'),
                      backgroundColor: Colors.red),
                );
              }
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
                  child: Center(
                    child: (payment['proofUrl'] != null &&
                            (payment['proofUrl'] as String).isNotEmpty)
                        ? Image.network(payment['proofUrl'],
                            fit: BoxFit.contain)
                        : const Text('No image'),
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

  Future<String> _sumProcessedAmount() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('payments')
        .where('verifyStatus', isEqualTo: 'verified')
        .get();
    final totalAmount = snapshot.docs.fold(0.0, (sum, doc) {
      final data = doc.data();
      final amount = data['paidAmount'] ?? data['amountDue'] ?? 0;
      return sum + amount;
    });
    return 'LKR $totalAmount';
  }
}
