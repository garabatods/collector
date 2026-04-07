import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class CollectorSectionHeader extends StatelessWidget {
  const CollectorSectionHeader({
    super.key,
    required this.title,
    this.trailing,
  });

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title.toUpperCase(),
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppColors.outline,
              ),
        ),
        const Spacer(),
        if (trailing != null) ...[
          trailing!,
          const SizedBox(width: AppSpacing.xxs),
        ],
      ],
    );
  }
}
