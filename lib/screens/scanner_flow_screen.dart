import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../features/collection/data/models/add_item_autofill_result.dart';
import '../features/collection/data/models/collectible_identification_result.dart';
import '../features/collection/data/repositories/collectible_identification_repository.dart';
import '../features/collection/data/services/add_item_autofill_resolver.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/collector_button.dart';
import '../widgets/collector_panel.dart';
import '../widgets/collector_sticky_back_button.dart';
import 'ai_photo_identification_screen.dart';
import 'manual_add_collectible_screen.dart';

enum _LookupPhase { idle, loading, found, notFound, failed }

class ScannerFlowScreen extends StatefulWidget {
  const ScannerFlowScreen({super.key});

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

  String? _detectedBarcode;
  CollectibleIdentificationResult? _lookupResult;
  String? _lookupMessage;
  _LookupPhase _lookupPhase = _LookupPhase.idle;
  bool _isHandlingDetection = false;
  bool _isScannerPaused = false;

  @override
  void dispose() {
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

    try {
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
      return await _autofillResolver.resolve(identificationResult);
    } catch (_) {
      return null;
    }
  }

  Future<void> _openAiPhotoId() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) =>
            AiPhotoIdentificationScreen(seedBarcode: _detectedBarcode),
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

  Future<void> _openManualWithoutScan() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => const ManualAddCollectibleScreen(),
      ),
    );

    if (!mounted) {
      return;
    }

    if (created == true) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final detectedBarcode = _detectedBarcode;
    final lookupResult = _lookupResult;
    final lookupMessage = _lookupMessage;
    final showScannerPreview = detectedBarcode == null;

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
                                  if (detectedBarcode == null)
                                    Text(
                                      'Scanning for UPC / EAN',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleMedium,
                                    )
                                  else
                                    Text(
                                      _lookupPhase == _LookupPhase.loading
                                          ? 'Looking up the barcode'
                                          : lookupResult?.hasCatalogMatch ==
                                                true
                                          ? 'Catalog match found'
                                          : 'Barcode detected',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleMedium,
                                    ),
                                  const SizedBox(height: AppSpacing.sm),
                                  if (detectedBarcode == null)
                                    Text(
                                      'The first valid barcode will pause the scanner so you can decide what to do next.',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: AppColors.onSurfaceVariant,
                                          ),
                                    )
                                  else ...[
                                    _DetectedBarcodeCard(
                                      barcode: detectedBarcode,
                                    ),
                                    if (_lookupPhase ==
                                        _LookupPhase.loading) ...[
                                      const SizedBox(height: AppSpacing.md),
                                      const _LookupLoadingCard(),
                                    ] else if (lookupResult?.hasCatalogMatch ==
                                        true) ...[
                                      const SizedBox(height: AppSpacing.md),
                                      _LookupPreviewCard(result: lookupResult),
                                      const SizedBox(height: AppSpacing.sm),
                                      Text(
                                        'Review the match, then continue to confirm or refine the details.',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              color: AppColors.onSurfaceVariant,
                                            ),
                                      ),
                                    ] else if (lookupMessage != null) ...[
                                      const SizedBox(height: AppSpacing.md),
                                      _LookupNoticeCard(
                                        title:
                                            _lookupPhase ==
                                                _LookupPhase.notFound
                                            ? 'Barcode match missed'
                                            : 'Lookup unavailable',
                                        description: lookupMessage,
                                        icon:
                                            _lookupPhase ==
                                                _LookupPhase.notFound
                                            ? Icons.auto_awesome_rounded
                                            : Icons.cloud_off_rounded,
                                      ),
                                    ],
                                  ],
                                  SizedBox(
                                    height: compactPanel
                                        ? AppSpacing.lg
                                        : AppSpacing.xl,
                                  ),
                                  if (detectedBarcode == null)
                                    SizedBox(
                                      width: double.infinity,
                                      child: CollectorButton(
                                        label: 'Scan manually later',
                                        onPressed: _openManualWithoutScan,
                                        variant:
                                            CollectorButtonVariant.secondary,
                                      ),
                                    )
                                  else
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        if (lookupResult?.hasCatalogMatch ==
                                            true) ...[
                                          CollectorButton(
                                            label: 'Add details',
                                            onPressed: _continueToManualAdd,
                                          ),
                                          const SizedBox(height: AppSpacing.md),
                                          CollectorButton(
                                            label: 'Scan again',
                                            onPressed: _resumeScanning,
                                            variant: CollectorButtonVariant
                                                .secondary,
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
                                            variant: CollectorButtonVariant
                                                .secondary,
                                          ),
                                          const SizedBox(height: AppSpacing.sm),
                                          CollectorButton(
                                            label: 'Scan again',
                                            onPressed: _resumeScanning,
                                            variant:
                                                CollectorButtonVariant.tertiary,
                                          ),
                                        ],
                                      ],
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
          CollectorStickyBackButton(
            onPressed: () => Navigator.of(context).pop(),
          ),
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
