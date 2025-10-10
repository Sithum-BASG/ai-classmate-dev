import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../config/subjects.dart';

class AdminAnalyticsPage extends StatefulWidget {
  const AdminAnalyticsPage({super.key});

  @override
  State<AdminAnalyticsPage> createState() => _AdminAnalyticsPageState();
}

class _AdminAnalyticsPageState extends State<AdminAnalyticsPage> {
  Map<String, int> _subjectDistribution = <String, int>{};

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 16 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            if (!isMobile)
              Row(
                children: [
                  const Text(
                    'Analytics & Reports',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.download),
                    label: const Text('Export Report'),
                  ),
                  const SizedBox(width: 12),
                  TextButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.calendar_today),
                    label: const Text('Date Range'),
                  ),
                ],
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Analytics & Reports',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.download, size: 18),
                          label: const Text('Export'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.calendar_today, size: 18),
                          label: const Text('Date'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            const SizedBox(height: 24),

            // Key Metrics (live)
            LayoutBuilder(
              builder: (context, constraints) {
                return GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: isMobile ? 2 : 4,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: isMobile ? 1.3 : 1.5,
                  children: [
                    FutureBuilder<int>(
                      future: _count(FirebaseFirestore.instance
                          .collection('student_profiles')),
                      builder: (context, s) => _buildMetricCard(
                        Icons.people,
                        (s.data ?? 0).toString(),
                        'Total Students',
                        Colors.blue,
                      ),
                    ),
                    FutureBuilder<int>(
                      future: _count(FirebaseFirestore.instance
                          .collection('tutor_profiles')
                          .where('status', isEqualTo: 'approved')),
                      builder: (context, s) => _buildMetricCard(
                        Icons.school,
                        (s.data ?? 0).toString(),
                        'Active Tutors',
                        Colors.green,
                      ),
                    ),
                    FutureBuilder<int>(
                      future: _count(
                          FirebaseFirestore.instance.collection('classes')),
                      builder: (context, s) => _buildMetricCard(
                        Icons.book,
                        (s.data ?? 0).toString(),
                        'Total Classes',
                        Colors.orange,
                      ),
                    ),
                    FutureBuilder<int>(
                      future: _monthlyVerifiedCount(),
                      builder: (context, s) => _buildMetricCard(
                        Icons.verified,
                        (s.data ?? 0).toString(),
                        'Verified Payments (month)',
                        Colors.purple,
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),

            // Subject Distribution (live)
            Container(
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
              child: FutureBuilder<Map<String, int>>(
                future: _loadSubjectDistribution(),
                builder: (context, s) {
                  final data = s.data ?? _subjectDistribution;
                  if (data.isEmpty) {
                    return const Text('No class data');
                  }
                  final total = data.values.fold<int>(0, (a, b) => a + b);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Subject Distribution',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 20),
                      ...data.entries.map((entry) {
                        final percentage = total == 0
                            ? 0
                            : ((entry.value / total) * 100).round();
                        return _buildDistributionBar(
                          entry.key,
                          entry.value,
                          percentage,
                          _getSubjectColor(entry.key),
                          isMobile,
                        );
                      }),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 24),

            // Revenue and Payment Status (live)
            if (!isMobile)
              Row(
                children: [
                  Expanded(child: _buildRevenueCard()),
                  const SizedBox(width: 16),
                  Expanded(child: _buildPaymentStatusCard()),
                ],
              )
            else
              Column(
                children: [
                  _buildRevenueCard(),
                  const SizedBox(height: 16),
                  _buildPaymentStatusCard(),
                ],
              ),
            const SizedBox(height: 24),

            // Outstanding Dues (live)
            _buildOutstandingDuesCard(isMobile),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(
      IconData icon, String value, String label, Color color) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 20),
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
          Icon(icon, size: isMobile ? 24 : 28, color: color),
          const SizedBox(height: 8),
          FittedBox(
            child: Text(
              value,
              style: TextStyle(
                fontSize: isMobile ? 18 : 24,
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
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDistributionBar(
    String subject,
    int count,
    int percentage,
    Color color,
    bool isMobile,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: Text(
                  subject,
                  style: TextStyle(fontSize: isMobile ? 12 : 14),
                ),
              ),
              if (!isMobile) ...[
                Text('$count classes'),
                const SizedBox(width: 8),
                SizedBox(
                  width: 40,
                  child: Text(
                    '$percentage%',
                    textAlign: TextAlign.right,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ],
          ),
          if (isMobile) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: percentage / 100,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    minHeight: 8,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '$percentage%',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ] else ...[
            const SizedBox(height: 4),
            LinearProgressIndicator(
              value: percentage / 100,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 8,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRevenueCard() {
    final isMobile = MediaQuery.of(context).size.width < 600;

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
          const Text(
            'Monthly Revenue',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          FutureBuilder<double>(
            future: _monthlyRevenue(),
            builder: (context, s) {
              final v = 'LKR ${(s.data ?? 0).toStringAsFixed(0)}';
              return Center(
                child: Text(
                  v,
                  style: TextStyle(
                    fontSize: isMobile ? 28 : 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            },
          ),
          Center(
            child: Text(
              'This Month',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ),
          const SizedBox(height: 20),
          _buildRevenueItem('Verified Payments (This Month):', ''),
        ],
      ),
    );
  }

  Widget _buildPaymentStatusCard() {
    return Container(
      padding: const EdgeInsets.all(20),
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
          const Text(
            'Payment Status',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          FutureBuilder<int>(
            future: _count(FirebaseFirestore.instance
                .collection('payments')
                .where('verifyStatus', isEqualTo: 'verified')),
            builder: (context, s) =>
                _buildPaymentStatus('Verified', s.data ?? 0, Colors.green),
          ),
          FutureBuilder<int>(
            future: _count(FirebaseFirestore.instance
                .collection('payments')
                .where('verifyStatus', isEqualTo: 'pending')),
            builder: (context, s) =>
                _buildPaymentStatus('Pending', s.data ?? 0, Colors.orange),
          ),
          FutureBuilder<int>(
            future: _count(FirebaseFirestore.instance
                .collection('payments')
                .where('verifyStatus', isEqualTo: 'rejected')),
            builder: (context, s) =>
                _buildPaymentStatus('Rejected', s.data ?? 0, Colors.red),
          ),
        ],
      ),
    );
  }

  Widget _buildOutstandingDuesCard(bool isMobile) {
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
          const Text(
            'Outstanding Dues',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          FutureBuilder<_OutstandingSummary>(
            future: _computeOutstanding(),
            builder: (context, s) {
              final sum = s.data?.totalAmount ?? 0;
              final countUnpaid = s.data?.unpaidCount ?? 0;
              final overdue = s.data?.overdueCount ?? 0;
              final children = [
                _buildDueItem('LKR ${sum.toStringAsFixed(0)}',
                    'Total Outstanding', Colors.red, true),
                _buildDueItem(
                    '$countUnpaid', 'Unpaid Invoices', Colors.black, false),
                _buildDueItem(
                    '$overdue', 'Overdue > 30 days', Colors.orange, false),
              ];
              if (isMobile) {
                return Column(children: [
                  children[0],
                  const SizedBox(height: 16),
                  children[1],
                  const SizedBox(height: 16),
                  children[2],
                ]);
              } else {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: children,
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Color _getSubjectColor(String subject) {
    switch (subject) {
      case 'Mathematics':
        return Colors.red;
      case 'Physics':
        return Colors.yellow[700]!;
      case 'Chemistry':
        return Colors.green;
      case 'Biology':
        return Colors.cyan;
      case 'Combined Mathematics':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Widget _buildRevenueItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildPaymentStatus(String status, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Text(status),
          const Spacer(),
          Text(
            count.toString(),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildDueItem(String value, String label, Color color, bool isAmount) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: isAmount ? color : Colors.black,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  // Data helpers
  Future<int> _count(Query<Map<String, dynamic>> query) async {
    try {
      final agg = await query.count().get();
      return agg.count ?? 0;
    } catch (_) {
      try {
        final snap = await query.limit(1000).get();
        return snap.size;
      } catch (_) {
        return 0;
      }
    }
  }

  Future<int> _monthlyVerifiedCount() async {
    try {
      final now = DateTime.now();
      final start = DateTime(now.year, now.month, 1);
      final end = DateTime(now.year, now.month + 1, 1);
      final qs = await FirebaseFirestore.instance
          .collection('payments')
          .where('verifyStatus', isEqualTo: 'verified')
          .where('paidAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('paidAt', isLessThan: Timestamp.fromDate(end))
          .get();
      return qs.size;
    } catch (_) {
      return 0;
    }
  }

  Future<double> _monthlyRevenue() async {
    try {
      final now = DateTime.now();
      final start = DateTime(now.year, now.month, 1);
      final end = DateTime(now.year, now.month + 1, 1);
      final qs = await FirebaseFirestore.instance
          .collection('payments')
          .where('verifyStatus', isEqualTo: 'verified')
          .where('paidAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('paidAt', isLessThan: Timestamp.fromDate(end))
          .get();
      double sum = 0;
      for (final d in qs.docs) {
        final data = d.data();
        final num? v = data['paidAmount'] as num? ?? data['amountDue'] as num?;
        if (v != null) sum += v.toDouble();
      }
      return sum;
    } catch (_) {
      return 0;
    }
  }

  Future<Map<String, int>> _loadSubjectDistribution() async {
    try {
      final qs = await FirebaseFirestore.instance
          .collection('classes')
          .where('status', isEqualTo: 'published')
          .limit(1000)
          .get();
      final Map<String, int> counts = <String, int>{};
      for (final d in qs.docs) {
        final data = d.data();
        final code = (data['subject_code'] as String?) ?? '';
        final label = _subjectLabel(code);
        if (label.isEmpty) continue;
        counts[label] = (counts[label] ?? 0) + 1;
      }
      if (mounted) setState(() => _subjectDistribution = counts);
      return counts;
    } catch (_) {
      return _subjectDistribution;
    }
  }

  String _subjectLabel(String? code) {
    if (code == null || code.isEmpty) return '';
    final match = kSubjectOptions.firstWhere(
      (s) => s.code == code,
      orElse: () => SubjectOption(code: code, label: code),
    );
    return match.label;
  }

  Future<_OutstandingSummary> _computeOutstanding() async {
    try {
      final qs = await FirebaseFirestore.instance
          .collection('invoices')
          .limit(1000)
          .get();
      double total = 0;
      int unpaid = 0;
      int overdue = 0;
      final now = DateTime.now();
      for (final d in qs.docs) {
        final m = d.data();
        final status = (m['status'] as String?)?.toLowerCase() ?? '';
        final num? amount = m['amountDue'] as num?;
        final due = m['dueDate'];
        DateTime? dueDate;
        if (due is Timestamp) dueDate = due.toDate();
        if (status != 'paid') {
          unpaid += 1;
          if (amount != null) total += amount.toDouble();
          if (dueDate != null && now.difference(dueDate).inDays > 30) {
            overdue += 1;
          }
        }
      }
      return _OutstandingSummary(
          totalAmount: total, unpaidCount: unpaid, overdueCount: overdue);
    } catch (_) {
      return _OutstandingSummary(
          totalAmount: 0, unpaidCount: 0, overdueCount: 0);
    }
  }
}

class _OutstandingSummary {
  _OutstandingSummary(
      {required this.totalAmount,
      required this.unpaidCount,
      required this.overdueCount});
  final double totalAmount;
  final int unpaidCount;
  final int overdueCount;
}
