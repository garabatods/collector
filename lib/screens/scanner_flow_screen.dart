import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../core/collector_haptics.dart';
import '../core/collector_sound_effects.dart';
import '../features/collection/data/models/add_item_autofill_result.dart';
import '../features/collection/data/models/collectible_model.dart';
import '../features/collection/data/models/collectible_identification_result.dart';
import '../features/collection/data/repositories/collectible_identification_repository.dart';
import '../features/collection/data/repositories/collectible_photos_repository.dart';
import '../features/collection/data/repositories/collectibles_repository.dart';
import '../features/collection/data/services/add_item_autofill_resolver.dart';
import '../features/collection/data/repositories/collection_vocabulary_repository.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/category_icon.dart';
import '../widgets/collector_button.dart';
import '../widgets/collector_panel.dart';
import '../widgets/collector_snack_bar.dart';
import '../widgets/collector_sticky_back_button.dart';
import 'ai_photo_identification_screen.dart';
import 'manual_add_collectible_screen.dart';

enum _LookupPhase { idle, loading, found, notFound, failed }

class ScannerFlowScreen extends StatefulWidget {
  const ScannerFlowScreen({super.key, this.initialCategory});

  final String? initialCategory;

  @override
  State<ScannerFlowScreen> createState() => _ScannerFlowScreenState();
}

class _ScannerFlowScreenState extends State<ScannerFlowScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    formats: const [
      BarcodeFormat.ean8,
      BarcodeFormat.ean13,
      BarcodeFormat.upcA,
      BarcodeFormat.upcE,
      BarcodeFormat.code128,
      BarcodeFormat.code39,
      BarcodeFormat.code93,
      BarcodeFormat.itf14,
    ],
  );
  final CollectibleIdentificationRepository _identificationRepository =
      CollectibleIdentificationRepository();
  final AddItemAutofillResolver _autofillResolver = AddItemAutofillResolver();
  final CollectiblesRepository _collectiblesRepository =
      CollectiblesRepository();
  final CollectiblePhotosRepository _photosRepository =
      CollectiblePhotosRepository();

  String? _detectedBarcode;
  CollectibleIdentificationResult? _lookupResult;
  String? _lookupMessage;
  _LookupPhase _lookupPhase = _LookupPhase.idle;
  bool _isHandlingDetection = false;
  bool _isScannerPaused = false;
  bool _isQuickScanEnabled = false;
  bool _createdItemInSession = false;

  @override
  void initState() {
    super.initState();
    CollectorSoundEffects.warmUpScan();
  }

  @override
  void dispose() {
    unawaited(CollectorSoundEffects.disposeScan());
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleDetect(BarcodeCapture capture) async {
    if (_isHandlingDetection) {
      return;
    }

    final barcode = capture.barcodes
        .map((item) => item.rawValue?.trim())
        .whereType<String>()
        .firstWhere((value) => value.isNotEmpty, orElse: () => '');

    if (barcode.isEmpty) {
      return;
    }

    _isHandlingDetection = true;
    CollectorSoundEffects.playScan();

    try {
      if (_isQuickScanEnabled) {
        await _handleQuickScanDetection(barcode);
        return;
      }

      await _controller.stop();
      _isScannerPaused = true;

      if (!mounted) {
        return;
      }

      setState(() {
        _detectedBarcode = barcode;
        _lookupResult = null;
        _lookupMessage = null;
        _lookupPhase = _LookupPhase.loading;
      });

      await _lookupBarcode(barcode);
    } finally {
      _isHandlingDetection = false;
    }
  }

  Future<void> _handleQuickScanDetection(String barcode) async {
    try {
      final lookupResult = await _identificationRepository.identifyBarcode(
        barcode,
      );
      if (!mounted) {
        return;
      }

      if (_isEligibleForQuickAdd(lookupResult)) {
        final autofillResult = await _resolveAutofillResult(lookupResult);
        if (!mounted) {
          return;
        }

        final added = await _quickAddMatchedItem(
          barcode: barcode,
          lookupResult: lookupResult,
          autofillResult: autofillResult,
        );
        if (!mounted || added) {
          return;
        }
      }

      await _controller.stop();
      _isScannerPaused = true;

      if (!mounted) {
        return;
      }

      setState(() {
        _detectedBarcode = barcode;
        _lookupResult = lookupResult;
        _lookupPhase = lookupResult.hasCatalogMatch
            ? _LookupPhase.found
            : lookupResult.isNotFound
            ? _LookupPhase.notFound
            : _LookupPhase.failed;
        _lookupMessage = lookupResult.hasCatalogMatch
            ? null
            : lookupResult.isNotFound
            ? 'No barcode match yet. AI Photo ID works better for loose toys, comics, worn packages, and barcode-less pieces.'
            : 'Barcode lookup is unavailable right now. You can still continue manually or use AI Photo ID.';
      });

      if (lookupResult.hasCatalogMatch) {
        CollectorHaptics.medium();
      }
    } on CollectibleIdentificationException catch (error) {
      await _controller.stop();
      _isScannerPaused = true;
      if (!mounted) {
        return;
      }

      setState(() {
        _detectedBarcode = barcode;
        _lookupResult = null;
        _lookupPhase = _LookupPhase.failed;
        _lookupMessage = error.message;
      });
    } catch (_) {
      await _controller.stop();
      _isScannerPaused = true;
      if (!mounted) {
        return;
      }

      setState(() {
        _detectedBarcode = barcode;
        _lookupResult = null;
        _lookupPhase = _LookupPhase.failed;
        _lookupMessage =
            'Lookup is unavailable right now. You can still continue with a manual add.';
      });
    }
  }

  Future<void> _lookupBarcode(String barcode) async {
    try {
      final lookupResult = await _identificationRepository.identifyBarcode(
        barcode,
      );
      if (!mounted || _detectedBarcode != barcode) {
        return;
      }

      setState(() {
        _lookupResult = lookupResult;
        _lookupPhase = lookupResult.hasCatalogMatch
            ? _LookupPhase.found
            : lookupResult.isNotFound
            ? _LookupPhase.notFound
            : _LookupPhase.failed;
        _lookupMessage = lookupResult.hasCatalogMatch
            ? null
            : lookupResult.isNotFound
            ? 'No barcode match yet. AI Photo ID works better for loose toys, comics, worn packages, and barcode-less pieces.'
            : 'Barcode lookup is unavailable right now. You can still continue manually or use AI Photo ID.';
      });
      if (lookupResult.hasCatalogMatch) {
        CollectorHaptics.medium();
      }
    } on CollectibleIdentificationException catch (error) {
      if (mounted && _detectedBarcode == barcode) {
        setState(() {
          _lookupResult = null;
          _lookupPhase = _LookupPhase.failed;
          _lookupMessage = error.message;
        });
      }
    } catch (_) {
      if (!mounted || _detectedBarcode != barcode) {
        return;
      }

      setState(() {
        _lookupResult = null;
        _lookupPhase = _LookupPhase.failed;
        _lookupMessage =
            'Lookup is unavailable right now. You can still continue with a manual add.';
      });
    }
  }

  void _closeScanner() {
    Navigator.of(context).pop(_createdItemInSession ? true : null);
  }

  Future<void> _resumeScanning() async {
    setState(() {
      _detectedBarcode = null;
      _lookupResult = null;
      _lookupMessage = null;
      _lookupPhase = _LookupPhase.idle;
    });

    if (_isScannerPaused) {
      await _controller.start();
      _isScannerPaused = false;
    }
  }

  Future<void> _continueToManualAdd() async {
    final barcode = _detectedBarcode;
    if (barcode == null || barcode.isEmpty) {
      return;
    }

    final autofillResult = await _resolveAutofillResult(_lookupResult);
    if (!mounted) {
      return;
    }
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => ManualAddCollectibleScreen(
          scannedBarcode: barcode,
          identificationResult: _lookupResult,
          autofillResult: autofillResult,
          initialCategory: widget.initialCategory,
        ),
      ),
    );

    if (!mounted) {
      return;
    }

    if (created == true) {
      Navigator.of(context).pop(true);
      return;
    }

    await _resumeScanning();
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

  bool _isEligibleForQuickAdd(CollectibleIdentificationResult lookupResult) {
    return _isQuickScanEnabled &&
        lookupResult.source == CollectibleIdentificationSource.barcode &&
        lookupResult.status != CollectibleIdentificationStatus.partial &&
        lookupResult.hasCatalogMatch;
  }

  String _resolvedQuickAddCategory(
    CollectibleIdentificationResult lookupResult,
  ) {
    final initialCategory = widget.initialCategory?.trim() ?? '';
    if (initialCategory.isNotEmpty) {
      return initialCategory;
    }

    final suggestedCategory = (lookupResult.suggestedCategory ?? '').trim();
    if (suggestedCategory.isNotEmpty) {
      return suggestedCategory;
    }

    if (lookupResult.isComicLike) {
      return 'Comics';
    }

    return '';
  }

  bool _canQuickAddMatch({
    required CollectibleIdentificationResult lookupResult,
    required AddItemAutofillResult? autofillResult,
  }) {
    final title = (autofillResult?.title ?? lookupResult.title).trim();
    final category = _resolvedQuickAddCategory(lookupResult);

    return title.isNotEmpty && category.isNotEmpty;
  }

  String? _normalizedOptionalText(String? value) {
    final trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? null : trimmed;
  }

  Future<bool> _quickAddMatchedItem({
    required String barcode,
    required CollectibleIdentificationResult lookupResult,
    required AddItemAutofillResult? autofillResult,
  }) async {
    if (!_canQuickAddMatch(
      lookupResult: lookupResult,
      autofillResult: autofillResult,
    )) {
      return false;
    }

    final messenger = ScaffoldMessenger.of(context);
    final category = _resolvedQuickAddCategory(lookupResult);
    final title = (autofillResult?.title ?? lookupResult.title).trim();
    final isComic = category.trim().toLowerCase() == 'comics';
    final brand = _normalizedOptionalText(
      autofillResult?.brandOrPublisher?.resolvedValue ??
          (isComic ? lookupResult.publisherCandidate : lookupResult.brand),
    );
    final series = _normalizedOptionalText(
      autofillResult?.seriesOrVolume ??
          (isComic ? lookupResult.volumeCandidate : lookupResult.series),
    );
    final itemNumber = _normalizedOptionalText(
      autofillResult?.issueNumber ?? lookupResult.issueNumber,
    );

    try {
      final created = await _collectiblesRepository.create(
        CollectibleModel(
          barcode: barcode.trim(),
          title: title,
          category: category,
          description: _normalizedOptionalText(
            autofillResult?.description ?? lookupResult.description,
          ),
          brand: brand,
          series: series,
          franchise: _normalizedOptionalText(
            autofillResult?.franchise ?? lookupResult.franchise,
          ),
          lineOrSeries: series,
          characterOrSubject: _normalizedOptionalText(
            autofillResult?.characterOrSubject ??
                lookupResult.characterOrSubject,
          ),
          releaseYear: autofillResult?.releaseYear ?? lookupResult.releaseYear,
          itemNumber: itemNumber,
        ),
        tagIds: autofillResult?.matchedTagIds,
        newTagNames: autofillResult?.newTagNames,
      );

      var photoUploadFailed = false;
      final collectibleId = created.id;
      final imageUrl = _normalizedOptionalText(lookupResult.imageUrl);
      if (collectibleId != null && imageUrl != null) {
        try {
          await _photosRepository.uploadPrimaryPhotoFromRemoteImage(
            collectibleId: collectibleId,
            imageUrl: imageUrl,
            fallbackFileName: title.toLowerCase().replaceAll(' ', '-'),
            caption: title,
          );
        } catch (_) {
          photoUploadFailed = true;
        }
      }

      if (!mounted) {
        return true;
      }

      CollectionVocabularyRepository.invalidateCache();
      _createdItemInSession = true;
      CollectorHaptics.medium();
      await _resumeScanning();

      if (!mounted) {
        return true;
      }

      CollectorSnackBar.showOn(
        messenger,
        message: photoUploadFailed
            ? '$title added, but the photo could not be saved.'
            : '$title added. Keep scanning.',
        tone: photoUploadFailed
            ? CollectorSnackBarTone.warning
            : CollectorSnackBarTone.success,
      );
      return true;
    } catch (_) {
      if (!mounted) {
        return false;
      }

      CollectorSnackBar.show(
        context,
        message: 'Quick add could not finish. Review the match below instead.',
        tone: CollectorSnackBarTone.error,
      );
      return false;
    }
  }

  Future<void> _openAiPhotoId() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => AiPhotoIdentificationScreen(
          seedBarcode: _detectedBarcode,
          initialCategory: widget.initialCategory,
        ),
      ),
    );

    if (!mounted) {
      return;
    }

    if (created == true) {
      _createdItemInSession = true;
      Navigator.of(context).pop(true);
      return;
    }

    await _resumeScanning();
  }

  Future<void> _openManualWithoutScan() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) =>
            ManualAddCollectibleScreen(initialCategory: widget.initialCategory),
      ),
    );

    if (!mounted) {
      return;
    }

    if (created == true) {
      _createdItemInSession = true;
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _toggleQuickScan() async {
    CollectorHaptics.selection();
    setState(() {
      _isQuickScanEnabled = !_isQuickScanEnabled;
    });
  }

  Widget _buildQuickScanToggle(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isEnabled = _isQuickScanEnabled;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isEnabled
              ? [
                  AppColors.primary.withValues(alpha: 0.18),
                  AppColors.surfaceContainerHighest.withValues(alpha: 0.82),
                ]
              : [
                  AppColors.surfaceContainerHighest.withValues(alpha: 0.42),
                  AppColors.surfaceContainerHighest.withValues(alpha: 0.26),
                ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isEnabled
              ? AppColors.primary.withValues(alpha: 0.32)
              : AppColors.outlineVariant.withValues(alpha: 0.18),
        ),
        boxShadow: isEnabled
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.14),
                  blurRadius: 20,
                  spreadRadius: 0.5,
                ),
              ]
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      alignment: Alignment.center,
                      child: Image.asset(
                        'assets/icons/quickScan.png',
                        width: 34,
                        height: 34,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Quick Scan',
                        style: textTheme.titleMedium?.copyWith(
                          color: AppColors.onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Switch.adaptive(
                      value: isEnabled,
                      onChanged: (_) => _toggleQuickScan(),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Auto-add strong barcode matches and keep scanning without opening the review screen.',
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScannerCategoryContext(BuildContext context) {
    final category = widget.initialCategory?.trim();
    if (category == null || category.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          CategoryIcon(category: category, size: 28),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Adding to $category',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(color: AppColors.onSurface),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScannerContent({
    required BuildContext context,
    required bool compactPanel,
    required String? detectedBarcode,
    required CollectibleIdentificationResult? lookupResult,
    required String? lookupMessage,
  }) {
    return _buildSingleScanContent(
      context: context,
      compactPanel: compactPanel,
      detectedBarcode: detectedBarcode,
      lookupResult: lookupResult,
      lookupMessage: lookupMessage,
    );
  }

  Widget _buildSingleScanContent({
    required BuildContext context,
    required bool compactPanel,
    required String? detectedBarcode,
    required CollectibleIdentificationResult? lookupResult,
    required String? lookupMessage,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (detectedBarcode == null)
          Text(
            'Scanning for UPC / EAN',
            style: Theme.of(context).textTheme.titleMedium,
          )
        else
          Text(
            _lookupPhase == _LookupPhase.loading
                ? 'Looking up the barcode'
                : lookupResult?.hasCatalogMatch == true
                ? 'Catalog match found'
                : 'Barcode detected',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        const SizedBox(height: AppSpacing.sm),
        if (detectedBarcode == null)
          Text(
            'The first valid barcode will pause the scanner so you can decide what to do next.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.onSurfaceVariant),
          )
        else ...[
          _DetectedBarcodeCard(barcode: detectedBarcode),
          if (_lookupPhase == _LookupPhase.loading) ...[
            const SizedBox(height: AppSpacing.md),
            const _LookupLoadingCard(),
          ] else if (lookupResult?.hasCatalogMatch == true) ...[
            const SizedBox(height: AppSpacing.md),
            _LookupPreviewCard(result: lookupResult),
            const SizedBox(height: AppSpacing.sm),
            Text(
              _isQuickScanEnabled
                  ? 'Quick scan paused here because this match still needs a review before saving.'
                  : 'Review the match, then continue to confirm or refine the details.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ] else if (lookupMessage != null) ...[
            const SizedBox(height: AppSpacing.md),
            _LookupNoticeCard(
              title: _lookupPhase == _LookupPhase.notFound
                  ? 'Barcode match missed'
                  : 'Lookup unavailable',
              description: lookupMessage,
              icon: _lookupPhase == _LookupPhase.notFound
                  ? Icons.auto_awesome_rounded
                  : Icons.cloud_off_rounded,
            ),
          ],
        ],
        SizedBox(height: compactPanel ? AppSpacing.lg : AppSpacing.xl),
        if (detectedBarcode == null)
          SizedBox(
            width: double.infinity,
            child: CollectorButton(
              label: 'Scan manually later',
              onPressed: _openManualWithoutScan,
              variant: CollectorButtonVariant.secondary,
            ),
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (lookupResult?.hasCatalogMatch == true) ...[
                CollectorButton(
                  label: 'Review details',
                  onPressed: _continueToManualAdd,
                ),
                const SizedBox(height: AppSpacing.md),
                CollectorButton(
                  label: 'Scan again',
                  onPressed: _resumeScanning,
                  variant: CollectorButtonVariant.secondary,
                ),
              ] else ...[
                CollectorButton(
                  label: 'Try AI Photo ID',
                  onPressed: _openAiPhotoId,
                ),
                const SizedBox(height: AppSpacing.md),
                CollectorButton(
                  label: 'Add details manually',
                  onPressed: _continueToManualAdd,
                  variant: CollectorButtonVariant.secondary,
                ),
                const SizedBox(height: AppSpacing.sm),
                CollectorButton(
                  label: 'Scan again',
                  onPressed: _resumeScanning,
                  variant: CollectorButtonVariant.tertiary,
                ),
              ],
            ],
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final detectedBarcode = _detectedBarcode;
    final lookupResult = _lookupResult;
    final lookupMessage = _lookupMessage;
    final showScannerPreview = detectedBarcode == null && !_isScannerPaused;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topCenter,
                  radius: 1.2,
                  colors: [AppColors.featureGlow, AppColors.background],
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
                  const SizedBox(height: AppSpacing.sm),
                  Expanded(
                    child: CollectorPanel(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      backgroundColor: AppColors.surfaceContainer.withValues(
                        alpha: 0.92,
                      ),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final compactPanel = constraints.maxHeight < 540;
                          final previewHeight = compactPanel ? 248.0 : 320.0;

                          return SingleChildScrollView(
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minHeight: constraints.maxHeight,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 220),
                                    switchInCurve: Curves.easeOutCubic,
                                    switchOutCurve: Curves.easeInCubic,
                                    child: showScannerPreview
                                        ? Padding(
                                            key: const ValueKey(
                                              'scanner-preview',
                                            ),
                                            padding: const EdgeInsets.only(
                                              bottom: AppSpacing.lg,
                                            ),
                                            child: _ScannerPreviewCard(
                                              controller: _controller,
                                              onDetect: _handleDetect,
                                              height: previewHeight,
                                            ),
                                          )
                                        : Padding(
                                            key: const ValueKey(
                                              'scanner-paused',
                                            ),
                                            padding: const EdgeInsets.only(
                                              bottom: AppSpacing.lg,
                                            ),
                                            child: _ScannerPausedBanner(
                                              isLoading:
                                                  _lookupPhase ==
                                                  _LookupPhase.loading,
                                            ),
                                          ),
                                  ),
                                  _buildQuickScanToggle(context),
                                  const SizedBox(height: AppSpacing.lg),
                                  _buildScannerCategoryContext(context),
                                  if ((widget.initialCategory ?? '')
                                      .trim()
                                      .isNotEmpty)
                                    const SizedBox(height: AppSpacing.lg),
                                  _buildScannerContent(
                                    context: context,
                                    compactPanel: compactPanel,
                                    detectedBarcode: detectedBarcode,
                                    lookupResult: lookupResult,
                                    lookupMessage: lookupMessage,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          CollectorStickyBackButton(onPressed: _closeScanner),
        ],
      ),
    );
  }
}

class _ScannerPausedBanner extends StatelessWidget {
  const _ScannerPausedBanner({required this.isLoading});

  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHighest.withValues(alpha: 0.38),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isLoading ? Icons.search_rounded : Icons.pause_circle_rounded,
              color: AppColors.primary,
              size: 18,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              isLoading
                  ? 'Scanner paused while we look for a catalog match.'
                  : 'Scanner paused. Review the result below or scan again.',
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

class _ScannerPreviewCard extends StatelessWidget {
  const _ScannerPreviewCard({
    required this.controller,
    required this.onDetect,
    required this.height,
  });

  final MobileScannerController controller;
  final void Function(BarcodeCapture capture) onDetect;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(28),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          fit: StackFit.expand,
          children: [
            MobileScanner(
              controller: controller,
              fit: BoxFit.cover,
              onDetect: onDetect,
              errorBuilder: (context, error) {
                return _ScannerErrorState(
                  message:
                      error.errorCode == MobileScannerErrorCode.permissionDenied
                      ? 'Camera permission is required to scan barcodes.'
                      : 'Scanner unavailable right now. You can still add the item manually.',
                );
              },
            ),
            IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.14),
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Center(
                  child: Container(
                    width: 220,
                    height: 120,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.72),
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      color: Colors.black.withValues(alpha: 0.08),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LookupLoadingCard extends StatelessWidget {
  const _LookupLoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHighest.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.18),
        ),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Checking the catalog',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  'We found a barcode and are pulling the strongest match now.',
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

class _ScannerErrorState extends StatelessWidget {
  const _ScannerErrorState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.surfaceContainerHighest,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.qr_code_scanner_rounded,
                size: 52,
                color: AppColors.primary,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetectedBarcodeCard extends StatelessWidget {
  const _DetectedBarcodeCard({required this.barcode});

  final String barcode;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHighest.withValues(alpha: 0.48),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.2),
        ),
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
                  'SCANNED CODE',
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(color: AppColors.primary),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  barcode,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LookupPreviewCard extends StatelessWidget {
  const _LookupPreviewCard({required this.result});

  final CollectibleIdentificationResult? result;

  @override
  Widget build(BuildContext context) {
    final result = this.result;
    if (result == null) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHighest.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(18),
            ),
            clipBehavior: Clip.antiAlias,
            child: (result.imageUrl ?? '').isNotEmpty
                ? Image.network(
                    result.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const _LookupImageFallback(),
                  )
                : const _LookupImageFallback(),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result.sourceBadge.toUpperCase(),
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(color: AppColors.primary),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  result.title,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if ((result.suggestedCategory ?? '').isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    result.suggestedCategory!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LookupNoticeCard extends StatelessWidget {
  const _LookupNoticeCard({
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
        color: AppColors.surfaceContainerHighest.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.secondaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AppColors.secondary),
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
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'You can still continue and add the collectible manually.',
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(color: AppColors.primary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LookupImageFallback extends StatelessWidget {
  const _LookupImageFallback();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Icon(Icons.inventory_2_outlined, color: AppColors.primary),
    );
  }
}
