import 'package:flutter/material.dart';
import '../theme.dart';

class RoleOptionCard extends StatelessWidget {
  final IconData icon;
  final Color iconBackgroundColor;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const RoleOptionCard({
    super.key,
    required this.icon,
    required this.iconBackgroundColor,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppTheme.primaryCardRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.primaryCardRadius),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.subtleBorder, width: 1),
            borderRadius: BorderRadius.circular(AppTheme.primaryCardRadius),
          ),
          child: Row(
            children: [
              // Icon container
              Container(
                width: AppTheme.roleCardIconSize,
                height: AppTheme.roleCardIconSize,
                decoration: BoxDecoration(
                  color: iconBackgroundColor,
                  borderRadius: BorderRadius.circular(
                    AppTheme.iconContainerRadius,
                  ),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),

              const SizedBox(width: 14),

              // Text content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(title, style: AppTheme.cardTitleStyle),
                    const SizedBox(height: 4),
                    Text(subtitle, style: AppTheme.cardSubtitleStyle),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
