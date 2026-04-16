import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../core/collector_haptics.dart';
import '../core/collector_sound_effects.dart';
import '../features/collection/data/models/add_item_autofill_result.dart';
import '../features/collection/data/models/collectible_identification_result.dart';
import '../features/collection/data/repositories/collectible_identification_repository.dart';
import '../features/collection/data/services/add_item_autofill_resolver.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/category_icon.dart';
import '../widgets/collector_button.dart';
import '../widgets/collector_panel.dart';
import '../widgets/collector_sticky_back_button.dart';
import 'ai_photo_identification_screen.dart';
import 'manual_add_collectible_screen.dart';

enum _LookupPhase { idle, loading, found, notFound, failed }

enum _MultiScanItemStatus { queued, loading, found, notFound, failed }

class _MultiScanTrayItem {
  const _MultiScanTrayItem({
    required this.id,
    required this.barcode,
    required this.status,
    this.lookupResult,
    this.message,
  });

  final int id;
  final String barcode;
  final _MultiScanItemStatus status;
  final CollectibleIdentificationResult? lookupResult;
  final String? message;

  bool get canReview =>
      status == _MultiScanItemStatus.found ||
      status == _MultiScanItemStatus.notFound ||
      status == _MultiScanItemStatus.failed;

  _MultiScanTrayItem copyWith({
    _MultiScanItemStatus? status,
    CollectibleIdentificationResult? lookupResult,
    String? message,
    bool clearLookupResult = false,
    bool clearMessage = false,
  }) {
    return _MultiScanTrayItem(
      id: id,
      barcode: barcode,
      status: status ?? this.status,
      lookupResult: clearLookupResult
          ? null
          : lookupResult ?? this.lookupResult,
      message: clearMessage ? null : message ?? this.message,
    );
  }
}

class ScannerFlowScreen extends StatefulWidget {
  const ScannerFlowScreen({super.key, this.initialCategory});

  final String? initialCategory;

  @override
  State<ScannerFlowScreen> createState() => _ScannerFlowScreenState();
}

class _ScannerFlowScreenState extends State<ScannerFlowScreen> {
  static const _multiScanLimit = 5;

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
  bool _isMultiScanMode = false;
  bool _isProcessingMultiScanQueue = false;
  bool _createdDuringMultiScan = false;
  int _nextMultiScanItemId = 0;
  String? _multiScanNotice;
  List<_MultiScanTrayItem> _multiScanItems = const [];

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
      if (_isMultiScanMode) {
        await _addMultiScanBarcode(barcode);
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

  Future<void> _addMultiScanBarcode(String barcode) async {
    final normalizedBarcode = _normalizeBarcodeInput(barcode);
    if (normalizedBarcode.isEmpty) {
      return;
    }

    final alreadyScanned = _multiScanItems.any(
      (item) => item.barcode == normalizedBarcode,
    );
    if (alreadyScanned) {
      setState(() {
        _multiScanNotice = 'Already in the tray: $normalizedBarcode';
      });
      return;
    }

    if (_multiScanItems.length >= _multiScanLimit) {
      setState(() {
        _multiScanNotice = 'Review these 5 items before scanning more.';
      });
      await _pauseMultiScanAtLimit();
      return;
    }

    final item = _MultiScanTrayItem(
      id: _nextMultiScanItemId++,
      barcode: normalizedBarcode,
      status: _MultiScanItemStatus.queued,
    );

    setState(() {
      _multiScanItems = List.unmodifiable([..._multiScanItems, item]);
      _multiScanNotice =
          'Added ${_multiScanItems.length}/$_multiScanLimit: $normalizedBarcode';
    });

    if (_multiScanItems.length >= _multiScanLimit) {
      await _pauseMultiScanAtLimit();
    }

    _processMultiScanQueue();
  }

  Future<void> _pauseMultiScanAtLimit() async {
    if (_isScannerPaused) {
      return;
    }

    await _controller.stop();
    if (!mounted) {
      return;
    }

    setState(() {
      _isScannerPaused = true;
    });
  }

  Future<void> _processMultiScanQueue() async {
    if (_isProcessingMultiScanQueue) {
      return;
    }

    _isProcessingMultiScanQueue = true;
    try {
      while (mounted) {
        final queuedIndex = _multiScanItems.indexWhere(
          (item) => item.status == _MultiScanItemStatus.queued,
        );
        if (queuedIndex == -1) {
          break;
        }

        final item = _multiScanItems[queuedIndex];
        if (!_replaceMultiScanItem(
          item.id,
          item.copyWith(
            status: _MultiScanItemStatus.loading,
            clearLookupResult: true,
            clearMessage: true,
          ),
        )) {
          continue;
        }

        try {
          final lookupResult = await _identificationRepository.identifyBarcode(
            item.barcode,
          );
          if (!mounted) {
            return;
          }

          final status = lookupResult.hasCatalogMatch
              ? _MultiScanItemStatus.found
              : lookupResult.isNotFound
              ? _MultiScanItemStatus.notFound
              : _MultiScanItemStatus.failed;
          final message = lookupResult.hasCatalogMatch
              ? null
              : lookupResult.isNotFound
              ? 'No catalog match. Add it manually or try AI Photo ID.'
              : 'Lookup was unavailable. Retry, add manually, or use AI Photo ID.';

          _replaceMultiScanItem(
            item.id,
            item.copyWith(
              status: status,
              lookupResult: lookupResult,
              message: message,
              clearMessage: message == null,
            ),
          );
        } on CollectibleIdentificationException catch (error) {
          if (!mounted) {
            return;
          }
          _replaceMultiScanItem(
            item.id,
            item.copyWith(
              status: _MultiScanItemStatus.failed,
              message: error.message,
              clearLookupResult: true,
            ),
          );
        } catch (_) {
          if (!mounted) {
            return;
          }
          _replaceMultiScanItem(
            item.id,
            item.copyWith(
              status: _MultiScanItemStatus.failed,
              message:
                  'Lookup is unavailable right now. You can still add it manually.',
              clearLookupResult: true,
            ),
          );
        }

        await Future<void>.delayed(const Duration(milliseconds: 350));
      }
    } finally {
      _isProcessingMultiScanQueue = false;
    }
  }

  bool _replaceMultiScanItem(int id, _MultiScanTrayItem replacement) {
    final index = _multiScanItems.indexWhere((item) => item.id == id);
    if (index == -1 || !mounted) {
      return false;
    }

    final updatedItems = [..._multiScanItems];
    updatedItems[index] = replacement;
    setState(() {
      _multiScanItems = List.unmodifiable(updatedItems);
    });
    return true;
  }

  Future<void> _retryMultiScanItem(_MultiScanTrayItem item) async {
    if (!_replaceMultiScanItem(
      item.id,
      item.copyWith(
        status: _MultiScanItemStatus.queued,
        clearLookupResult: true,
        clearMessage: true,
      ),
    )) {
      return;
    }

    setState(() {
      _multiScanNotice = 'Retrying ${item.barcode}.';
    });
    await _processMultiScanQueue();
  }

  Future<void> _removeMultiScanItem(_MultiScanTrayItem item) async {
    setState(() {
      _multiScanItems = List.unmodifiable(
        _multiScanItems.where((entry) => entry.id != item.id),
      );
      _multiScanNotice = 'Removed ${item.barcode}.';
    });
    await _resumeMultiScanIfPossible();
  }

  Future<void> _clearMultiScanTray() async {
    setState(() {
      _multiScanItems = const [];
      _multiScanNotice = 'Tray cleared.';
    });
    await _resumeMultiScanIfPossible();
  }

  Future<void> _resumeMultiScanIfPossible() async {
    if (!_isMultiScanMode ||
        _multiScanItems.length >= _multiScanLimit ||
        !_isScannerPaused) {
      return;
    }

    await _controller.start();
    if (!mounted) {
      return;
    }

    setState(() {
      _isScannerPaused = false;
    });
  }

  Future<void> _toggleMultiScanMode() async {
    CollectorHaptics.selection();
    if (_isMultiScanMode) {
      if (_multiScanItems.isNotEmpty) {
        setState(() {
          _multiScanNotice = 'Clear the tray before returning to single scan.';
        });
        return;
      }

      setState(() {
        _isMultiScanMode = false;
        _multiScanNotice = null;
      });
      return;
    }

    if (_detectedBarcode != null) {
      await _resumeScanning();
      if (!mounted) {
        return;
      }
    }

    setState(() {
      _isMultiScanMode = true;
      _multiScanNotice = 'Multi-scan is ready. Scan up to 5 items.';
    });
  }

  Future<void> _reviewNextMultiScanItem() async {
    final nextItem = _nextReviewableMultiScanItem();
    if (nextItem == null) {
      setState(() {
        _multiScanNotice = _multiScanItems.isEmpty
            ? 'Scan an item to build the tray.'
            : 'Still checking. Review will be ready in a moment.';
      });
      return;
    }

    await _continueToManualAddForMultiScanItem(nextItem);
  }

  _MultiScanTrayItem? _nextReviewableMultiScanItem() {
    for (final item in _multiScanItems) {
      if (item.canReview) {
        return item;
      }
    }
    return null;
  }

  Future<void> _continueToManualAddForMultiScanItem(
    _MultiScanTrayItem item,
  ) async {
    final autofillResult = await _resolveAutofillResult(item.lookupResult);
    if (!mounted) {
      return;
    }

    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => ManualAddCollectibleScreen(
          scannedBarcode: item.barcode,
          identificationResult: item.lookupResult,
          autofillResult: autofillResult,
          initialCategory: widget.initialCategory,
        ),
      ),
    );

    if (!mounted) {
      return;
    }

    if (created == true) {
      await _finishMultiScanItem(item);
    }
  }

  Future<void> _openAiPhotoIdForMultiScanItem(_MultiScanTrayItem item) async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => AiPhotoIdentificationScreen(
          seedBarcode: item.barcode,
          initialCategory: widget.initialCategory,
        ),
      ),
    );

    if (!mounted) {
      return;
    }

    if (created == true) {
      await _finishMultiScanItem(item);
    }
  }

  Future<void> _finishMultiScanItem(_MultiScanTrayItem item) async {
    setState(() {
      _createdDuringMultiScan = true;
      _multiScanItems = List.unmodifiable(
        _multiScanItems.where((entry) => entry.id != item.id),
      );
      _multiScanNotice = 'Saved ${item.barcode}.';
    });

    final nextItem = _nextReviewableMultiScanItem();
    if (nextItem != null) {
      await Future<void>.delayed(const Duration(milliseconds: 220));
      if (mounted) {
        await _continueToManualAddForMultiScanItem(nextItem);
      }
      return;
    }

    await _resumeMultiScanIfPossible();
  }

  void _closeScanner() {
    Navigator.of(context).pop(_createdDuringMultiScan ? true : null);
  }

  static String _normalizeBarcodeInput(String barcode) {
    return barcode.replaceAll(RegExp(r'[^0-9Xx]'), '').trim();
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
      Navigator.of(context).pop(true);
    }
  }

  Widget _buildScannerModeToggle(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHighest.withValues(alpha: 0.34),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Multi-scan', style: textTheme.titleSmall),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  '${_multiScanItems.length}/$_multiScanLimit scanned',
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: _isMultiScanMode,
            onChanged: (_) => _toggleMultiScanMode(),
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
    if (_isMultiScanMode) {
      return _buildMultiScanContent(
        context: context,
        compactPanel: compactPanel,
      );
    }

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
              'Review the match, then continue to confirm or refine the details.',
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
                  label: 'Add details',
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

  Widget _buildMultiScanContent({
    required BuildContext context,
    required bool compactPanel,
  }) {
    final readyCount = _multiScanItems.where((item) => item.canReview).length;
    final isChecking = _multiScanItems.any(
      (item) =>
          item.status == _MultiScanItemStatus.queued ||
          item.status == _MultiScanItemStatus.loading,
    );
    final canReview = readyCount > 0;
    final isTrayFull = _multiScanItems.length >= _multiScanLimit;
    final shouldShowNotice = (_multiScanNotice ?? '').isNotEmpty && !isTrayFull;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Multi-scan',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    '${_multiScanItems.length}/$_multiScanLimit scanned',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (isChecking)
              Text(
                'Checking',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
          ],
        ),
        if (shouldShowNotice) ...[
          const SizedBox(height: AppSpacing.sm),
          _MultiScanNotice(message: _multiScanNotice!),
        ],
        const SizedBox(height: AppSpacing.sm),
        if (_multiScanItems.isEmpty)
          const _MultiScanEmptyTray()
        else
          _MultiScanTrayList(
            items: _multiScanItems,
            onAddDetails: _continueToManualAddForMultiScanItem,
            onAiPhoto: _openAiPhotoIdForMultiScanItem,
            onRetry: _retryMultiScanItem,
            onRemove: _removeMultiScanItem,
          ),
        SizedBox(height: compactPanel ? AppSpacing.lg : AppSpacing.xl),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CollectorButton(
              label: canReview
                  ? 'Review $readyCount ${readyCount == 1 ? 'item' : 'items'}'
                  : isChecking
                  ? 'Checking barcodes'
                  : 'Scan items first',
              onPressed: canReview ? _reviewNextMultiScanItem : null,
              isLoading: isChecking && !canReview,
            ),
            const SizedBox(height: AppSpacing.md),
            CollectorButton(
              label: 'Add one manually',
              onPressed: _openManualWithoutScan,
              variant: CollectorButtonVariant.secondary,
            ),
            if (_multiScanItems.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              CollectorButton(
                label: 'Clear tray',
                onPressed: _clearMultiScanTray,
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
    final shouldFocusMultiScanResults =
        _isMultiScanMode && _multiScanItems.isNotEmpty && _isScannerPaused;
    final shouldShowModeToggle = !_isMultiScanMode || _multiScanItems.isEmpty;

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
                                        : shouldFocusMultiScanResults
                                        ? const SizedBox.shrink(
                                            key: ValueKey(
                                              'multi-scan-results-focus',
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
                                                  !_isMultiScanMode &&
                                                  _lookupPhase ==
                                                      _LookupPhase.loading,
                                              message: _isMultiScanMode
                                                  ? 'Multi-scan tray is full. Review or clear items to scan more.'
                                                  : null,
                                            ),
                                          ),
                                  ),
                                  _buildScannerCategoryContext(context),
                                  if ((widget.initialCategory ?? '')
                                      .trim()
                                      .isNotEmpty)
                                    const SizedBox(height: AppSpacing.lg),
                                  if (shouldShowModeToggle) ...[
                                    _buildScannerModeToggle(context),
                                    const SizedBox(height: AppSpacing.lg),
                                  ],
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

class _MultiScanNotice extends StatelessWidget {
  const _MultiScanNotice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        message,
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: AppColors.onSurfaceVariant),
      ),
    );
  }
}

class _MultiScanEmptyTray extends StatelessWidget {
  const _MultiScanEmptyTray();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHighest.withValues(alpha: 0.36),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.qr_code_scanner_rounded,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              'Scan the first barcode to start the tray.',
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

class _MultiScanTrayList extends StatelessWidget {
  const _MultiScanTrayList({
    required this.items,
    required this.onAddDetails,
    required this.onAiPhoto,
    required this.onRetry,
    required this.onRemove,
  });

  final List<_MultiScanTrayItem> items;
  final void Function(_MultiScanTrayItem item) onAddDetails;
  final void Function(_MultiScanTrayItem item) onAiPhoto;
  final void Function(_MultiScanTrayItem item) onRetry;
  final void Function(_MultiScanTrayItem item) onRemove;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: items.length >= 5 ? 340 : 260),
      child: ListView.separated(
        primary: false,
        shrinkWrap: true,
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.xs),
        itemBuilder: (context, index) {
          return _MultiScanTrayRow(
            item: items[index],
            onAddDetails: onAddDetails,
            onAiPhoto: onAiPhoto,
            onRetry: onRetry,
            onRemove: onRemove,
          );
        },
      ),
    );
  }
}

class _MultiScanTrayRow extends StatelessWidget {
  const _MultiScanTrayRow({
    required this.item,
    required this.onAddDetails,
    required this.onAiPhoto,
    required this.onRetry,
    required this.onRemove,
  });

  final _MultiScanTrayItem item;
  final void Function(_MultiScanTrayItem item) onAddDetails;
  final void Function(_MultiScanTrayItem item) onAiPhoto;
  final void Function(_MultiScanTrayItem item) onRetry;
  final void Function(_MultiScanTrayItem item) onRemove;

  @override
  Widget build(BuildContext context) {
    final result = item.lookupResult;
    final statusLabel = _statusLabel(item.status);
    final primaryText = result?.title.trim().isNotEmpty == true
        ? result!.title
        : item.barcode;
    final secondaryText = result?.title.trim().isNotEmpty == true
        ? item.barcode
        : item.message ?? _helperText(item.status);

    return Material(
      color: AppColors.surfaceContainerHighest.withValues(alpha: 0.36),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: item.canReview ? () => onAddDetails(item) : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          child: Row(
            children: [
              _MultiScanTrayThumbnail(item: item),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            primaryText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          statusLabel,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(color: AppColors.primary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      secondaryText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              _MultiScanTrayRowMenu(
                item: item,
                onAddDetails: onAddDetails,
                onAiPhoto: onAiPhoto,
                onRetry: onRetry,
                onRemove: onRemove,
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _statusLabel(_MultiScanItemStatus status) {
    return switch (status) {
      _MultiScanItemStatus.queued => 'Queued',
      _MultiScanItemStatus.loading => 'Looking up',
      _MultiScanItemStatus.found => 'Found',
      _MultiScanItemStatus.notFound => 'No match',
      _MultiScanItemStatus.failed => 'Needs retry',
    };
  }

  static String _helperText(_MultiScanItemStatus status) {
    return switch (status) {
      _MultiScanItemStatus.queued => 'Waiting in line.',
      _MultiScanItemStatus.loading => 'Checking the catalog.',
      _MultiScanItemStatus.found => 'Tap to review.',
      _MultiScanItemStatus.notFound => 'Manual add or AI Photo ID.',
      _MultiScanItemStatus.failed => 'Retry or add manually.',
    };
  }

  static IconData _statusIcon(_MultiScanItemStatus status) {
    return switch (status) {
      _MultiScanItemStatus.queued => Icons.pending_actions_rounded,
      _MultiScanItemStatus.loading => Icons.search_rounded,
      _MultiScanItemStatus.found => Icons.check_circle_rounded,
      _MultiScanItemStatus.notFound => Icons.manage_search_rounded,
      _MultiScanItemStatus.failed => Icons.refresh_rounded,
    };
  }
}

class _MultiScanTrayThumbnail extends StatelessWidget {
  const _MultiScanTrayThumbnail({required this.item});

  final _MultiScanTrayItem item;

  @override
  Widget build(BuildContext context) {
    final imageUrl = item.lookupResult?.imageUrl?.trim();
    final hasImage = imageUrl != null && imageUrl.isNotEmpty;

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: hasImage
          ? Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _MultiScanTrayStatusIcon(item: item),
            )
          : _MultiScanTrayStatusIcon(item: item),
    );
  }
}

class _MultiScanTrayStatusIcon extends StatelessWidget {
  const _MultiScanTrayStatusIcon({required this.item});

  final _MultiScanTrayItem item;

  @override
  Widget build(BuildContext context) {
    if (item.status == _MultiScanItemStatus.loading) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    return Icon(
      _MultiScanTrayRow._statusIcon(item.status),
      color: AppColors.primary,
      size: 20,
    );
  }
}

class _MultiScanTrayRowMenu extends StatelessWidget {
  const _MultiScanTrayRowMenu({
    required this.item,
    required this.onAddDetails,
    required this.onAiPhoto,
    required this.onRetry,
    required this.onRemove,
  });

  final _MultiScanTrayItem item;
  final void Function(_MultiScanTrayItem item) onAddDetails;
  final void Function(_MultiScanTrayItem item) onAiPhoto;
  final void Function(_MultiScanTrayItem item) onRetry;
  final void Function(_MultiScanTrayItem item) onRemove;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_MultiScanTrayAction>(
      tooltip: 'Item actions',
      icon: const Icon(Icons.more_horiz_rounded),
      color: AppColors.surfaceContainerHigh,
      onSelected: (action) {
        switch (action) {
          case _MultiScanTrayAction.addDetails:
            onAddDetails(item);
            break;
          case _MultiScanTrayAction.aiPhoto:
            onAiPhoto(item);
            break;
          case _MultiScanTrayAction.retry:
            onRetry(item);
            break;
          case _MultiScanTrayAction.remove:
            onRemove(item);
            break;
        }
      },
      itemBuilder: (context) => [
        if (item.canReview)
          PopupMenuItem(
            value: _MultiScanTrayAction.addDetails,
            child: Text(
              item.status == _MultiScanItemStatus.found
                  ? 'Add details'
                  : 'Add manually',
            ),
          ),
        if (item.canReview)
          const PopupMenuItem(
            value: _MultiScanTrayAction.aiPhoto,
            child: Text('AI Photo ID'),
          ),
        if (item.status == _MultiScanItemStatus.failed)
          const PopupMenuItem(
            value: _MultiScanTrayAction.retry,
            child: Text('Retry'),
          ),
        const PopupMenuItem(
          value: _MultiScanTrayAction.remove,
          child: Text('Remove'),
        ),
      ],
    );
  }
}

enum _MultiScanTrayAction { addDetails, aiPhoto, retry, remove }

class _ScannerPausedBanner extends StatelessWidget {
  const _ScannerPausedBanner({required this.isLoading, this.message});

  final bool isLoading;
  final String? message;

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
              message ??
                  (isLoading
                      ? 'Scanner paused while we look for a catalog match.'
                      : 'Scanner paused. Review the result below or scan again.'),
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
