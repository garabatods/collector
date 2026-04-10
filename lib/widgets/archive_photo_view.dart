import 'dart:io';

import 'package:flutter/material.dart';

import '../core/data/archive_types.dart';

class ArchivePhotoView extends StatelessWidget {
  const ArchivePhotoView({
    super.key,
    required this.photoRef,
    required this.fit,
    required this.placeholder,
    this.alignment = Alignment.center,
    this.error,
  });

  final ArchivePhotoRef? photoRef;
  final BoxFit fit;
  final Alignment alignment;
  final Widget placeholder;
  final Widget? error;

  @override
  Widget build(BuildContext context) {
    final localPath = photoRef?.localPath?.trim();
    final remoteUrl = photoRef?.remoteUrl?.trim();
    if (localPath != null && localPath.isNotEmpty) {
      return Image.file(
        File(localPath),
        fit: fit,
        alignment: alignment,
        errorBuilder: (_, _, _) => _remoteOrFallback(remoteUrl),
      );
    }

    return _remoteOrFallback(remoteUrl);
  }

  Widget _remoteOrFallback(String? remoteUrl) {
    if (remoteUrl == null || remoteUrl.isEmpty) {
      return error ?? placeholder;
    }

    return Image.network(
      remoteUrl,
      fit: fit,
      alignment: alignment,
      errorBuilder: (_, _, _) => error ?? placeholder,
    );
  }
}
