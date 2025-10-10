import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme.dart';

class TutorAnnouncementsPage extends StatelessWidget {
  const TutorAnnouncementsPage({super.key});

  Stream<QuerySnapshot<Map<String, dynamic>>> _stream() {
    return FirebaseFirestore.instance
        .collection('announcements')
        .orderBy('created_at', descending: true)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.brandSurface,
      appBar: AppBar(
        title: const Text('Announcements'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go('/tutor');
            }
          },
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _stream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Failed to load: ${snapshot.error}'));
          }
          final docs = snapshot.data?.docs ?? const [];
          // Filter by audience: show only All Users or Tutors Only
          final filtered = docs.where((d) {
            final a = d.data();
            final aud = ((a['audience'] as String?) ?? 'All Users').trim();
            return aud == 'All Users' || aud == 'Tutors Only';
          }).toList();
          if (filtered.isEmpty) {
            return const Center(child: Text('No announcements'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemCount: filtered.length,
            itemBuilder: (context, i) {
              final a = filtered[i].data();
              final title = (a['title'] as String?) ?? 'Announcement';
              final msg = (a['message'] as String?) ?? '';
              final audience = (a['audience'] as String?) ?? 'All Users';
              final date = (a['date'] as String?) ?? _fmtDate(a['created_at']);
              final status = (a['status'] as String?) ?? '';
              return _Card(
                title: title,
                message: msg,
                audience: audience,
                date: date,
                status: status,
              );
            },
          );
        },
      ),
    );
  }

  static String _fmtDate(dynamic createdAt) {
    if (createdAt == null) return '';
    try {
      if (createdAt is Timestamp)
        return createdAt.toDate().toIso8601String().split('T').first;
      if (createdAt is DateTime)
        return createdAt.toIso8601String().split('T').first;
      return createdAt.toString();
    } catch (_) {
      return '';
    }
  }
}

class _Card extends StatelessWidget {
  const _Card(
      {required this.title,
      required this.message,
      required this.audience,
      required this.date,
      required this.status});
  final String title;
  final String message;
  final String audience;
  final String date;
  final String status;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(title,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text('To: $audience',
                    style: const TextStyle(
                        fontSize: 12, color: AppTheme.mutedText)),
              ])),
          if (status.isNotEmpty)
            Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                    color: AppTheme.brandPrimary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20)),
                child: Text(status,
                    style: const TextStyle(
                        color: AppTheme.brandPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600))),
        ]),
        const SizedBox(height: 12),
        Text(message,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppTheme.mutedText)),
        const SizedBox(height: 12),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(date,
              style: const TextStyle(fontSize: 12, color: AppTheme.mutedText)),
          const SizedBox(),
        ]),
      ]),
    );
  }
}
