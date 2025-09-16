// Auto-generated for Student Dashboard — paste-ready.
import 'package:flutter/material.dart';
import '../theme.dart';

class EnrolledClassCard extends StatelessWidget {
  final String id;
  final String title;
  final String tutorName;
  final String schedule;
  final int progressCurrent;
  final int progressTotal;
  final double rating;
  final String nextSession;
  final String status;
  final VoidCallback onTap;

  const EnrolledClassCard({
    super.key,
    required this.id,
    required this.title,
    required this.tutorName,
    required this.schedule,
    required this.progressCurrent,
    required this.progressTotal,
    required this.rating,
    required this.nextSession,
    required this.status,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final progress = progressCurrent / progressTotal;
    final isUpcoming = status == 'upcoming';

    return Semantics(
      label: '$title class with $tutorName, next session $nextSession',
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isUpcoming ? const Color(0xFFEBF5FF) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isUpcoming
                  ? AppTheme.brandPrimary.withValues(alpha: 0.3)
                  : AppTheme.borderSubtle,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isUpcoming)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.brandPrimary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Next Class: $title with $tutorName',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor:
                        AppTheme.brandPrimary.withValues(alpha: 0.1),
                    child: Text(
                      tutorName.substring(0, 2).toUpperCase(),
                      style: const TextStyle(
                        color: AppTheme.brandPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          tutorName,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        schedule,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.star, size: 16, color: Colors.amber),
                          const SizedBox(width: 4),
                          Text(
                            rating.toString(),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Progress',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        '$progressCurrent/$progressTotal lessons',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: progress,
                    backgroundColor: AppTheme.borderSubtle,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      progress > 0.7
                          ? AppTheme.brandSecondary
                          : AppTheme.brandPrimary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
