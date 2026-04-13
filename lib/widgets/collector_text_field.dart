import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_spacing.dart';

class CollectorTextField extends StatefulWidget {
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
    this.onChanged,
    this.showClearButton = true,
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
  final ValueChanged<String>? onChanged;
  final bool showClearButton;

  @override
  State<CollectorTextField> createState() => _CollectorTextFieldState();
}

class _CollectorTextFieldState extends State<CollectorTextField> {
  TextEditingController? _internalController;
  late final FocusNode _focusNode;

  TextEditingController get _controller =>
      widget.controller ?? _internalController!;

  bool get _shouldShowClearButton {
    return widget.showClearButton &&
        !widget.obscureText &&
        _focusNode.hasFocus &&
        _controller.text.isNotEmpty;
  }

  @override
  void initState() {
    super.initState();
    _internalController = widget.controller == null
        ? TextEditingController()
        : null;
    _focusNode = FocusNode();
    _controller.addListener(_handleInputStateChanged);
    _focusNode.addListener(_handleInputStateChanged);
  }

  @override
  void didUpdateWidget(covariant CollectorTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller == widget.controller) {
      return;
    }

    final oldController = oldWidget.controller ?? _internalController;
    oldController?.removeListener(_handleInputStateChanged);
    if (oldWidget.controller == null) {
      oldController?.dispose();
    }

    _internalController = widget.controller == null
        ? TextEditingController()
        : null;
    _controller.addListener(_handleInputStateChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_handleInputStateChanged);
    if (widget.controller == null) {
      _internalController?.dispose();
    }
    _focusNode
      ..removeListener(_handleInputStateChanged)
      ..dispose();
    super.dispose();
  }

  void _handleInputStateChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _clearText() {
    _controller.clear();
    widget.onChanged?.call('');
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label.isNotEmpty) ...[
          Text(
            widget.label.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall,
          ),
          const SizedBox(height: AppSpacing.xs),
        ],
        TextField(
          controller: _controller,
          focusNode: _focusNode,
          keyboardType: widget.keyboardType,
          obscureText: widget.obscureText,
          textInputAction: widget.textInputAction,
          autofillHints: widget.autofillHints,
          onChanged: widget.onChanged,
          onTapOutside: (_) => _focusNode.unfocus(),
          decoration: InputDecoration(
            hintText: widget.hintText,
            errorText: widget.errorText,
            prefixIcon: widget.prefixIcon == null
                ? null
                : Icon(widget.prefixIcon, color: AppColors.onSurfaceVariant),
            suffixIcon: _shouldShowClearButton
                ? IconButton(
                    tooltip: 'Clear',
                    onPressed: _clearText,
                    icon: const Icon(Icons.close_rounded, size: 18),
                    color: AppColors.onSurfaceVariant,
                  )
                : null,
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

class CollectorSearchField extends StatefulWidget {
  const CollectorSearchField({
    super.key,
    required this.hintText,
    this.fillColor,
    this.iconColor,
    this.hintColor,
    this.controller,
    this.focusNode,
    this.onTap,
    this.onChanged,
    this.readOnly = true,
    this.autofocus = false,
    this.suffixIcon,
    this.showClearButton = true,
  });

  final String hintText;
  final Color? fillColor;
  final Color? iconColor;
  final Color? hintColor;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged;
  final bool readOnly;
  final bool autofocus;
  final Widget? suffixIcon;
  final bool showClearButton;

  @override
  State<CollectorSearchField> createState() => _CollectorSearchFieldState();
}

class _CollectorSearchFieldState extends State<CollectorSearchField> {
  TextEditingController? _internalController;
  FocusNode? _internalFocusNode;

  TextEditingController get _controller =>
      widget.controller ?? _internalController!;
  FocusNode? get _focusNode => widget.focusNode ?? _internalFocusNode;

  bool get _shouldShowClearButton {
    return widget.showClearButton &&
        !widget.readOnly &&
        widget.suffixIcon == null &&
        _controller.text.isNotEmpty;
  }

  @override
  void initState() {
    super.initState();
    _internalController = widget.controller == null
        ? TextEditingController()
        : null;
    _internalFocusNode = widget.focusNode == null ? FocusNode() : null;
    _controller.addListener(_handleInputStateChanged);
  }

  @override
  void didUpdateWidget(covariant CollectorSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      final oldController = oldWidget.controller ?? _internalController;
      oldController?.removeListener(_handleInputStateChanged);
      if (oldWidget.controller == null) {
        oldController?.dispose();
      }
      _internalController = widget.controller == null
          ? TextEditingController()
          : null;
      _controller.addListener(_handleInputStateChanged);
    }

    if (oldWidget.focusNode != widget.focusNode) {
      if (oldWidget.focusNode == null) {
        _internalFocusNode?.dispose();
      }
      _internalFocusNode = widget.focusNode == null ? FocusNode() : null;
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_handleInputStateChanged);
    if (widget.controller == null) {
      _internalController?.dispose();
    }
    if (widget.focusNode == null) {
      _internalFocusNode?.dispose();
    }
    super.dispose();
  }

  void _handleInputStateChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _clearText() {
    _controller.clear();
    widget.onChanged?.call('');
    _focusNode?.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      focusNode: _focusNode,
      readOnly: widget.readOnly,
      autofocus: widget.autofocus,
      onTap: widget.onTap,
      onChanged: widget.onChanged,
      onTapOutside: (_) => _focusNode?.unfocus(),
      decoration: InputDecoration(
        filled: true,
        fillColor: widget.fillColor ?? AppColors.surfaceContainerHighest,
        hintText: widget.hintText,
        hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: widget.hintColor ?? AppColors.onSurfaceVariant,
        ),
        prefixIcon: Icon(
          Icons.search,
          color: widget.iconColor ?? AppColors.onSurfaceVariant,
        ),
        suffixIcon:
            widget.suffixIcon ??
            (_shouldShowClearButton
                ? IconButton(
                    tooltip: 'Clear search',
                    onPressed: _clearText,
                    icon: const Icon(Icons.close_rounded, size: 18),
                    color: AppColors.onSurfaceVariant,
                  )
                : null),
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
