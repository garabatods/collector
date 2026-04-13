import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../features/collection/data/models/add_item_autofill_result.dart';
import '../features/collection/data/models/collectible_identification_result.dart';
import '../features/collection/data/repositories/collectible_identification_repository.dart';
import '../features/collection/data/repositories/collectible_photos_repository.dart';
import '../features/collection/data/services/add_item_autofill_resolver.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/collector_button.dart';
import '../widgets/collector_panel.dart';
import '../widgets/collector_sticky_back_button.dart';
import 'manual_add_collectible_screen.dart';

enum _AiPhotoPhase { idle, identifying, found, notFound, failed }

class AiPhotoIdentificationScreen extends StatefulWidget {
  const AiPhotoIdentificationScreen({
    super.key,
    this.seedBarcode,
    this.initialCategory,
  });

  final String? seedBarcode;
  final String? initialCategory;

  @override
  State<AiPhotoIdentificationScreen> createState() =>
      _AiPhotoIdentificationScreenState();
}

class _AiPhotoIdentificationScreenState
    extends State<AiPhotoIdentificationScreen> {
  final _picker = ImagePicker();
  final _identificationRepository = CollectibleIdentificationRepository();
  final _autofillResolver = AddItemAutofillResolver();

  XFile? _selectedImage;
  Uint8List? _selectedImageBytes;
  CollectibleIdentificationResult? _result;
  String? _message;
  _AiPhotoPhase _phase = _AiPhotoPhase.idle;

  bool get _hasImage => _selectedImage != null && _selectedImageBytes != null;

  Future<void> _pickImage(ImageSource source) async {
    final image = await _picker.pickImage(
      source: source,
      imageQuality: 86,
      maxWidth: 1800,
    );
    if (!mounted || image == null) {
      return;
    }

    final bytes = await image.readAsBytes();
    if (!mounted) {
      return;
    }

    setState(() {
      _selectedImage = image;
      _selectedImageBytes = bytes;
      _result = null;
      _message = null;
      _phase = _AiPhotoPhase.identifying;
    });

    await _identifySelectedImage();
  }

  Future<void> _identifySelectedImage() async {
    final selectedImage = _selectedImage;
    final selectedImageBytes = _selectedImageBytes;
    if (selectedImage == null || selectedImageBytes == null) {
      return;
    }

    try {
      final result = await _identificationRepository.identifyPhoto(
        imageBytes: selectedImageBytes,
        mimeType: CollectiblePhotosRepository.contentTypeForFileName(
          selectedImage.name,
        ),
        barcode: widget.seedBarcode,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _result = result;
        _phase = result.hasCatalogMatch
            ? _AiPhotoPhase.found
            : result.isNotFound
            ? _AiPhotoPhase.notFound
            : _AiPhotoPhase.failed;
        _message = result.hasCatalogMatch
            ? null
            : result.isNotFound
            ? 'We could not confidently identify this piece yet. You can still continue and finish the details yourself.'
            : 'AI identification is unavailable right now. You can still continue manually.';
      });
    } on CollectibleIdentificationException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _result = null;
        _phase = _AiPhotoPhase.failed;
        _message = error.message;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _result = null;
        _phase = _AiPhotoPhase.failed;
        _message = 'AI identification is unavailable right now.';
      });
    }
  }

  Future<void> _continueToManualAdd() async {
    final autofillResult = await _resolveAutofillResult(_result);
    if (!mounted) {
      return;
    }
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => ManualAddCollectibleScreen(
          scannedBarcode: widget.seedBarcode ?? _result?.barcode,
          identificationResult: _result,
          autofillResult: autofillResult,
          initialImage: (_result?.imageUrl ?? '').isNotEmpty
              ? null
              : _selectedImage,
          initialCategory: widget.initialCategory,
        ),
      ),
    );

    if (!mounted) {
      return;
    }

    if (created == true) {
      Navigator.of(context).pop(true);
    }
  }

  Future<AddItemAutofillResult?> _resolveAutofillResult(
    CollectibleIdentificationResult? identificationResult,
  ) async {
    if (identificationResult == null || !identificationResult.hasPrefillData) {
      return null;
    }

    try {
      return await _autofillResolver.resolve(
        identificationResult,
        preferredCategory: widget.initialCategory,
      );
    } catch (_) {
      return null;
    }
  }

  void _clearSelection() {
    setState(() {
      _selectedImage = null;
      _selectedImageBytes = null;
      _result = null;
      _message = null;
      _phase = _AiPhotoPhase.idle;
    });
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    final phase = _phase;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topCenter,
                  radius: 1.25,
                  colors: [AppColors.aiPhotoGlow, AppColors.background],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.primary.withValues(alpha: 0.08),
                    Colors.transparent,
                    AppColors.tertiary.withValues(alpha: 0.04),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.xs,
                AppSpacing.md,
                AppSpacing.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 48),
                  if ((widget.seedBarcode ?? '').isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.md),
                    _SeedBarcodeBanner(barcode: widget.seedBarcode!),
                  ],
                  const SizedBox(height: AppSpacing.md),
                  Expanded(
                    child: CollectorPanel(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      backgroundColor: AppColors.surfaceContainer.withValues(
                        alpha: 0.92,
                      ),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _PremiumImageStage(selectedImage: _selectedImage),
                            const SizedBox(height: AppSpacing.lg),
                            Wrap(
                              spacing: AppSpacing.md,
                              runSpacing: AppSpacing.md,
                              children: [
                                _SourceActionButton(
                                  icon: Icons.camera_alt_outlined,
                                  label: 'Take photo',
                                  onTap: () => _pickImage(ImageSource.camera),
                                ),
                                _SourceActionButton(
                                  icon: Icons.photo_library_outlined,
                                  label: 'Choose photo',
                                  onTap: () => _pickImage(ImageSource.gallery),
                                ),
                                if (_hasImage)
                                  _SourceActionButton(
                                    icon: Icons.refresh_rounded,
                                    label: 'Try another',
                                    onTap: _clearSelection,
                                  ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            Text(
                              phase == _AiPhotoPhase.identifying
                                  ? 'AI is examining the collectible'
                                  : result?.hasCatalogMatch == true
                                  ? 'AI identification result'
                                  : _hasImage
                                  ? 'AI could not confirm the item'
                                  : 'Start with a photo',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              phase == _AiPhotoPhase.identifying
                                  ? 'We are identifying the piece and enriching it when it looks comic-related.'
                                  : result?.hasCatalogMatch == true
                                  ? 'Review the strongest match, then continue to confirm or refine the details.'
                                  : _hasImage
                                  ? (_message ??
                                        'You can still continue manually with the selected photo.')
                                  : 'Capture the full front of the item or cover art for the strongest result.',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: AppColors.onSurfaceVariant),
                            ),
                            if (phase == _AiPhotoPhase.identifying) ...[
                              const SizedBox(height: AppSpacing.md),
                              const _AiLoadingCard(),
                            ] else if (result?.hasCatalogMatch == true) ...[
                              const SizedBox(height: AppSpacing.md),
                              _AiResultCard(result: result!),
                            ] else if (_hasImage && _message != null) ...[
                              const SizedBox(height: AppSpacing.md),
                              _AiNoticeCard(
                                title: phase == _AiPhotoPhase.failed
                                    ? 'AI identification unavailable'
                                    : 'No confident AI match yet',
                                description: _message!,
                                icon: phase == _AiPhotoPhase.failed
                                    ? Icons.cloud_off_rounded
                                    : Icons.auto_awesome_outlined,
                              ),
                            ],
                            const SizedBox(height: AppSpacing.xl),
                            if (result?.hasCatalogMatch == true) ...[
                              SizedBox(
                                width: double.infinity,
                                child: CollectorButton(
                                  label: 'Add details',
                                  onPressed: _continueToManualAdd,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              SizedBox(
                                width: double.infinity,
                                child: CollectorButton(
                                  label: 'Try another photo',
                                  onPressed: _clearSelection,
                                  variant: CollectorButtonVariant.secondary,
                                ),
                              ),
                            ] else ...[
                              SizedBox(
                                width: double.infinity,
                                child: CollectorButton(
                                  label: 'Add details manually',
                                  onPressed: _hasImage
                                      ? _continueToManualAdd
                                      : null,
                                  variant: _hasImage
                                      ? CollectorButtonVariant.primary
                                      : CollectorButtonVariant.secondary,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              SizedBox(
                                width: double.infinity,
                                child: CollectorButton(
                                  label: _hasImage
                                      ? 'Try another photo'
                                      : 'Maybe later',
                                  onPressed: _hasImage
                                      ? _clearSelection
                                      : () => Navigator.of(context).pop(),
                                  variant: CollectorButtonVariant.secondary,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          CollectorStickyBackButton(
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}

class _SeedBarcodeBanner extends StatelessWidget {
  const _SeedBarcodeBanner({required this.barcode});

  final String barcode;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.24)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.qr_code_2_rounded,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SCANNED BARCODE',
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(color: AppColors.primary),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(barcode, style: Theme.of(context).textTheme.titleSmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PremiumImageStage extends StatelessWidget {
  const _PremiumImageStage({required this.selectedImage});

  final XFile? selectedImage;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: 0.18),
            AppColors.surfaceContainerHighest.withValues(alpha: 0.82),
            AppColors.tertiary.withValues(alpha: 0.14),
          ],
        ),
      ),
      padding: const EdgeInsets.all(1.2),
      child: Container(
        height: 300,
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerHighest.withValues(alpha: 0.78),
          borderRadius: BorderRadius.circular(29),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (selectedImage != null)
              Image.file(File(selectedImage!.path), fit: BoxFit.cover)
            else
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF232847), Color(0xFF161A21)],
                  ),
                ),
              ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.08),
                    Colors.black.withValues(alpha: 0.44),
                  ],
                ),
              ),
            ),
            if (selectedImage == null)
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 74,
                      height: 74,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.14),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.auto_awesome_rounded,
                        color: AppColors.primary,
                        size: 34,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Premium AI Photo ID',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Cover art, loose figures, boxed sets, and rare pieces all work well here. Use a full-frame photo for the strongest result.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SourceActionButton extends StatelessWidget {
  const _SourceActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.onSurface,
        side: BorderSide(
          color: AppColors.outlineVariant.withValues(alpha: 0.34),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      icon: Icon(icon),
      label: Text(label),
    );
  }
}

class _AiLoadingCard extends StatelessWidget {
  const _AiLoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHighest.withValues(alpha: 0.46),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Padding(
              padding: EdgeInsets.all(12),
              child: CircularProgressIndicator(strokeWidth: 2.4),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              'Running visual identification, then enriching comic-like matches automatically.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AiResultCard extends StatelessWidget {
  const _AiResultCard({required this.result});

  final CollectibleIdentificationResult result;

  @override
  Widget build(BuildContext context) {
    final confidence = result.confidence;
    final imageUrl = (result.imageUrl ?? '').trim();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHighest.withValues(alpha: 0.44),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  result.sourceBadge.toUpperCase(),
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(color: AppColors.primary),
                ),
              ),
              if (confidence != null) ...[
                const SizedBox(width: AppSpacing.sm),
                Text(
                  '${(confidence * 100).round()}% confidence',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
          if (imageUrl.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              height: 190,
              width: double.infinity,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: AppColors.surfaceContainerHigh,
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const SizedBox.shrink(),
                  ),
                  Align(
                    alignment: Alignment.bottomLeft,
                    child: Container(
                      margin: const EdgeInsets.all(AppSpacing.md),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.48),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'Suggested photo',
                        style: Theme.of(
                          context,
                        ).textTheme.labelLarge?.copyWith(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Text(result.title, style: Theme.of(context).textTheme.headlineSmall),
          if ((result.suggestedCategory ?? '').isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              result.suggestedCategory!,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
          if ((result.description ?? '').isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              result.description!,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              if ((result.brand ?? '').isNotEmpty)
                _MetaTag(label: result.brand!),
              if ((result.franchise ?? '').isNotEmpty)
                _MetaTag(label: result.franchise!),
              if ((result.series ?? '').isNotEmpty)
                _MetaTag(label: result.series!),
              if ((result.characterOrSubject ?? '').isNotEmpty)
                _MetaTag(label: result.characterOrSubject!),
              if (result.releaseYear != null)
                _MetaTag(label: '${result.releaseYear}'),
              if ((result.comicContext?.issueNumber ?? '').isNotEmpty)
                _MetaTag(label: '#${result.comicContext!.issueNumber!}'),
              if ((result.comicContext?.publisher ?? '').isNotEmpty)
                _MetaTag(label: result.comicContext!.publisher!),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetaTag extends StatelessWidget {
  const _MetaTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.22),
        ),
      ),
      child: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.labelLarge?.copyWith(color: AppColors.onSurface),
      ),
    );
  }
}

class _AiNoticeCard extends StatelessWidget {
  const _AiNoticeCard({
    required this.title,
    required this.description,
    required this.icon,
  });

  final String title;
  final String description;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHighest.withValues(alpha: 0.44),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AppColors.primary),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
