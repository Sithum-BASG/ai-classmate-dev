import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme.dart';

class TutorReviewsPage extends StatelessWidget {
  const TutorReviewsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Scaffold(
        body: Center(child: Text('Please sign in as a tutor.')),
      );
    }
    final ratingsRef = FirebaseFirestore.instance
        .collection('tutor_profiles')
        .doc(uid)
        .collection('ratings')
        .orderBy('updatedAt', descending: true);

    return Scaffold(
      backgroundColor: AppTheme.brandSurface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/tutor/profile');
            }
          },
        ),
        title: const Text('Reviews & Ratings'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: ratingsRef.snapshots(),
        builder: (context, snap) {
          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('No reviews yet.'));
          }
          double avg = 0.0;
          for (final d in docs) {
            avg += (d.data()['rating'] as num?)?.toDouble() ?? 0;
          }
          final count = docs.length;
          avg = count == 0 ? 0.0 : avg / count;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return _SummaryCard(avg: avg, count: count);
              }
              final d = docs[index - 1];
              final r = d.data();
              final rating = (r['rating'] as num?)?.toInt() ?? 0;
              final review = (r['review'] as String?) ?? '';
              return _ReviewTile(rating: rating, review: review);
            },
          );
        },
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final double avg;
  final int count;
  const _SummaryCard({required this.avg, required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.star, color: Colors.amber),
          const SizedBox(width: 8),
          Text('${avg.toStringAsFixed(1)} ($count reviews)',
              style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _ReviewTile extends StatelessWidget {
  final int rating;
  final String review;
  const _ReviewTile({required this.rating, required this.review});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: List.generate(5, (i) {
              final filled = rating >= i + 1;
              return Icon(
                filled ? Icons.star : Icons.star_border,
                size: 16,
                color: filled ? AppTheme.brandPrimary : Colors.grey,
              );
            }),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              review.isEmpty ? 'No comment' : review,
              style: const TextStyle(fontSize: 13),
            ),
          )
        ],
      ),
    );
  }
}
