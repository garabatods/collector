import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class CategoryIcon extends StatelessWidget {
  const CategoryIcon({
    super.key,
    required this.category,
    this.size = 24,
    this.fallbackColor = AppColors.onSurfaceVariant,
  });

  final String? category;
  final double size;
  final Color fallbackColor;

  static const _assetRoot = 'assets/icons/categories_v2';

  static String assetFor(String? category) {
    final normalized = _normalize(category);
    if (normalized.isEmpty) {
      return '$_assetRoot/other2.png';
    }

    if (normalized == 'library' ||
        normalized == 'allitems' ||
        normalized == 'collection') {
      return '$_assetRoot/library.png';
    }
    if (normalized == 'actionfigures' || normalized.contains('actionfigure')) {
      return '$_assetRoot/action_figures.png';
    }
    if (normalized == 'boardgames' || normalized.contains('boardgame')) {
      return '$_assetRoot/board_games.png';
    }
    if (normalized == 'comics' ||
        normalized == 'comicbooks' ||
        normalized.contains('comic')) {
      return '$_assetRoot/comics.png';
    }
    if (normalized == 'tradingcards' ||
        normalized.contains('tradingcard') ||
        normalized.contains('card')) {
      return '$_assetRoot/trading_cards.png';
    }
    if (normalized == 'diecast' ||
        normalized.contains('cartoy') ||
        normalized.contains('car') ||
        normalized.contains('vehicle')) {
      return '$_assetRoot/cartoys.png';
    }
    if (normalized == 'vinylfigures' ||
        normalized.contains('funko') ||
        normalized.contains('popfigure')) {
      return '$_assetRoot/funko.png';
    }
    if (normalized.contains('lego') || normalized.contains('buildingblock')) {
      return '$_assetRoot/lego.png';
    }
    if (normalized.contains('model')) {
      return '$_assetRoot/modeling.png';
    }
    if (normalized.contains('book') || normalized.contains('manga')) {
      return '$_assetRoot/books.png';
    }
    if (normalized.contains('videogame') ||
        normalized == 'games' ||
        normalized.contains('game')) {
      return '$_assetRoot/videogames.png';
    }
    if (normalized.contains('video') ||
        normalized.contains('movie') ||
        normalized.contains('bluray') ||
        normalized.contains('dvd') ||
        normalized.contains('media')) {
      return '$_assetRoot/video_media.png';
    }
    if (normalized == 'cdaudio' ||
        normalized == 'cds' ||
        normalized.contains('compactdisc') ||
        normalized.contains('audio') ||
        normalized.contains('soundtrack')) {
      return '$_assetRoot/cd_audio.png';
    }
    if (normalized.contains('vinyl') ||
        normalized.contains('record') ||
        normalized.contains('music')) {
      return '$_assetRoot/vinyl_disc.png';
    }
    if (normalized.contains('pin')) {
      return '$_assetRoot/pins.png';
    }
    if (normalized == 'statues' ||
        normalized == 'statue' ||
        normalized.contains('memorabilia')) {
      return '$_assetRoot/other.png';
    }
    if (normalized == 'other') {
      return '$_assetRoot/other.png';
    }

    return '$_assetRoot/other2.png';
  }

  static String _normalize(String? value) {
    return (value ?? '').toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      assetFor(category),
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      errorBuilder: (context, error, stackTrace) =>
          Icon(Icons.category_outlined, color: fallbackColor, size: size),
    );
  }
}
