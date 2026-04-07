import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_spacing.dart';

class CollectorTextField extends StatelessWidget {
  const CollectorTextField({
    super.key,
    required this.label,
    required this.hintText,
    this.prefixIcon,
    this.controller,
    this.keyboardType,
    this.obscureText = false,
    this.textInputAction,
    this.autofillHints,
    this.errorText,
  });

  final String label;
  final String hintText;
  final IconData? prefixIcon;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final bool obscureText;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty) ...[
          Text(
            label.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall,
          ),
          const SizedBox(height: AppSpacing.xs),
        ],
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          textInputAction: textInputAction,
          autofillHints: autofillHints,
          decoration: InputDecoration(
            hintText: hintText,
            errorText: errorText,
            prefixIcon: prefixIcon == null
                ? null
                : Icon(
                    prefixIcon,
                    color: AppColors.onSurfaceVariant,
                  ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
            enabledBorder: const OutlineInputBorder(
              borderRadius: AppRadii.medium,
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: AppRadii.medium,
              borderSide: BorderSide(
                color: AppColors.primary.withValues(alpha: 0.5),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class CollectorSearchField extends StatelessWidget {
  const CollectorSearchField({
    super.key,
    required this.hintText,
    this.fillColor,
    this.iconColor,
    this.hintColor,
    this.controller,
    this.onTap,
    this.onChanged,
    this.readOnly = true,
    this.autofocus = false,
    this.suffixIcon,
  });

  final String hintText;
  final Color? fillColor;
  final Color? iconColor;
  final Color? hintColor;
  final TextEditingController? controller;
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged;
  final bool readOnly;
  final bool autofocus;
  final Widget? suffixIcon;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
      autofocus: autofocus,
      onTap: onTap,
      onChanged: onChanged,
      decoration: InputDecoration(
        filled: true,
        fillColor: fillColor ?? AppColors.surfaceContainerHighest,
        hintText: hintText,
        hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: hintColor ?? AppColors.onSurfaceVariant,
            ),
        prefixIcon: Icon(
          Icons.search,
          color: iconColor ?? AppColors.onSurfaceVariant,
        ),
        suffixIcon: suffixIcon,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: AppRadii.medium,
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadii.medium,
          borderSide: BorderSide(
            color: AppColors.primary.withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }
}
