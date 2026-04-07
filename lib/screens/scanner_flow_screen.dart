import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../features/collection/data/models/barcode_lookup_result.dart';
import '../features/collection/data/services/upcitemdb_barcode_lookup_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/collector_button.dart';
import '../widgets/collector_panel.dart';
import 'manual_add_collectible_screen.dart';

enum _LookupPhase {
  idle,
  loading,
  found,
  notFound,
  failed,
}

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
  final UpcItemDbBarcodeLookupService _barcodeLookupService =
      UpcItemDbBarcodeLookupService();

  String? _detectedBarcode;
  BarcodeLookupResult? _lookupResult;
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
        .firstWhere(
          (value) => value.isNotEmpty,
          orElse: () => '',
        );

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
      final lookupResult = await _barcodeLookupService.lookup(barcode);
      if (!mounted || _detectedBarcode != barcode) {
        return;
      }

      setState(() {
        _lookupResult = lookupResult;
        _lookupPhase =
            lookupResult == null ? _LookupPhase.notFound : _LookupPhase.found;
        _lookupMessage = lookupResult == null
            ? 'No catalog match found. You can still continue and add the details manually.'
            : null;
      });
    } on BarcodeLookupException catch (error) {
      if (!mounted || _detectedBarcode != barcode) {
        return;
      }

      setState(() {
        _lookupResult = null;
        _lookupPhase = _LookupPhase.failed;
        _lookupMessage = error.message;
      });
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

    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => ManualAddCollectibleScreen(
          scannedBarcode: barcode,
          barcodeLookup: _lookupResult,
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

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topCenter,
                  radius: 1.2,
                  colors: [
                    AppColors.featureGlow,
                    AppColors.background,
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
                  Row(
                    children: [
                      CollectorButton(
                        label: 'Back',
                        onPressed: () => Navigator.of(context).pop(),
                        variant: CollectorButtonVariant.icon,
                        icon: Icons.arrow_back_rounded,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Expanded(
                    child: CollectorPanel(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      backgroundColor:
                          AppColors.surfaceContainer.withValues(alpha: 0.92),
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
                                  _ScannerPreviewCard(
                                    controller: _controller,
                                    onDetect: _handleDetect,
                                    height: previewHeight,
                                  ),
                                  const SizedBox(height: AppSpacing.lg),
                                  if (detectedBarcode == null)
                                    Text(
                                      'Scanning for UPC / EAN',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium,
                                    )
                                  else
                                    Text(
                                      _lookupPhase == _LookupPhase.loading
                                          ? 'Looking up the barcode'
                                          : 'Barcode detected',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium,
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
                                    if (_lookupPhase == _LookupPhase.loading) ...[
                                      const SizedBox(height: AppSpacing.md),
                                      const LinearProgressIndicator(
                                        minHeight: 3,
                                        borderRadius: BorderRadius.all(
                                          Radius.circular(999),
                                        ),
                                      ),
                                    ] else if (lookupResult != null) ...[
                                      const SizedBox(height: AppSpacing.md),
                                      _LookupPreviewCard(
                                        result: lookupResult,
                                      ),
                                    ] else if (lookupMessage != null) ...[
                                      const SizedBox(height: AppSpacing.md),
                                      Text(
                                        lookupMessage,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              color:
                                                  AppColors.onSurfaceVariant,
                                            ),
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
                                    Row(
                                      children: [
                                        Expanded(
                                          child: CollectorButton(
                                            label: 'Scan again',
                                            onPressed: _resumeScanning,
                                            variant: CollectorButtonVariant
                                                .secondary,
                                          ),
                                        ),
                                        const SizedBox(width: AppSpacing.md),
                                        Expanded(
                                          child: CollectorButton(
                                            label: 'Add details',
                                            onPressed: _continueToManualAdd,
                                          ),
                                        ),
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
                  message: error.errorCode == MobileScannerErrorCode.permissionDenied
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

class _ScannerErrorState extends StatelessWidget {
  const _ScannerErrorState({
    required this.message,
  });

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
  const _DetectedBarcodeCard({
    required this.barcode,
  });

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
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.primary,
                      ),
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
  const _LookupPreviewCard({
    required this.result,
  });

  final BarcodeLookupResult result;

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
            width: 72,
            height: 72,
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
                  'CATALOG MATCH',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.primary,
                      ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  result.title,
                  maxLines: 2,
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

class _LookupImageFallback extends StatelessWidget {
  const _LookupImageFallback();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Icon(
        Icons.inventory_2_outlined,
        color: AppColors.primary,
      ),
    );
  }
}
