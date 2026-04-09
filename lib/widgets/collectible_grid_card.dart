import 'package:flutter/material.dart';

import '../features/collection/data/models/collectible_model.dart';
import '../features/collection/data/repositories/collectibles_repository.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'collector_panel.dart';
import '../screens/collectible_detail_screen.dart';

class CollectibleGridCard extends StatefulWidget {
  const CollectibleGridCard({
    super.key,
    required this.collectible,
    required this.photoUrl,
    required this.onCollectionChanged,
    this.onCollectibleUpdated,
  });

  final CollectibleModel collectible;
  final String? photoUrl;
  final Future<void> Function() onCollectionChanged;
  final ValueChanged<CollectibleModel>? onCollectibleUpdated;

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
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => CollectibleDetailScreen(
          collectible: widget.collectible.copyWith(isFavorite: _isFavorite),
          photoUrl: widget.photoUrl,
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not update favorite right now.')),
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
        borderRadius: BorderRadius.circular(24),
        onTap: _openDetails,
        child: CollectorPanel(
          padding: EdgeInsets.zero,
          backgroundColor: AppColors.surfaceContainer.withValues(alpha: 0.94),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 9,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ColoredBox(
                        color: AppColors.surfaceContainerHighest.withValues(
                          alpha: 0.72,
                        ),
                      ),
                      if (widget.photoUrl == null)
                        const Center(
                          child: Icon(
                            Icons.photo_outlined,
                            color: AppColors.onSurfaceVariant,
                            size: 40,
                          ),
                        )
                      else
                        Image.network(
                          widget.photoUrl!,
                          fit: BoxFit.cover,
                          alignment: Alignment.center,
                          errorBuilder: (_, _, _) => const Center(
                            child: Icon(
                              Icons.broken_image_outlined,
                              color: AppColors.onSurfaceVariant,
                              size: 40,
                            ),
                          ),
                        ),
                      Positioned(
                        top: AppSpacing.sm,
                        right: AppSpacing.sm,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: AppColors.background.withValues(alpha: 0.58),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.outlineVariant.withValues(
                                alpha: 0.2,
                              ),
                            ),
                          ),
                          child: IconButton(
                            onPressed: _isUpdatingFavorite
                                ? null
                                : _toggleFavorite,
                            iconSize: 18,
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.all(8),
                            splashRadius: 20,
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
                      if (photoTags.isNotEmpty)
                        Positioned(
                          left: AppSpacing.sm,
                          bottom: AppSpacing.sm,
                          child: Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: photoTags,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Expanded(
                flex: 11,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    12,
                    AppSpacing.md,
                    10,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.collectible.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        widget.collectible.category,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.onSurfaceVariant,
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: backgroundColor.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(8),
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
          letterSpacing: 0.7,
        ),
      ),
    );
  }
}
