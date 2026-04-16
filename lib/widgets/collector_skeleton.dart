import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'collector_panel.dart';

class CollectorSkeletonBlock extends StatefulWidget {
  const CollectorSkeletonBlock({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
    this.shape = BoxShape.rectangle,
  });

  final double? width;
  final double? height;
  final BorderRadiusGeometry? borderRadius;
  final BoxShape shape;

  @override
  State<CollectorSkeletonBlock> createState() => _CollectorSkeletonBlockState();
}

class _CollectorSkeletonBlockState extends State<CollectorSkeletonBlock>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final borderRadius =
        widget.shape == BoxShape.circle
            ? null
            : widget.borderRadius ?? BorderRadius.circular(12);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final offset = (_controller.value * 2.4) - 1.2;
        return SizedBox(
          width: widget.width,
          height: widget.height,
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: widget.shape,
              borderRadius: borderRadius,
              gradient: LinearGradient(
                begin: Alignment(-1.8 + offset, -0.2),
                end: Alignment(-0.2 + offset, 0.2),
                colors: [
                  AppColors.surfaceContainer,
                  AppColors.surfaceContainerHighest.withValues(alpha: 0.96),
                  AppColors.surfaceContainer,
                ],
                stops: const [0.12, 0.42, 0.72],
              ),
            ),
          ),
        );
      },
    );
  }
}

class CollectorSectionHeaderSkeleton extends StatelessWidget {
  const CollectorSectionHeaderSkeleton({super.key, this.trailingWidth = 84});

  final double trailingWidth;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const CollectorSkeletonBlock(width: 132, height: 26),
        const Spacer(),
        CollectorSkeletonBlock(width: trailingWidth, height: 20),
      ],
    );
  }
}

class CollectorSearchFieldSkeleton extends StatelessWidget {
  const CollectorSearchFieldSkeleton({super.key, this.height = 64});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer.withValues(alpha: 0.84),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.18),
        ),
      ),
      child: const Row(
        children: [
          CollectorSkeletonBlock(
            width: 22,
            height: 22,
            borderRadius: BorderRadius.all(Radius.circular(999)),
          ),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: CollectorSkeletonBlock(
              height: 18,
              borderRadius: BorderRadius.all(Radius.circular(999)),
            ),
          ),
        ],
      ),
    );
  }
}

class CollectorGridCardSkeleton extends StatelessWidget {
  const CollectorGridCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return CollectorPanel(
      padding: EdgeInsets.zero,
      backgroundColor: AppColors.surfaceContainer.withValues(alpha: 0.94),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 8,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: const CollectorSkeletonBlock(
                width: double.infinity,
                height: double.infinity,
                borderRadius: BorderRadius.zero,
              ),
            ),
          ),
          Expanded(
            flex: 5,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  CollectorSkeletonBlock(height: 16),
                  SizedBox(height: AppSpacing.xs),
                  CollectorSkeletonBlock(width: 72, height: 12),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CollectorListCardSkeleton extends StatelessWidget {
  const CollectorListCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        children: const [
          ClipRRect(
            borderRadius: BorderRadius.all(Radius.circular(8)),
            child: CollectorSkeletonBlock(
              width: 40,
              height: 40,
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
          ),
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CollectorSkeletonBlock(height: 14),
                SizedBox(height: 6),
                CollectorSkeletonBlock(width: 88, height: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CollectorCategoryCardSkeleton extends StatelessWidget {
  const CollectorCategoryCardSkeleton({
    super.key,
    this.height = 84,
    this.compact = false,
  });

  final double height;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return CollectorPanel(
      padding: const EdgeInsets.all(AppSpacing.md),
      backgroundColor: AppColors.surfaceContainer.withValues(alpha: 0.92),
      child: SizedBox(
        height: height,
        child: Row(
          children: [
            CollectorSkeletonBlock(
              width: compact ? 40 : 44,
              height: compact ? 40 : 44,
              borderRadius: BorderRadius.circular(12),
            ),
            const SizedBox(width: AppSpacing.md),
            const Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CollectorSkeletonBlock(height: 16),
                  SizedBox(height: AppSpacing.sm),
                  CollectorSkeletonBlock(width: 72, height: 12),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
