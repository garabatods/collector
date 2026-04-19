import 'package:flutter/material.dart';

import '../core/collector_haptics.dart';
import '../core/data/archive_types.dart';
import '../features/collection/data/models/collectible_detail_navigation_context.dart';
import '../features/collection/data/models/collectible_model.dart';
import '../features/collection/data/repositories/collectibles_repository.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'archive_photo_view.dart';
import 'collector_panel.dart';
import 'collector_skeleton.dart';
import 'collector_snack_bar.dart';
import '../screens/collectible_detail_screen.dart';

class CollectibleGridCard extends StatefulWidget {
  const CollectibleGridCard({
    super.key,
    required this.collectible,
    required this.photoRef,
    required this.onCollectionChanged,
    this.detailNavigationContext,
    this.onCollectibleUpdated,
    this.selectionMode = false,
    this.selected = false,
    this.onSelectionTap,
    this.onLongPressSelection,
  });

  final CollectibleModel collectible;
  final ArchivePhotoRef? photoRef;
  final Future<void> Function() onCollectionChanged;
  final CollectibleDetailNavigationContext? detailNavigationContext;
  final ValueChanged<CollectibleModel>? onCollectibleUpdated;
  final bool selectionMode;
  final bool selected;
  final VoidCallback? onSelectionTap;
  final VoidCallback? onLongPressSelection;

  @override
  State<CollectibleGridCard> createState() => _CollectibleGridCardState();
}

class _CollectibleGridCardState extends State<CollectibleGridCard> {
  final _collectiblesRepository = CollectiblesRepository();

  late bool _isFavorite;
  var _isUpdatingFavorite = false;

  @override
  void initState() {
    super.initState();
    _isFavorite = widget.collectible.isFavorite;
  }

  @override
  void didUpdateWidget(covariant CollectibleGridCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.collectible.id != widget.collectible.id ||
        oldWidget.collectible.isFavorite != widget.collectible.isFavorite) {
      _isFavorite = widget.collectible.isFavorite;
    }
  }

  Future<void> _openDetails() async {
    CollectorHaptics.light();
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => CollectibleDetailScreen(
          collectible: widget.collectible.copyWith(isFavorite: _isFavorite),
          photoRef: widget.photoRef,
          navigationContext: widget.detailNavigationContext,
        ),
      ),
    );

    if (changed == true) {
      await widget.onCollectionChanged();
    }
  }

  Future<void> _toggleFavorite() async {
    if (_isUpdatingFavorite || widget.collectible.id == null) {
      return;
    }

    CollectorHaptics.selection();
    final nextValue = !_isFavorite;
    setState(() {
      _isFavorite = nextValue;
      _isUpdatingFavorite = true;
    });

    try {
      final updatedCollectible = widget.collectible.copyWith(
        isFavorite: nextValue,
      );
      await _collectiblesRepository.update(updatedCollectible);
      if (!mounted) {
        return;
      }
      widget.onCollectibleUpdated?.call(updatedCollectible);
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isFavorite = !nextValue;
      });
      CollectorSnackBar.show(
        context,
        message: 'Could not update favorite right now.',
        tone: CollectorSnackBarTone.error,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUpdatingFavorite = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSelectionMode = widget.selectionMode;
    final isSelected = widget.selected;
    final photoTags = <Widget>[
      if (widget.collectible.isGrail)
        const _PhotoStatusTag(
          label: 'GRAIL',
          backgroundColor: AppColors.secondaryContainer,
          foregroundColor: AppColors.secondary,
          borderColor: AppColors.secondary,
        ),
      if (widget.collectible.isDuplicate)
        const _PhotoStatusTag(
          label: 'DUPLICATE',
          backgroundColor: AppColors.tertiaryContainer,
          foregroundColor: AppColors.tertiary,
          borderColor: AppColors.tertiary,
        ),
    ];

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: isSelectionMode ? widget.onSelectionTap : _openDetails,
        onLongPress: widget.onLongPressSelection,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? AppColors.primary.withValues(alpha: 0.5)
                  : Colors.transparent,
              width: isSelected ? 1.5 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.16),
                      blurRadius: 18,
                      offset: const Offset(0, 10),
                    ),
                  ]
                : null,
          ),
          child: CollectorPanel(
            padding: EdgeInsets.zero,
            backgroundColor: isSelected
                ? AppColors.primary.withValues(alpha: 0.12)
                : AppColors.surfaceContainer.withValues(alpha: 0.94),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 8,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        ColoredBox(
                          color: AppColors.surfaceContainerHighest.withValues(
                            alpha: 0.72,
                          ),
                        ),
                        ArchivePhotoView(
                          photoRef: widget.photoRef,
                          fit: BoxFit.cover,
                          alignment: Alignment.center,
                          placeholder: const CollectorSkeletonBlock(
                            width: double.infinity,
                            height: double.infinity,
                            borderRadius: BorderRadius.zero,
                          ),
                          error: const Center(
                            child: Icon(
                              Icons.broken_image_outlined,
                              color: AppColors.onSurfaceVariant,
                              size: 28,
                            ),
                          ),
                        ),
                        if (isSelectionMode)
                          Positioned.fill(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primary.withValues(alpha: 0.18)
                                    : AppColors.background.withValues(
                                        alpha: 0.12,
                                      ),
                              ),
                            ),
                          ),
                        Positioned(
                          top: 5,
                          right: 5,
                          child: isSelectionMode
                              ? _SelectionIndicator(selected: isSelected)
                              : DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: AppColors.background.withValues(
                                      alpha: 0.58,
                                    ),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppColors.outlineVariant
                                          .withValues(alpha: 0.2),
                                    ),
                                  ),
                                  child: IconButton(
                                    onPressed: _isUpdatingFavorite
                                        ? null
                                        : _toggleFavorite,
                                    iconSize: 15,
                                    visualDensity: VisualDensity.compact,
                                    padding: const EdgeInsets.all(5),
                                    splashRadius: 16,
                                    color: _isFavorite
                                        ? AppColors.tertiary
                                        : AppColors.onSurface,
                                    icon: Icon(
                                      _isFavorite
                                          ? Icons.favorite_rounded
                                          : Icons.favorite_border_rounded,
                                    ),
                                  ),
                                ),
                        ),
                        if (photoTags.isNotEmpty && !isSelectionMode)
                          Positioned(
                            left: 5,
                            bottom: 5,
                            child: Wrap(
                              spacing: 4,
                              runSpacing: 4,
                              children: photoTags,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  flex: 5,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(4, 6, 4, 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.collectible.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(
                            context,
                          ).textTheme.labelLarge?.copyWith(height: 1.1),
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          widget.collectible.category.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: AppColors.onSurfaceVariant.withValues(
                                  alpha: 0.74,
                                ),
                                fontSize: 9,
                                letterSpacing: 0.7,
                              ),
                        ),
                      ],
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

class CollectibleListCard extends StatefulWidget {
  const CollectibleListCard({
    super.key,
    required this.collectible,
    required this.photoRef,
    required this.onCollectionChanged,
    this.detailNavigationContext,
    this.onCollectibleUpdated,
    this.selectionMode = false,
    this.selected = false,
    this.onSelectionTap,
    this.onLongPressSelection,
  });

  final CollectibleModel collectible;
  final ArchivePhotoRef? photoRef;
  final Future<void> Function() onCollectionChanged;
  final CollectibleDetailNavigationContext? detailNavigationContext;
  final ValueChanged<CollectibleModel>? onCollectibleUpdated;
  final bool selectionMode;
  final bool selected;
  final VoidCallback? onSelectionTap;
  final VoidCallback? onLongPressSelection;

  @override
  State<CollectibleListCard> createState() => _CollectibleListCardState();
}

class _CollectibleListCardState extends State<CollectibleListCard> {
  final _collectiblesRepository = CollectiblesRepository();

  late bool _isFavorite;
  var _isUpdatingFavorite = false;

  @override
  void initState() {
    super.initState();
    _isFavorite = widget.collectible.isFavorite;
  }

  @override
  void didUpdateWidget(covariant CollectibleListCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.collectible.id != widget.collectible.id ||
        oldWidget.collectible.isFavorite != widget.collectible.isFavorite) {
      _isFavorite = widget.collectible.isFavorite;
    }
  }

  Future<void> _openDetails() async {
    CollectorHaptics.light();
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => CollectibleDetailScreen(
          collectible: widget.collectible.copyWith(isFavorite: _isFavorite),
          photoRef: widget.photoRef,
          navigationContext: widget.detailNavigationContext,
        ),
      ),
    );

    if (changed == true) {
      await widget.onCollectionChanged();
    }
  }

  Future<void> _toggleFavorite() async {
    if (_isUpdatingFavorite || widget.collectible.id == null) {
      return;
    }

    CollectorHaptics.selection();
    final nextValue = !_isFavorite;
    setState(() {
      _isFavorite = nextValue;
      _isUpdatingFavorite = true;
    });

    try {
      final updatedCollectible = widget.collectible.copyWith(
        isFavorite: nextValue,
      );
      await _collectiblesRepository.update(updatedCollectible);
      if (!mounted) {
        return;
      }
      widget.onCollectibleUpdated?.call(updatedCollectible);
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isFavorite = !nextValue;
      });
      CollectorSnackBar.show(
        context,
        message: 'Could not update favorite right now.',
        tone: CollectorSnackBarTone.error,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUpdatingFavorite = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSelectionMode = widget.selectionMode;
    final isSelected = widget.selected;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isSelectionMode ? widget.onSelectionTap : _openDetails,
        onLongPress: widget.onLongPressSelection,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.12)
                : AppColors.surfaceContainer.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? AppColors.primary.withValues(alpha: 0.42)
                  : AppColors.outlineVariant.withValues(alpha: 0.12),
            ),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ColoredBox(
                        color: AppColors.surfaceContainerHighest,
                        child: ArchivePhotoView(
                          photoRef: widget.photoRef,
                          fit: BoxFit.cover,
                          alignment: Alignment.center,
                          placeholder: const CollectorSkeletonBlock(
                            width: double.infinity,
                            height: double.infinity,
                            borderRadius: BorderRadius.zero,
                          ),
                          error: const Icon(
                            Icons.broken_image_outlined,
                            color: AppColors.onSurfaceVariant,
                            size: 20,
                          ),
                        ),
                      ),
                      if (isSelectionMode)
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary.withValues(alpha: 0.18)
                                : AppColors.background.withValues(alpha: 0.1),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Flexible(
                      flex: 3,
                      child: Text(
                        widget.collectible.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      flex: 2,
                      child: Text(
                        widget.collectible.category.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.onSurfaceVariant.withValues(
                            alpha: 0.64,
                          ),
                          fontSize: 9,
                          letterSpacing: 0.75,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              if (isSelectionMode)
                _SelectionIndicator(selected: isSelected)
              else ...[
                IconButton(
                  onPressed: _isUpdatingFavorite ? null : _toggleFavorite,
                  iconSize: 18,
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints.tightFor(
                    width: 30,
                    height: 30,
                  ),
                  color: _isFavorite ? AppColors.tertiary : AppColors.onSurface,
                  icon: Icon(
                    _isFavorite
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: AppColors.onSurfaceVariant,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectionIndicator extends StatelessWidget {
  const _SelectionIndicator({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: selected
            ? AppColors.primary
            : AppColors.background.withValues(alpha: 0.36),
        shape: BoxShape.circle,
        border: Border.all(
          color: selected
              ? AppColors.primary
              : AppColors.outlineVariant.withValues(alpha: 0.4),
          width: 1.4,
        ),
      ),
      child: Icon(
        selected ? Icons.check_rounded : Icons.circle_outlined,
        size: 16,
        color: selected ? AppColors.onPrimary : AppColors.onSurfaceVariant,
      ),
    );
  }
}

class _PhotoStatusTag extends StatelessWidget {
  const _PhotoStatusTag({
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.borderColor,
  });

  final String label;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
      decoration: BoxDecoration(
        color: backgroundColor.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: borderColor.withValues(alpha: 0.55)),
        boxShadow: [
          BoxShadow(
            color: AppColors.background.withValues(alpha: 0.22),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: foregroundColor,
          fontWeight: FontWeight.w800,
          fontSize: 8,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
