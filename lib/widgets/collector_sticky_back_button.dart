import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import 'collector_button.dart';

class CollectorStickyBackButton extends StatelessWidget {
  const CollectorStickyBackButton({
    super.key,
    required this.onPressed,
    this.label = 'Back',
  });

  final VoidCallback onPressed;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.only(
            left: AppSpacing.md,
            top: AppSpacing.md,
          ),
          child: CollectorButton(
            label: label,
            onPressed: onPressed,
            variant: CollectorButtonVariant.icon,
            icon: Icons.arrow_back_rounded,
          ),
        ),
      ),
    );
  }
}
