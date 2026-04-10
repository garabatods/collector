import 'package:flutter/material.dart';

import '../features/profile/data/repositories/profile_avatar_repository.dart';

class _CachedResolvedAvatarUrl {
  const _CachedResolvedAvatarUrl({
    required this.url,
    required this.resolvedAt,
  });

  final String? url;
  final DateTime resolvedAt;
}

class ResolvedAvatarImage extends StatefulWidget {
  const ResolvedAvatarImage({
    super.key,
    required this.avatarSource,
    required this.fallback,
    this.fit = BoxFit.cover,
    this.error,
  });

  final String? avatarSource;
  final Widget fallback;
  final BoxFit fit;
  final Widget? error;

  @override
  State<ResolvedAvatarImage> createState() => _ResolvedAvatarImageState();
}

class _ResolvedAvatarImageState extends State<ResolvedAvatarImage> {
  static const _cacheMaxAge = Duration(minutes: 50);
  static final Map<String, _CachedResolvedAvatarUrl> _resolvedUrlCache =
      <String, _CachedResolvedAvatarUrl>{};

  final _profileAvatarRepository = ProfileAvatarRepository();

  late Future<String?> _future;

  @override
  void initState() {
    super.initState();
    _future = _resolveAvatar();
  }

  @override
  void didUpdateWidget(covariant ResolvedAvatarImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.avatarSource != widget.avatarSource) {
      _future = _resolveAvatar();
    }
  }

  Future<String?> _resolveAvatar() {
    final source = widget.avatarSource?.trim();
    if (source == null || source.isEmpty) {
      return Future.value(null);
    }

    final cached = _resolvedUrlCache[source];
    if (cached != null &&
        DateTime.now().difference(cached.resolvedAt) < _cacheMaxAge) {
      return Future.value(cached.url);
    }

    return _profileAvatarRepository.resolveAvatarUrl(source).then((resolvedUrl) {
      _resolvedUrlCache[source] = _CachedResolvedAvatarUrl(
        url: resolvedUrl,
        resolvedAt: DateTime.now(),
      );
      return resolvedUrl;
    });
  }

  String? _cachedAvatarUrl() {
    final source = widget.avatarSource?.trim();
    if (source == null || source.isEmpty) {
      return null;
    }

    final cached = _resolvedUrlCache[source];
    if (cached == null) {
      return null;
    }

    if (DateTime.now().difference(cached.resolvedAt) >= _cacheMaxAge) {
      _resolvedUrlCache.remove(source);
      return null;
    }

    return cached.url;
  }

  @override
  Widget build(BuildContext context) {
    final fallback = widget.fallback;
    final cachedUrl = _cachedAvatarUrl();

    return FutureBuilder<String?>(
      future: _future,
      initialData: cachedUrl,
      builder: (context, snapshot) {
        final resolvedUrl = snapshot.data?.trim();
        if (resolvedUrl == null || resolvedUrl.isEmpty) {
          return fallback;
        }

        return Image.network(
          resolvedUrl,
          fit: widget.fit,
          errorBuilder: (_, _, _) => widget.error ?? fallback,
        );
      },
    );
  }
}
