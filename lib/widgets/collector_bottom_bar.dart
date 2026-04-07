import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_spacing.dart';

class CollectorBottomBarItemData {
  const CollectorBottomBarItemData({
    required this.icon,
    required this.label,
    this.active = false,
    this.onTap,
    this.isCenterAction = false,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback? onTap;
  final bool isCenterAction;
}

class CollectorBottomBar extends StatelessWidget {
  const CollectorBottomBar({
    super.key,
    required this.items,
  });

  final List<CollectorBottomBarItemData> items;

  static const double _shellHeight = 76;
  static const double _centerActionSize = 60;
  static const double _centerActionHeight = 60;
  static const double _centerActionOverlap = 0;
  static const double _centerGap = 84;
  static const double _centerActionBottomOffset =
      (_shellHeight - _centerActionHeight) / 2;

  @override
  Widget build(BuildContext context) {
    final regularItems = items.where((item) => !item.isCenterAction).toList();
    final centerItem = items.cast<CollectorBottomBarItemData?>().firstWhere(
          (item) => item?.isCenterAction ?? false,
          orElse: () => null,
        );

    final totalHeight = _shellHeight + _centerActionOverlap;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.xs,
          AppSpacing.md,
          AppSpacing.xs,
        ),
        child: SizedBox(
          height: totalHeight,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomCenter,
            children: [
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _BottomBarShell(
                  height: _shellHeight,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      for (var index = 0; index < regularItems.length; index++) ...[
                        Expanded(
                          child: _CollectorBottomBarItem(
                            item: regularItems[index],
                          ),
                        ),
                        if (index == 1) const SizedBox(width: _centerGap),
                      ],
                    ],
                  ),
                ),
              ),
              if (centerItem != null)
                Positioned(
                  bottom: _centerActionBottomOffset,
                  child: _CollectorCenterAction(
                    item: centerItem,
                    size: _centerActionSize,
                    height: _centerActionHeight,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomBarShell extends StatelessWidget {
  const _BottomBarShell({
    required this.height,
    required this.child,
  });

  final double height;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: AppRadii.extraLarge,
        boxShadow: const [
          BoxShadow(
            color: AppColors.softShadow,
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: AppRadii.extraLarge,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
          child: Container(
            height: height,
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.sm,
              8,
              AppSpacing.sm,
              AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: AppColors.background.withValues(alpha: 0.08),
              border: Border.all(
                color: AppColors.onSurface.withValues(alpha: 0.05),
              ),
            ),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class _CollectorBottomBarItem extends StatelessWidget {
  const _CollectorBottomBarItem({
    required this.item,
  });

  final CollectorBottomBarItemData item;

  @override
  Widget build(BuildContext context) {
    final foreground = item.active ? AppColors.primary : AppColors.onSurfaceVariant;

    return Center(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: item.onTap,
          borderRadius: AppRadii.large,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            constraints: BoxConstraints(
              minWidth: item.active ? 76 : 68,
              minHeight: 52,
            ),
            padding: EdgeInsets.symmetric(
              horizontal: item.active ? 14 : 8,
              vertical: item.active ? 8 : 6,
            ),
            decoration: BoxDecoration(
              color: item.active
                  ? AppColors.primary.withValues(alpha: 0.12)
                  : Colors.transparent,
              borderRadius: AppRadii.large,
              border: item.active
                  ? Border.all(
                      color: AppColors.primary.withValues(alpha: 0.06),
                    )
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  item.icon,
                  color: foreground,
                  size: item.active ? 20 : 19,
                ),
                const SizedBox(height: 5),
                SizedBox(
                  height: 11,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      item.label.toUpperCase(),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: foreground,
                            fontSize: 9.5,
                            height: 1,
                            letterSpacing: 0.8,
                          ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CollectorCenterAction extends StatelessWidget {
  const _CollectorCenterAction({
    required this.item,
    required this.size,
    required this.height,
  });

  final CollectorBottomBarItemData item;
  final double size;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkResponse(
        onTap: item.onTap,
        radius: size / 1.3,
        containedInkWell: false,
        child: Semantics(
          button: true,
          label: item.label,
          child: SizedBox(
            height: height,
            child: DecoratedBox(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppColors.primaryGradient,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryShadowHalo,
                    blurRadius: 28,
                    offset: Offset(0, 12),
                  ),
                ],
              ),
              child: SizedBox(
                width: size,
                height: size,
                child: Icon(
                  item.icon,
                  size: 30,
                  color: AppColors.onPrimary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
