import 'package:flutter/material.dart';

import '../features/collection/data/models/collectible_model.dart';
import '../features/collection/data/repositories/collectibles_repository.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'collector_chip.dart';
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
      final updatedCollectible = widget.collectible.copyWith(isFavorite: nextValue);
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
        const SnackBar(
          content: Text('Could not update favorite right now.'),
        ),
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: _openDetails,
        child: CollectorPanel(
          padding: const EdgeInsets.all(AppSpacing.md),
          backgroundColor: AppColors.surfaceContainer.withValues(alpha: 0.94),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        widget.photoUrl == null
                            ? const Center(
                                child: Icon(
                                  Icons.photo_outlined,
                                  color: AppColors.onSurfaceVariant,
                                  size: 36,
                                ),
                              )
                            : Image.network(
                                widget.photoUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => const Center(
                                  child: Icon(
                                    Icons.broken_image_outlined,
                                    color: AppColors.onSurfaceVariant,
                                    size: 36,
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
                                color: AppColors.outlineVariant.withValues(alpha: 0.2),
                              ),
                            ),
                            child: IconButton(
                              onPressed: _isUpdatingFavorite ? null : _toggleFavorite,
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
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
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
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  if (_isFavorite)
                    const _MiniIndicator(
                      label: 'Favorite',
                      tone: CollectorChipTone.primary,
                    ),
                  if (widget.collectible.isGrail)
                    const _MiniIndicator(
                      label: 'Grail',
                      tone: CollectorChipTone.secondary,
                    ),
                  if (widget.collectible.isDuplicate)
                    const _MiniIndicator(
                      label: 'Duplicate',
                      tone: CollectorChipTone.tertiary,
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

class _MiniIndicator extends StatelessWidget {
  const _MiniIndicator({
    required this.label,
    required this.tone,
  });

  final String label;
  final CollectorChipTone tone;

  @override
  Widget build(BuildContext context) {
    return CollectorChip(
      label: label,
      tone: tone,
    );
  }
}
