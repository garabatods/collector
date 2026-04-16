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
    final expectsImage = photoRef?.hasPhotoRecord ?? false;
    if (localPath != null && localPath.isNotEmpty) {
      return Image.file(
        File(localPath),
        fit: fit,
        alignment: alignment,
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (wasSynchronouslyLoaded || frame != null) {
            return child;
          }
          return placeholder;
        },
        errorBuilder: (_, _, _) => _remoteOrFallback(
          remoteUrl,
          expectsImage: expectsImage,
        ),
      );
    }

    return _remoteOrFallback(remoteUrl, expectsImage: expectsImage);
  }

  Widget _remoteOrFallback(String? remoteUrl, {required bool expectsImage}) {
    if (remoteUrl == null || remoteUrl.isEmpty) {
      return expectsImage ? placeholder : (error ?? placeholder);
    }

    return Image.network(
      remoteUrl,
      fit: fit,
      alignment: alignment,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded || frame != null) {
          return child;
        }
        return placeholder;
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          return child;
        }
        return placeholder;
      },
      errorBuilder: (_, _, _) => expectsImage ? placeholder : (error ?? placeholder),
    );
  }
}
