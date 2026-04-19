import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../core/collector_haptics.dart';
import '../features/collection/data/models/add_item_autofill_result.dart';
import '../features/collection/data/models/collectible_model.dart';
import '../features/collection/data/models/collectible_identification_result.dart';
import '../features/collection/data/models/tag_model.dart';
import '../features/collection/data/repositories/collectible_photos_repository.dart';
import '../features/collection/data/repositories/collection_vocabulary_repository.dart';
import '../features/collection/data/repositories/collectibles_repository.dart';
import '../features/collection/data/repositories/tags_repository.dart';
import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_spacing.dart';
import '../widgets/collector_bottom_sheet.dart';
import '../widgets/collector_button.dart';
import '../widgets/collector_panel.dart';
import '../widgets/collector_snack_bar.dart';
import '../widgets/collector_sticky_back_button.dart';
import '../widgets/collector_text_field.dart';

const _formHeaderBottomSpacing = AppSpacing.lg;
const _formSectionSpacing = 40.0;
const _formPanelContentSpacing = AppSpacing.md;
const _visibleSuggestionCount = 5;

class ManualAddCollectibleScreen extends StatefulWidget {
  const ManualAddCollectibleScreen({
    super.key,
    this.collectible,
    this.existingPhotoUrl,
    this.scannedBarcode,
    this.identificationResult,
    this.autofillResult,
    this.initialImage,
    this.initialCategory,
    this.selectedTagIds,
    this.newTagNames,
  });

  final CollectibleModel? collectible;
  final String? existingPhotoUrl;
  final String? scannedBarcode;
  final CollectibleIdentificationResult? identificationResult;
  final AddItemAutofillResult? autofillResult;
  final XFile? initialImage;
  final String? initialCategory;
  final List<String>? selectedTagIds;
  final List<String>? newTagNames;

  @override
  State<ManualAddCollectibleScreen> createState() =>
      _ManualAddCollectibleScreenState();
}

class _ManualAddCollectibleScreenState
    extends State<ManualAddCollectibleScreen> {
  static String? _lastUsedCategory;

  static const List<String> _topCategories = [
    'Action Figures',
    'Board Games',
    'Statues',
    'Vinyl Figures',
    'Trading Cards',
  ];

  static const List<String> _moreCategories = [
    'Comics',
    'Memorabilia',
    'Die-cast',
    'Other',
  ];

  static const List<_BoxStatusOption> _boxStatusOptions = [
    _BoxStatusOption(label: 'Sealed', value: 'sealed'),
    _BoxStatusOption(label: 'Boxed', value: 'boxed'),
    _BoxStatusOption(label: 'Partial Box', value: 'partial_box'),
    _BoxStatusOption(label: 'Loose', value: 'loose'),
  ];

  final _titleController = TextEditingController();
  final _customCategoryController = TextEditingController();
  final _customBrandController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _franchiseController = TextEditingController();
  final _seriesController = TextEditingController();
  final _characterController = TextEditingController();
  final _releaseYearController = TextEditingController();
  final _issueNumberController = TextEditingController();
  final _notesController = TextEditingController();
  final _repository = CollectiblesRepository();
  final _photosRepository = CollectiblePhotosRepository();
  final _tagsRepository = TagsRepository();
  final _imagePicker = ImagePicker();
  late final ScrollController _scrollController;

  XFile? _selectedImage;
  String? _selectedCategory;
  String? _selectedBrand;
  bool _useCustomCategory = false;
  bool _useCustomBrand = false;
  bool _detailsExpanded = false;
  String? _selectedCondition;
  String? _selectedBoxStatus;
  int _quantity = 1;
  bool _isFavorite = false;
  bool _isGrail = false;
  bool _isDuplicate = false;
  bool _isSaving = false;
  bool _isDeleting = false;
  bool _showFloatingSave = true;
  String? _titleError;
  String? _categoryError;
  List<String> _savedCategories = const [];
  List<String> _topBrands = const [];
  List<String> _moreBrands = const [];
  List<TagModel> _availableTags = const [];
  final Set<String> _selectedTagIds = <String>{};
  final List<String> _newTagNames = <String>[];
  late AddItemFormMode _formMode;

  bool get _isEditing => widget.collectible != null;
  bool get _isComicMode => _formMode == AddItemFormMode.comic;
  double get _floatingSaveRevealThreshold => _isEditing ? 260 : 132;
  String get _primaryActionLabel => _isEditing ? 'Save Changes' : 'Add Item';

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_handleScroll);
    _formMode = _resolveInitialFormMode();
    _hydrateFromCollectible();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncFloatingSaveVisibility();
    });
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    _titleController.dispose();
    _customCategoryController.dispose();
    _customBrandController.dispose();
    _descriptionController.dispose();
    _franchiseController.dispose();
    _seriesController.dispose();
    _characterController.dispose();
    _releaseYearController.dispose();
    _issueNumberController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _handleScroll() {
    _syncFloatingSaveVisibility();
  }

  void _syncFloatingSaveVisibility() {
    if (!mounted || !_scrollController.hasClients) {
      return;
    }

    final position = _scrollController.position;
    final shouldShow =
        (position.maxScrollExtent - position.pixels) >
        _floatingSaveRevealThreshold;

    if (shouldShow == _showFloatingSave) {
      return;
    }

    setState(() {
      _showFloatingSave = shouldShow;
    });
  }

  AddItemFormMode _resolveInitialFormMode() {
    final collectible = widget.collectible;
    if (collectible != null) {
      final category = collectible.category.trim().toLowerCase();
      if (category == 'comics' ||
          (collectible.itemNumber ?? '').trim().isNotEmpty) {
        return AddItemFormMode.comic;
      }
      return AddItemFormMode.general;
    }

    return widget.autofillResult?.formMode ??
        (widget.identificationResult?.isComicLike ?? false
            ? AddItemFormMode.comic
            : AddItemFormMode.general);
  }

  void _hydrateFromCollectible() {
    _selectedImage = widget.initialImage;
    _selectedTagIds
      ..clear()
      ..addAll(widget.selectedTagIds ?? const []);
    _newTagNames
      ..clear()
      ..addAll(widget.newTagNames ?? const []);

    final collectible = widget.collectible;
    if (collectible == null) {
      _applyInitialCategory();
      _hydrateFromIdentification();
      _applyAutofillResult();
      _loadSuggestions();
      return;
    }

    _titleController.text = collectible.title;
    _descriptionController.text = collectible.description ?? '';
    _franchiseController.text = collectible.franchise ?? '';
    _seriesController.text =
        collectible.series ?? collectible.lineOrSeries ?? '';
    _characterController.text = collectible.characterOrSubject ?? '';
    _releaseYearController.text = collectible.releaseYear?.toString() ?? '';
    _issueNumberController.text = collectible.itemNumber ?? '';
    final collectibleBrand = (collectible.brand ?? '').trim();
    _selectedBrand = collectibleBrand.isEmpty ? null : collectibleBrand;
    _useCustomBrand = collectibleBrand.isNotEmpty;
    _customBrandController.clear();
    _selectedTagIds
      ..clear()
      ..addAll(
        collectible.tags
            .map((tag) => tag.id)
            .whereType<String>()
            .where((id) => id.isNotEmpty),
      );
    _notesController.text = collectible.notes ?? '';
    _selectedCondition = collectible.itemCondition;
    _selectedBoxStatus = collectible.boxStatus;
    _quantity = collectible.quantity;
    _isFavorite = collectible.isFavorite;
    _isGrail = collectible.isGrail;
    _isDuplicate = collectible.isDuplicate;

    if (_topCategories.contains(collectible.category)) {
      _selectedCategory = collectible.category;
      _useCustomCategory = false;
    } else if (_moreCategories.contains(collectible.category)) {
      _selectedCategory = collectible.category;
      _useCustomCategory = false;
    } else {
      _customCategoryController.text = collectible.category;
      _useCustomCategory = true;
    }

    _detailsExpanded = _hasVisibleMetadata();
    _loadSuggestions();
  }

  void _applyInitialCategory() {
    final category = widget.initialCategory?.trim();
    if (category == null || category.isEmpty) {
      return;
    }

    _selectedCategory = category;
    _useCustomCategory = false;
    _customCategoryController.clear();
    _categoryError = null;
    _lastUsedCategory = category;
    _formMode = _isComicCategory(category)
        ? AddItemFormMode.comic
        : AddItemFormMode.general;
  }

  void _hydrateFromIdentification() {
    final identificationResult = widget.identificationResult;
    if (identificationResult == null) {
      return;
    }

    if (_titleController.text.trim().isEmpty) {
      _titleController.text = identificationResult.title;
    }

    if (((_selectedBrand ?? '').trim().isEmpty) &&
        (identificationResult.brand ?? '').trim().isNotEmpty) {
      _selectedBrand = identificationResult.brand!.trim();
      _useCustomBrand = true;
      _customBrandController.clear();
    }

    if (_descriptionController.text.trim().isEmpty) {
      _descriptionController.text = identificationResult.description ?? '';
    }
    if (_franchiseController.text.trim().isEmpty) {
      _franchiseController.text = identificationResult.franchise ?? '';
    }
    if (_seriesController.text.trim().isEmpty) {
      _seriesController.text =
          _usefulSeriesCandidate(identificationResult.volumeCandidate) ??
          _usefulSeriesCandidate(identificationResult.series) ??
          '';
    }
    if (_characterController.text.trim().isEmpty) {
      _characterController.text = identificationResult.characterOrSubject ?? '';
    }
    if (_releaseYearController.text.trim().isEmpty &&
        identificationResult.releaseYear != null) {
      _releaseYearController.text = identificationResult.releaseYear.toString();
    }
    if (_issueNumberController.text.trim().isEmpty) {
      _issueNumberController.text = identificationResult.issueNumber ?? '';
    }
  }

  void _applyAutofillResult() {
    final autofillResult = widget.autofillResult;
    if (autofillResult == null) {
      _detailsExpanded = _hasVisibleMetadata();
      return;
    }

    if (!_hasExplicitInitialCategory) {
      _formMode = autofillResult.formMode;
    }
    _setIfEmpty(_titleController, autofillResult.title);
    _setIfEmpty(_descriptionController, autofillResult.description);
    _setIfEmpty(_franchiseController, autofillResult.franchise);
    _setIfEmpty(_seriesController, autofillResult.seriesOrVolume);
    _setIfEmpty(_characterController, autofillResult.characterOrSubject);
    _setIfEmpty(_releaseYearController, autofillResult.releaseYear?.toString());
    _setIfEmpty(_issueNumberController, autofillResult.issueNumber);

    _applyResolvedBrand(autofillResult.brandOrPublisher);
    _applyTagSuggestions(autofillResult);

    _detailsExpanded = _hasVisibleMetadata();
  }

  Future<void> _loadSuggestions() async {
    try {
      final results = await Future.wait([
        _repository.fetchAll(),
        _tagsRepository.fetchAll(),
      ]);
      final collectibles = results[0] as List<CollectibleModel>;
      final tags = results[1] as List<TagModel>;
      if (!mounted) {
        return;
      }

      final categoryCounts = <String, int>{};
      final brandCounts = <String, int>{};
      for (final item in collectibles) {
        final category = item.category.trim();
        if (category.isNotEmpty) {
          categoryCounts.update(
            category,
            (value) => value + 1,
            ifAbsent: () => 1,
          );
        }

        final brand = (item.brand ?? '').trim();
        if (brand.isEmpty) {
          continue;
        }

        brandCounts.update(brand, (value) => value + 1, ifAbsent: () => 1);
      }

      int sortByCountThenName(
        MapEntry<String, int> a,
        MapEntry<String, int> b,
      ) {
        final byCount = b.value.compareTo(a.value);
        return byCount == 0 ? a.key.compareTo(b.key) : byCount;
      }

      final sortedCategories = categoryCounts.entries.toList()
        ..sort(sortByCountThenName);
      final sortedBrands = brandCounts.entries.toList()
        ..sort(sortByCountThenName);

      final savedCategories = sortedCategories
          .map((entry) => entry.key)
          .toList(growable: false);

      final brands = sortedBrands
          .map((entry) => entry.key)
          .toList(growable: false);
      final topBrands = brands
          .take(_visibleSuggestionCount)
          .toList(growable: false);
      final moreBrands = brands
          .skip(_visibleSuggestionCount)
          .toList(growable: false);
      final pendingCategory = _useCustomCategory
          ? _customCategoryController.text.trim()
          : (_selectedCategory ?? '').trim();
      final pendingBrand = (_selectedBrand ?? '').trim();

      setState(() {
        _savedCategories = savedCategories;
        _topBrands = topBrands;
        _moreBrands = moreBrands;
        _availableTags = tags;

        if (pendingCategory.isNotEmpty) {
          final existingCategory = savedCategories.cast<String?>().firstWhere(
            (category) =>
                (category ?? '').trim().toLowerCase() ==
                pendingCategory.toLowerCase(),
            orElse: () => null,
          );
          if (existingCategory != null) {
            _selectedCategory = existingCategory;
            _useCustomCategory = false;
            _customCategoryController.clear();
          }
        }

        if (pendingBrand.isEmpty) {
          return;
        }

        if (brands.contains(pendingBrand)) {
          _selectedBrand = pendingBrand;
          _useCustomBrand = false;
        } else {
          _selectedBrand = pendingBrand;
          _useCustomBrand = true;
        }
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _savedCategories = const [];
        _topBrands = const [];
        _moreBrands = const [];
        _availableTags = const [];
      });
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final image = await _imagePicker.pickImage(
      source: source,
      imageQuality: 88,
      maxWidth: 1800,
    );

    if (!mounted || image == null) {
      return;
    }

    setState(() {
      _selectedImage = image;
    });
  }

  void _selectCategory(String category) {
    final trimmedCategory = category.trim();
    CollectorHaptics.selection();
    setState(() {
      _useCustomCategory = false;
      _selectedCategory = trimmedCategory;
      _customCategoryController.clear();
      _categoryError = null;
      _formMode = _isComicCategory(trimmedCategory)
          ? AddItemFormMode.comic
          : AddItemFormMode.general;
    });
    _lastUsedCategory = trimmedCategory.isEmpty ? null : trimmedCategory;
  }

  void _selectBrand(String brand) {
    CollectorHaptics.selection();
    setState(() {
      _useCustomBrand = false;
      _selectedBrand = brand;
      _customBrandController.clear();
    });
  }

  void _toggleDetailsExpanded() {
    CollectorHaptics.selection();
    setState(() {
      _detailsExpanded = !_detailsExpanded;
    });
  }

  Future<void> _openPhotoSourceSheet() async {
    CollectorHaptics.light();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _PhotoSourceBottomSheet(),
    );

    if (!mounted || source == null) {
      return;
    }

    await _pickImage(source);
  }

  Future<void> _openCategorySelectorSheet() async {
    final latestCategory = (_lastUsedCategory ?? '').trim();
    CollectorHaptics.light();
    final selected = await showModalBottomSheet<String>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _OptionSearchBottomSheet(
        title: 'Choose category',
        description:
            'Search categories instead of browsing a long wall of pills.',
        searchHint: 'Search categories',
        options: _categoryOptions,
        pinnedOption: latestCategory.isEmpty ? null : latestCategory,
        selectedValue: _useCustomCategory ? null : _selectedCategory,
        createActionLabel: 'Create category',
        createFieldLabel: 'Category name',
        createFieldHint: 'Display pieces',
        createSubmitLabel: 'Use category',
        initialCreateValue: _useCustomCategory
            ? _customCategoryController.text
            : '',
      ),
    );

    if (!mounted || selected == null) {
      return;
    }

    _selectCategory(selected);
  }

  Future<void> _openBrandSelectorSheet() async {
    CollectorHaptics.light();
    final selected = await showModalBottomSheet<String>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _OptionSearchBottomSheet(
        title: _brandSheetTitle,
        description: _brandSheetDescription,
        searchHint: _isComicMode ? 'Search publishers' : 'Search brands',
        options: _brandOptions,
        selectedValue: _useCustomBrand ? null : _selectedBrand,
        createActionLabel: _isComicMode ? 'Create publisher' : 'Create brand',
        createFieldLabel: _isComicMode ? 'Publisher name' : 'Brand name',
        createFieldHint: _isComicMode ? 'Comic publisher' : 'Toy maker',
        createSubmitLabel: _isComicMode ? 'Use publisher' : 'Use brand',
        initialCreateValue: _useCustomBrand ? _customBrandController.text : '',
        emptyStateLabel: _brandEmptyLabel,
      ),
    );

    if (!mounted || selected == null) {
      return;
    }

    _selectBrand(selected);
  }

  Future<void> _openTagsSelectorSheet() async {
    CollectorHaptics.light();
    final result = await showModalBottomSheet<_TagPickerSheetResult>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _TagSearchBottomSheet(
        availableTags: _availableTags,
        selectedTagIds: _selectedTagIds,
        newTagNames: _newTagNames,
      ),
    );

    if (!mounted || result == null) {
      return;
    }

    CollectorHaptics.selection();
    setState(() {
      _selectedTagIds
        ..clear()
        ..addAll(result.selectedTagIds);
      _newTagNames
        ..clear()
        ..addAll(result.newTagNames);
    });
  }

  void _removeSelectedExistingTag(String tagId) {
    CollectorHaptics.selection();
    setState(() {
      _selectedTagIds.remove(tagId);
    });
  }

  void _removeNewTagName(String tagName) {
    CollectorHaptics.selection();
    setState(() {
      _newTagNames.removeWhere(
        (existing) => existing.toLowerCase() == tagName.toLowerCase(),
      );
    });
  }

  String _resolvedCategory() {
    if (_isComicMode) {
      final resolvedComicCategory = (_selectedCategory ?? '').trim();
      if (resolvedComicCategory.isNotEmpty) {
        return resolvedComicCategory;
      }
      return _customCategoryController.text.trim();
    }

    if (_useCustomCategory) {
      return _customCategoryController.text.trim();
    }

    return (_selectedCategory ?? '').trim();
  }

  bool _isComicCategory(String category) {
    return category.trim().toLowerCase() == 'comics';
  }

  bool get _hasExplicitInitialCategory {
    final category = widget.initialCategory?.trim();
    return category != null && category.isNotEmpty;
  }

  String? _resolvedBrand() {
    final selectedBrand = (_selectedBrand ?? '').trim();
    return selectedBrand.isEmpty ? null : selectedBrand;
  }

  String _resolvedCategoryDisplayValue() {
    final category = _resolvedCategory();
    return category.isEmpty ? 'Choose a category' : category;
  }

  String _resolvedBrandDisplayValue() {
    final brand = _resolvedBrand();
    if ((brand ?? '').isEmpty) {
      return _isComicMode ? 'Choose a publisher' : 'Optional for now';
    }
    return brand!;
  }

  List<String> get _categoryOptions => [
    ...{
      ..._topCategories,
      ..._moreCategories,
      ..._savedCategories,
      if ((_selectedCategory ?? '').trim().isNotEmpty) _selectedCategory!,
      if (_useCustomCategory &&
          _customCategoryController.text.trim().isNotEmpty)
        _customCategoryController.text.trim(),
    },
  ].toList(growable: false);

  List<String> get _brandOptions => [
    ...{
      ..._topBrands,
      ..._moreBrands,
      if ((_selectedBrand ?? '').trim().isNotEmpty) _selectedBrand!,
      if (_useCustomBrand && _customBrandController.text.trim().isNotEmpty)
        _customBrandController.text.trim(),
    },
  ].toList(growable: false);

  List<TagModel> get _selectedExistingTags => _availableTags
      .where(
        (tag) => (tag.id ?? '').isNotEmpty && _selectedTagIds.contains(tag.id),
      )
      .toList(growable: false);

  bool get _hasSelectedTags =>
      _selectedExistingTags.isNotEmpty || _newTagNames.isNotEmpty;

  String get _resolvedTagsDisplayValue {
    final count = _selectedExistingTags.length + _newTagNames.length;
    if (count == 0) {
      return 'Optional for now';
    }
    if (count == 1) {
      return _selectedExistingTags.isNotEmpty
          ? _selectedExistingTags.first.name
          : _newTagNames.first;
    }
    return '$count tags selected';
  }

  String get _tagsFieldHelperText {
    if (!_hasSelectedTags) {
      return 'Optional for browsing later';
    }
    final names = [
      ..._selectedExistingTags.map((tag) => tag.name),
      ..._newTagNames,
    ];
    return names.take(2).join(', ') +
        (names.length > 2 ? ' +${names.length - 2}' : '');
  }

  String? _nullableText(TextEditingController controller) {
    final value = controller.text.trim();
    return value.isEmpty ? null : value;
  }

  String? _usefulSeriesCandidate(String? value) {
    final cleaned = value?.trim();
    if (cleaned == null ||
        cleaned.isEmpty ||
        !RegExp(r'[A-Za-z]').hasMatch(cleaned)) {
      return null;
    }

    final compact = cleaned.replaceAll(RegExp(r'[^A-Za-z0-9]'), '');
    final hasSeparator = RegExp(r'[^A-Za-z0-9]').hasMatch(cleaned);
    final hasLowercase = RegExp(r'[a-z]').hasMatch(cleaned);
    final isAllCapsCode =
        !hasLowercase &&
        !hasSeparator &&
        RegExp(r'^[A-Z0-9]+$').hasMatch(compact) &&
        compact.length > 5;

    return isAllCapsCode ? null : cleaned;
  }

  int? _nullableInt(TextEditingController controller) {
    final value = controller.text.trim();
    if (value.isEmpty) {
      return null;
    }
    return int.tryParse(value);
  }

  void _setIfEmpty(TextEditingController controller, String? value) {
    if (controller.text.trim().isNotEmpty) {
      return;
    }
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return;
    }
    controller.text = trimmed;
  }

  void _applyResolvedBrand(ResolvedMatch<String>? resolvedMatch) {
    final value = resolvedMatch?.resolvedValue?.trim();
    if (value == null || value.isEmpty) {
      return;
    }

    _selectedBrand = value;
    if (resolvedMatch!.hasExistingMatch) {
      _useCustomBrand = false;
      _customBrandController.clear();
      return;
    }

    _useCustomBrand = true;
    _customBrandController.text = value;
  }

  void _applyTagSuggestions(AddItemAutofillResult autofillResult) {
    _selectedTagIds.addAll(autofillResult.matchedTagIds);
    for (final tagName in autofillResult.newTagNames) {
      final alreadySelectedExisting = _availableTags.any(
        (tag) =>
            tag.name.trim().toLowerCase() == tagName.toLowerCase() &&
            _selectedTagIds.contains(tag.id),
      );
      final alreadyQueued = _newTagNames.any(
        (existing) => existing.toLowerCase() == tagName.toLowerCase(),
      );

      if (!alreadySelectedExisting && !alreadyQueued) {
        _newTagNames.add(tagName);
      }
    }
  }

  bool _hasVisibleMetadata() {
    if (_isComicMode) {
      return _descriptionController.text.trim().isNotEmpty ||
          _releaseYearController.text.trim().isNotEmpty ||
          _selectedCondition != null ||
          _isFavorite;
    }

    return _descriptionController.text.trim().isNotEmpty ||
        _selectedBoxStatus != null ||
        _isFavorite;
  }

  String get _screenTitle {
    if (_isEditing) {
      return _isComicMode ? 'Edit comic.' : 'Edit item.';
    }
    return _isComicMode ? 'Add a comic.' : 'Add an item.';
  }

  String get _screenDescription {
    if (_isEditing) {
      return '';
    }

    return _isComicMode
        ? 'Comic details work a little differently, so we front-load the issue and publisher info.'
        : 'Save the essentials first. Add more only if it helps.';
  }

  String get _brandFieldLabel => _isComicMode ? 'Publisher' : 'Brand';

  String get _brandSheetTitle =>
      _isComicMode ? 'Choose publisher' : 'Choose brand';

  String get _brandSheetDescription => _isComicMode
      ? 'Search the publishers already in your collection or add a new one.'
      : 'Search the brands already in your collection or add a new one.';

  String get _brandFieldHelperText => _isComicMode
      ? 'Publisher helps organize comic runs'
      : 'Optional for the first save';

  String get _brandEmptyLabel =>
      _isComicMode ? 'No saved publishers yet' : 'No saved brands yet';

  Future<void> _save() async {
    final title = _titleController.text.trim();
    final category = _resolvedCategory();

    setState(() {
      _titleError = title.isEmpty ? 'Title is required.' : null;
      _categoryError = category.isEmpty ? 'Category is required.' : null;
    });

    if (_titleError != null || _categoryError != null) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final messenger = ScaffoldMessenger.of(context);
      _lastUsedCategory = category;
      final writeModel = CollectibleModel(
        id: widget.collectible?.id,
        userId: widget.collectible?.userId,
        barcode:
            (widget.scannedBarcode ??
                    widget.autofillResult?.barcode ??
                    widget.collectible?.barcode)
                ?.trim(),
        title: title,
        category: category,
        description: _nullableText(_descriptionController),
        brand: _resolvedBrand(),
        series: _nullableText(_seriesController),
        franchise: _nullableText(_franchiseController),
        lineOrSeries: _nullableText(_seriesController),
        characterOrSubject: _nullableText(_characterController),
        releaseYear: _nullableInt(_releaseYearController),
        itemCondition: _selectedCondition,
        boxStatus: _isComicMode
            ? (widget.collectible?.boxStatus ?? _selectedBoxStatus)
            : _selectedBoxStatus,
        itemNumber: _nullableText(_issueNumberController),
        quantity: _quantity,
        isFavorite: _isFavorite,
        isGrail: _isGrail,
        isDuplicate: _isDuplicate,
        openToTrade: false,
        notes: _nullableText(_notesController),
      );

      final collectible = _isEditing
          ? await _repository.update(
              writeModel,
              tagIds: _selectedTagIds,
              newTagNames: _newTagNames,
            )
          : await _repository.create(
              writeModel,
              tagIds: _selectedTagIds,
              newTagNames: _newTagNames,
            );

      var photoUploadFailed = false;
      final selectedImage = _selectedImage;
      final collectibleId = collectible.id;

      if (selectedImage != null && collectibleId != null) {
        try {
          if (_isEditing) {
            await _photosRepository.replacePrimaryPhoto(
              collectibleId: collectibleId,
              localImagePath: selectedImage.path,
              originalFileName: selectedImage.name,
              caption: title,
            );
          } else {
            await _photosRepository.uploadPrimaryPhoto(
              collectibleId: collectibleId,
              localImagePath: selectedImage.path,
              originalFileName: selectedImage.name,
              caption: title,
            );
          }
        } catch (_) {
          photoUploadFailed = true;
        }
      } else if (!_isEditing &&
          collectibleId != null &&
          (widget.identificationResult?.imageUrl ?? '').isNotEmpty) {
        try {
          await _photosRepository.uploadPrimaryPhotoFromRemoteImage(
            collectibleId: collectibleId,
            imageUrl: widget.identificationResult!.imageUrl!,
            fallbackFileName: title.toLowerCase().replaceAll(' ', '-'),
            caption: title,
          );
        } catch (_) {
          photoUploadFailed = true;
        }
      }

      if (!mounted) {
        return;
      }

      CollectorHaptics.medium();
      CollectionVocabularyRepository.invalidateCache();
      Navigator.of(context).pop(true);

      CollectorSnackBar.showOn(
        messenger,
        message: selectedImage == null
            ? _isEditing
                  ? 'Item updated.'
                  : 'Item added.'
            : photoUploadFailed
            ? _isEditing
                  ? 'Item updated, but the photo could not be uploaded.'
                  : 'Item added, but the photo could not be uploaded.'
            : _isEditing
            ? 'Item and photo updated.'
            : 'Item and photo added.',
        tone: photoUploadFailed
            ? CollectorSnackBarTone.warning
            : CollectorSnackBarTone.success,
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      CollectorSnackBar.show(
        context,
        message: _isEditing
            ? 'Could not update this item right now. Please try again.'
            : 'Could not add this item right now. Please try again.',
        tone: CollectorSnackBarTone.error,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _deleteItem() async {
    if (!_isEditing || _isSaving || _isDeleting) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surfaceContainerHigh,
          title: const Text('Delete item?'),
          content: const Text(
            'This will remove the collectible and its saved photo from your collection.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(backgroundColor: AppColors.error),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    final collectibleId = widget.collectible?.id;
    if (collectibleId == null) {
      return;
    }

    setState(() {
      _isDeleting = true;
    });

    try {
      await _photosRepository.deleteAllForCollectible(collectibleId);
      await _repository.delete(collectibleId);

      if (!mounted) {
        return;
      }

      final messenger = ScaffoldMessenger.of(context);
      CollectorHaptics.heavy();
      CollectionVocabularyRepository.invalidateCache();
      Navigator.of(context).pop(true);
      CollectorSnackBar.showOn(
        messenger,
        message: 'Removed from collection.',
        tone: CollectorSnackBarTone.success,
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      CollectorSnackBar.show(
        context,
        message: 'Could not remove this item right now.',
        tone: CollectorSnackBarTone.error,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedImage = _selectedImage;
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final bottomScrollPadding = _showFloatingSave ? 156.0 : AppSpacing.xl;

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
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.md,
                      AppSpacing.md,
                      _formHeaderBottomSpacing,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 44),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          _screenTitle,
                          style: Theme.of(context).textTheme.headlineLarge,
                        ),
                        if (_screenDescription.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            _screenDescription,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: AppColors.onSurfaceVariant),
                          ),
                        ],
                        if ((widget.scannedBarcode ?? '').isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.md),
                          _ScannedBarcodeBanner(
                            barcode: widget.scannedBarcode!,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    0,
                    AppSpacing.md,
                    bottomScrollPadding,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _PhotoSection(
                        selectedImage: selectedImage,
                        existingPhotoUrl: widget.existingPhotoUrl,
                        lookupImageUrl: widget.identificationResult?.imageUrl,
                        onEditPhoto: _openPhotoSourceSheet,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _SectionPanel(
                        eyebrow: '',
                        title: _isComicMode ? 'Comic essentials' : 'Basics',
                        description: '',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CollectorTextField(
                              label: 'Title',
                              hintText: _isComicMode
                                  ? 'Series title #1'
                                  : 'Item name or release title',
                              controller: _titleController,
                              errorText: _titleError,
                              textInputAction: TextInputAction.next,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            const _BasicsDivider(),
                            const SizedBox(height: AppSpacing.md),
                            if (_isComicMode) ...[
                              _SelectionField(
                                label: 'Category',
                                value: _resolvedCategoryDisplayValue(),
                                helperText:
                                    'Change this if the item was classified wrong',
                                errorText: _categoryError,
                                actionLabel: _resolvedCategory().trim().isEmpty
                                    ? 'Choose'
                                    : 'Change',
                                onTap: _openCategorySelectorSheet,
                                isPlaceholder: _resolvedCategory()
                                    .trim()
                                    .isEmpty,
                                compact: true,
                                showActionLabel: false,
                                showHelperWhenSelected: false,
                              ),
                              const SizedBox(height: AppSpacing.md),
                              const _BasicsDivider(),
                              const SizedBox(height: AppSpacing.md),
                              _SelectionField(
                                label: _brandFieldLabel,
                                value: _resolvedBrandDisplayValue(),
                                helperText: _brandFieldHelperText,
                                actionLabel:
                                    (_resolvedBrand() ?? '').trim().isEmpty
                                    ? 'Choose'
                                    : 'Change',
                                onTap: _openBrandSelectorSheet,
                                isPlaceholder: (_resolvedBrand() ?? '')
                                    .trim()
                                    .isEmpty,
                                compact: true,
                                showActionLabel: false,
                                showHelperWhenSelected: false,
                              ),
                              const SizedBox(height: AppSpacing.md),
                              const _BasicsDivider(),
                              const SizedBox(height: AppSpacing.md),
                              _SelectionField(
                                label: 'Tags',
                                value: _resolvedTagsDisplayValue,
                                helperText: _tagsFieldHelperText,
                                actionLabel: _hasSelectedTags
                                    ? 'Edit'
                                    : 'Choose',
                                onTap: _openTagsSelectorSheet,
                                isPlaceholder: !_hasSelectedTags,
                                footer: _hasSelectedTags
                                    ? Padding(
                                        padding: const EdgeInsets.only(
                                          top: AppSpacing.sm,
                                        ),
                                        child: Wrap(
                                          spacing: AppSpacing.sm,
                                          runSpacing: AppSpacing.sm,
                                          children: [
                                            for (final tag
                                                in _selectedExistingTags)
                                              _EditableTagChip(
                                                label: tag.name,
                                                onRemove: () =>
                                                    _removeSelectedExistingTag(
                                                      tag.id!,
                                                    ),
                                              ),
                                            for (final tagName in _newTagNames)
                                              _EditableTagChip(
                                                label: tagName,
                                                onRemove: () =>
                                                    _removeNewTagName(tagName),
                                              ),
                                          ],
                                        ),
                                      )
                                    : null,
                              ),
                            ] else ...[
                              _SelectionField(
                                label: 'Category',
                                value: _resolvedCategoryDisplayValue(),
                                helperText: 'Required to save',
                                errorText: _categoryError,
                                actionLabel: _resolvedCategory().trim().isEmpty
                                    ? 'Choose'
                                    : 'Change',
                                onTap: _openCategorySelectorSheet,
                                isPlaceholder: _resolvedCategory()
                                    .trim()
                                    .isEmpty,
                                compact: true,
                                showActionLabel: false,
                                showHelperWhenSelected: false,
                              ),
                              const SizedBox(height: AppSpacing.md),
                              const _BasicsDivider(),
                              const SizedBox(height: AppSpacing.md),
                              _SelectionField(
                                label: _brandFieldLabel,
                                value: _resolvedBrandDisplayValue(),
                                helperText: _brandFieldHelperText,
                                actionLabel:
                                    (_resolvedBrand() ?? '').trim().isEmpty
                                    ? 'Choose'
                                    : 'Change',
                                onTap: _openBrandSelectorSheet,
                                isPlaceholder: (_resolvedBrand() ?? '')
                                    .trim()
                                    .isEmpty,
                                compact: true,
                                showActionLabel: false,
                                showHelperWhenSelected: false,
                              ),
                              const SizedBox(height: AppSpacing.md),
                              const _BasicsDivider(),
                              const SizedBox(height: AppSpacing.md),
                              _SelectionField(
                                label: 'Tags',
                                value: _resolvedTagsDisplayValue,
                                helperText: _tagsFieldHelperText,
                                actionLabel: _hasSelectedTags
                                    ? 'Edit'
                                    : 'Choose',
                                onTap: _openTagsSelectorSheet,
                                isPlaceholder: !_hasSelectedTags,
                                footer: _hasSelectedTags
                                    ? Padding(
                                        padding: const EdgeInsets.only(
                                          top: AppSpacing.sm,
                                        ),
                                        child: Wrap(
                                          spacing: AppSpacing.sm,
                                          runSpacing: AppSpacing.sm,
                                          children: [
                                            for (final tag
                                                in _selectedExistingTags)
                                              _EditableTagChip(
                                                label: tag.name,
                                                onRemove: () =>
                                                    _removeSelectedExistingTag(
                                                      tag.id!,
                                                    ),
                                              ),
                                            for (final tagName in _newTagNames)
                                              _EditableTagChip(
                                                label: tagName,
                                                onRemove: () =>
                                                    _removeNewTagName(tagName),
                                              ),
                                          ],
                                        ),
                                      )
                                    : null,
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: _formSectionSpacing),
                      _ExpandableSectionPanel(
                        eyebrow: '',
                        title: 'Details',
                        description: _isComicMode
                            ? 'A few extra fields when they help.'
                            : 'Only the details that matter here.',
                        expanded: _detailsExpanded,
                        onToggle: _toggleDetailsExpanded,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_isComicMode) ...[
                              CollectorTextField(
                                label: 'Series / Volume',
                                hintText: 'Series or volume title',
                                controller: _seriesController,
                                textInputAction: TextInputAction.next,
                              ),
                              const SizedBox(height: AppSpacing.md),
                              CollectorTextField(
                                label: 'Issue number',
                                hintText: '1',
                                controller: _issueNumberController,
                                keyboardType: TextInputType.number,
                                textInputAction: TextInputAction.next,
                              ),
                              const SizedBox(height: AppSpacing.md),
                              CollectorTextField(
                                label: 'Release year',
                                hintText: 'YYYY',
                                controller: _releaseYearController,
                                keyboardType: TextInputType.number,
                                textInputAction: TextInputAction.next,
                              ),
                              const SizedBox(height: AppSpacing.md),
                              _TextAreaField(
                                label: 'Description',
                                hintText: 'Short synopsis or condition notes.',
                                controller: _descriptionController,
                              ),
                            ] else ...[
                              Text(
                                'BOX STATUS',
                                style: Theme.of(context).textTheme.labelSmall,
                              ),
                              const SizedBox(height: AppSpacing.xxs),
                              const SizedBox(height: AppSpacing.sm),
                              Wrap(
                                spacing: AppSpacing.sm,
                                runSpacing: AppSpacing.sm,
                                children: _boxStatusOptions
                                    .map(
                                      (option) => _SingleSelectChoiceChip(
                                        label: option.label,
                                        tone: _ChipTone.neutral,
                                        selected:
                                            _selectedBoxStatus == option.value,
                                        onTap: () {
                                          setState(() {
                                            _selectedBoxStatus =
                                                _selectedBoxStatus ==
                                                    option.value
                                                ? null
                                                : option.value;
                                          });
                                        },
                                      ),
                                    )
                                    .toList(growable: false),
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              _TextAreaField(
                                label: 'Description',
                                hintText:
                                    'Notes about condition, accessories, or packaging.',
                                controller: _descriptionController,
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: _formSectionSpacing),
                      AnimatedCrossFade(
                        duration: const Duration(milliseconds: 220),
                        firstCurve: Curves.easeInOutCubic,
                        secondCurve: Curves.easeInOutCubic,
                        sizeCurve: Curves.easeInOutCubic,
                        crossFadeState: _showFloatingSave
                            ? CrossFadeState.showFirst
                            : CrossFadeState.showSecond,
                        firstChild: const SizedBox.shrink(),
                        secondChild: _InlineSaveSection(
                          label: _primaryActionLabel,
                          isLoading: _isSaving,
                          onSave: _isDeleting ? null : _save,
                        ),
                      ),
                      if (_isEditing) ...[
                        const SizedBox(height: AppSpacing.lg),
                        _DeleteItemSection(
                          isDeleting: _isDeleting,
                          onDelete: _deleteItem,
                        ),
                      ],
                    ]),
                  ),
                ),
              ],
            ),
          ),
          CollectorStickyBackButton(
            onPressed: () => Navigator.of(context).pop(),
          ),
          Positioned(
            left: AppSpacing.md,
            right: AppSpacing.md,
            bottom: 0,
            child: IgnorePointer(
              ignoring: !_showFloatingSave,
              child: AnimatedSlide(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                offset: _showFloatingSave ? Offset.zero : const Offset(0, 1.1),
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  opacity: _showFloatingSave ? 1 : 0,
                  child: AnimatedPadding(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutCubic,
                    padding: EdgeInsets.only(
                      bottom: keyboardInset > 0
                          ? keyboardInset + AppSpacing.sm
                          : AppSpacing.md,
                    ),
                    child: SafeArea(
                      top: false,
                      child: _FloatingSaveBar(
                        label: _primaryActionLabel,
                        isLoading: _isSaving,
                        onSave: _isDeleting ? null : _save,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FloatingSaveBar extends StatelessWidget {
  const _FloatingSaveBar({
    required this.label,
    required this.isLoading,
    required this.onSave,
  });

  final String label;
  final bool isLoading;
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.22),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.32),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: CollectorButton(
          label: label,
          onPressed: onSave,
          isLoading: isLoading,
        ),
      ),
    );
  }
}

class _InlineSaveSection extends StatelessWidget {
  const _InlineSaveSection({
    required this.label,
    required this.isLoading,
    required this.onSave,
  });

  final String label;
  final bool isLoading;
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: CollectorButton(
        label: label,
        onPressed: onSave,
        isLoading: isLoading,
      ),
    );
  }
}

class _DeleteItemSection extends StatelessWidget {
  const _DeleteItemSection({required this.isDeleting, required this.onDelete});

  final bool isDeleting;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: AppColors.outlineVariant.withValues(alpha: 0.22),
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Delete item',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  'Removes it from your collection.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          TextButton.icon(
            onPressed: isDeleting ? null : onDelete,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.error,
              disabledForegroundColor: AppColors.error.withValues(alpha: 0.44),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            icon: isDeleting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.delete_outline_rounded, size: 18),
            label: Text(isDeleting ? 'Deleting...' : 'Delete'),
          ),
        ],
      ),
    );
  }
}

class _PhotoSection extends StatelessWidget {
  const _PhotoSection({
    required this.selectedImage,
    this.existingPhotoUrl,
    this.lookupImageUrl,
    required this.onEditPhoto,
  });

  final XFile? selectedImage;
  final String? existingPhotoUrl;
  final String? lookupImageUrl;
  final VoidCallback onEditPhoto;

  @override
  Widget build(BuildContext context) {
    final hasPhoto =
        selectedImage != null ||
        (existingPhotoUrl ?? '').trim().isNotEmpty ||
        (lookupImageUrl ?? '').trim().isNotEmpty;

    return Stack(
      children: [
        _PhotoPreview(
          selectedImage: selectedImage,
          existingPhotoUrl: existingPhotoUrl,
          lookupImageUrl: lookupImageUrl,
          height: 196,
          onAddPhoto: hasPhoto ? null : onEditPhoto,
        ),
        if (hasPhoto)
          Positioned(
            right: AppSpacing.md,
            bottom: AppSpacing.md,
            child: _PhotoOverlayAction(
              label: 'Update photo',
              icon: Icons.edit_outlined,
              onTap: onEditPhoto,
            ),
          )
        else
          const SizedBox.shrink(),
      ],
    );
  }
}

class _PhotoOverlayAction extends StatelessWidget {
  const _PhotoOverlayAction({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.pill,
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.48),
            borderRadius: AppRadii.pill,
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: Colors.white),
              const SizedBox(width: AppSpacing.xs),
              Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhotoPreview extends StatelessWidget {
  const _PhotoPreview({
    required this.selectedImage,
    this.existingPhotoUrl,
    this.lookupImageUrl,
    this.height = 220,
    this.onAddPhoto,
  });

  final XFile? selectedImage;
  final String? existingPhotoUrl;
  final String? lookupImageUrl;
  final double height;
  final VoidCallback? onAddPhoto;

  bool _isRemoteUrl(String value) {
    final parsed = Uri.tryParse(value);
    return parsed != null &&
        (parsed.scheme == 'http' || parsed.scheme == 'https');
  }

  Widget _buildExistingPhoto() {
    final existingPhotoUrl = this.existingPhotoUrl;
    if (existingPhotoUrl == null) {
      return const _PhotoPreviewEmpty();
    }

    if (_isRemoteUrl(existingPhotoUrl)) {
      return Image.network(
        existingPhotoUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => const _PhotoPreviewEmpty(),
      );
    }

    return Image.file(
      File(existingPhotoUrl),
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => const _PhotoPreviewEmpty(),
    );
  }

  Widget _buildEmptyState() {
    return _PhotoPreviewEmpty(onAddPhoto: onAddPhoto);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.22),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: selectedImage != null
            ? Image.file(File(selectedImage!.path), fit: BoxFit.cover)
            : existingPhotoUrl != null
            ? _buildExistingPhoto()
            : lookupImageUrl != null
            ? Image.network(
                lookupImageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _buildEmptyState(),
              )
            : _buildEmptyState(),
      ),
    );
  }
}

class _PhotoPreviewEmpty extends StatelessWidget {
  const _PhotoPreviewEmpty({this.onAddPhoto});

  final VoidCallback? onAddPhoto;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.add_a_photo_outlined,
          size: 54,
          color: AppColors.primary,
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'No photo selected yet',
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(color: AppColors.onSurfaceVariant),
        ),
        const SizedBox(height: AppSpacing.md),
        if (onAddPhoto != null)
          _PhotoOverlayAction(
            label: 'Add photo',
            icon: Icons.add_a_photo_outlined,
            onTap: onAddPhoto!,
          ),
      ],
    );
  }
}

class _SectionPanel extends StatelessWidget {
  const _SectionPanel({
    required this.eyebrow,
    required this.title,
    required this.description,
    required this.child,
  });

  final String eyebrow;
  final String title;
  final String description;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final hasEyebrow = eyebrow.trim().isNotEmpty;
    final hasDescription = description.trim().isNotEmpty;

    return CollectorPanel(
      padding: const EdgeInsets.all(AppSpacing.lg),
      backgroundColor: AppColors.surfaceContainer.withValues(alpha: 0.94),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasEyebrow) ...[
            Text(
              eyebrow.toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.primary,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          if (hasDescription) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: _formPanelContentSpacing),
          child,
        ],
      ),
    );
  }
}

class _ExpandableSectionPanel extends StatelessWidget {
  const _ExpandableSectionPanel({
    required this.eyebrow,
    required this.title,
    required this.description,
    required this.expanded,
    required this.onToggle,
    required this.child,
  });

  final String eyebrow;
  final String title;
  final String description;
  final bool expanded;
  final VoidCallback onToggle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final hasEyebrow = eyebrow.trim().isNotEmpty;
    final hasDescription = description.trim().isNotEmpty;

    return CollectorPanel(
      padding: const EdgeInsets.all(AppSpacing.lg),
      backgroundColor: AppColors.surfaceContainer.withValues(alpha: 0.94),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (hasEyebrow) ...[
                          Text(
                            eyebrow.toUpperCase(),
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: AppColors.primary,
                                  letterSpacing: 1.1,
                                ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                        ],
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        if (hasDescription) ...[
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            description,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: AppColors.onSurfaceVariant),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Icon(
                    expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: AppColors.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.only(top: _formPanelContentSpacing),
              child: child,
            ),
            crossFadeState: expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 180),
          ),
        ],
      ),
    );
  }
}

class _ScannedBarcodeBanner extends StatelessWidget {
  const _ScannedBarcodeBanner({required this.barcode});

  final String barcode;

  @override
  Widget build(BuildContext context) {
    return CollectorPanel(
      padding: const EdgeInsets.all(AppSpacing.md),
      backgroundColor: AppColors.surfaceContainer.withValues(alpha: 0.88),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.qr_code_rounded, color: AppColors.primary),
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

class _SelectionField extends StatelessWidget {
  const _SelectionField({
    required this.label,
    required this.value,
    required this.helperText,
    required this.actionLabel,
    required this.onTap,
    this.errorText,
    this.isPlaceholder = false,
    this.footer,
    this.compact = false,
    this.showActionLabel = true,
    this.showHelperWhenSelected = true,
  });

  final String label;
  final String value;
  final String helperText;
  final String actionLabel;
  final VoidCallback onTap;
  final String? errorText;
  final bool isPlaceholder;
  final Widget? footer;
  final bool compact;
  final bool showActionLabel;
  final bool showHelperWhenSelected;

  @override
  Widget build(BuildContext context) {
    final showHelper =
        (errorText ?? '').isNotEmpty ||
        helperText.trim().isNotEmpty &&
            (showHelperWhenSelected || isPlaceholder);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: AppColors.onSurfaceVariant),
        ),
        const SizedBox(height: AppSpacing.xs),
        InkWell(
          onTap: onTap,
          borderRadius: AppRadii.medium,
          child: Ink(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: compact ? AppSpacing.sm : AppSpacing.md,
            ),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHighest.withValues(alpha: 0.4),
              borderRadius: AppRadii.medium,
              border: Border.all(
                color: (errorText ?? '').isNotEmpty
                    ? AppColors.error.withValues(alpha: 0.6)
                    : AppColors.outlineVariant.withValues(alpha: 0.22),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            (compact
                                    ? Theme.of(context).textTheme.titleMedium
                                    : Theme.of(context).textTheme.titleSmall)
                                ?.copyWith(
                                  color: isPlaceholder
                                      ? AppColors.onSurfaceVariant
                                      : AppColors.onSurface,
                                ),
                      ),
                      if (showHelper) ...[
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          errorText ?? helperText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: (errorText ?? '').isNotEmpty
                                    ? AppColors.error
                                    : AppColors.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (showActionLabel) ...[
                        Text(
                          actionLabel,
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(color: AppColors.primary),
                        ),
                        const SizedBox(width: AppSpacing.xxs),
                      ],
                      const Icon(
                        Icons.chevron_right_rounded,
                        size: 20,
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        if (footer != null) ...[footer!],
      ],
    );
  }
}

class _EditableTagChip extends StatelessWidget {
  const _EditableTagChip({required this.label, required this.onRemove});

  final String label;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final maxChipWidth = MediaQuery.sizeOf(context).width * 0.72;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onRemove,
        borderRadius: AppRadii.pill,
        child: Ink(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxChipWidth),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer.withValues(alpha: 0.16),
                borderRadius: AppRadii.pill,
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.22),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.primary,
                        fontSize: 10,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  const Icon(
                    Icons.close_rounded,
                    size: 14,
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PhotoSourceBottomSheet extends StatelessWidget {
  const _PhotoSourceBottomSheet();

  @override
  Widget build(BuildContext context) {
    return _SelectionBottomSheetShell(
      title: 'Update photo',
      description: 'Take a fresh photo or choose one from your library.',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _SheetActionRow(
            label: 'Take photo',
            icon: Icons.camera_alt_outlined,
            onTap: () => Navigator.of(context).pop(ImageSource.camera),
          ),
          const SizedBox(height: AppSpacing.xs),
          _SheetActionRow(
            label: 'Photo library',
            icon: Icons.photo_library_outlined,
            onTap: () => Navigator.of(context).pop(ImageSource.gallery),
          ),
        ],
      ),
    );
  }
}

class _TextAreaField extends StatefulWidget {
  const _TextAreaField({
    required this.label,
    required this.hintText,
    required this.controller,
  });

  final String label;
  final String hintText;
  final TextEditingController controller;

  @override
  State<_TextAreaField> createState() => _TextAreaFieldState();
}

class _TextAreaFieldState extends State<_TextAreaField> {
  late final FocusNode _focusNode;

  bool get _shouldShowClearButton {
    return _focusNode.hasFocus && widget.controller.text.isNotEmpty;
  }

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(_handleInputStateChanged);
    widget.controller.addListener(_handleInputStateChanged);
  }

  @override
  void didUpdateWidget(covariant _TextAreaField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller == widget.controller) {
      return;
    }

    oldWidget.controller.removeListener(_handleInputStateChanged);
    widget.controller.addListener(_handleInputStateChanged);
  }

  @override
  void dispose() {
    _focusNode
      ..removeListener(_handleInputStateChanged)
      ..dispose();
    widget.controller.removeListener(_handleInputStateChanged);
    super.dispose();
  }

  void _handleInputStateChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _clearText() {
    widget.controller.clear();
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall,
        ),
        const SizedBox(height: AppSpacing.xs),
        TextField(
          controller: widget.controller,
          focusNode: _focusNode,
          minLines: 3,
          maxLines: 5,
          textInputAction: TextInputAction.newline,
          onTapOutside: (_) => _focusNode.unfocus(),
          decoration: InputDecoration(
            hintText: widget.hintText,
            alignLabelWithHint: true,
            suffixIcon: _shouldShowClearButton
                ? IconButton(
                    tooltip: 'Clear',
                    onPressed: _clearText,
                    icon: const Icon(Icons.close_rounded, size: 18),
                    color: AppColors.onSurfaceVariant,
                  )
                : null,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
            enabledBorder: const OutlineInputBorder(
              borderRadius: AppRadii.medium,
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: AppRadii.medium,
              borderSide: BorderSide(
                color: AppColors.primary.withValues(alpha: 0.5),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _OptionSearchBottomSheet extends StatefulWidget {
  const _OptionSearchBottomSheet({
    required this.title,
    required this.description,
    required this.searchHint,
    required this.options,
    required this.selectedValue,
    required this.createActionLabel,
    required this.createFieldLabel,
    required this.createFieldHint,
    required this.createSubmitLabel,
    this.pinnedOption,
    this.initialCreateValue = '',
    this.emptyStateLabel,
  });

  final String title;
  final String description;
  final String searchHint;
  final List<String> options;
  final String? selectedValue;
  final String createActionLabel;
  final String createFieldLabel;
  final String createFieldHint;
  final String createSubmitLabel;
  final String? pinnedOption;
  final String initialCreateValue;
  final String? emptyStateLabel;

  @override
  State<_OptionSearchBottomSheet> createState() =>
      _OptionSearchBottomSheetState();
}

class _OptionSearchBottomSheetState extends State<_OptionSearchBottomSheet> {
  final _searchController = TextEditingController();
  late final TextEditingController _createController;
  String _query = '';
  String? _createErrorText;
  var _showCreatePanel = false;

  @override
  void initState() {
    super.initState();
    _createController = TextEditingController(text: widget.initialCreateValue);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _createController.dispose();
    super.dispose();
  }

  void _showCreate() {
    setState(() {
      _showCreatePanel = true;
      _createErrorText = null;
      if (_createController.text.trim().isEmpty && _query.trim().isNotEmpty) {
        _createController.text = _query.trim();
      }
    });
  }

  void _submitCreatedValue(List<String> normalizedOptions) {
    final value = _createController.text.trim();
    if (value.isEmpty) {
      setState(() {
        _createErrorText = '${widget.createFieldLabel} is required.';
      });
      return;
    }

    final existingValue = normalizedOptions.cast<String?>().firstWhere(
      (option) => (option ?? '').trim().toLowerCase() == value.toLowerCase(),
      orElse: () => null,
    );

    Navigator.of(context).pop(existingValue ?? value);
  }

  @override
  Widget build(BuildContext context) {
    final normalizedOptions = <String>[];
    final seenOptions = <String>{};
    for (final option in widget.options) {
      final trimmed = option.trim();
      final normalized = trimmed.toLowerCase();
      if (trimmed.isNotEmpty && seenOptions.add(normalized)) {
        normalizedOptions.add(trimmed);
      }
    }
    final pinnedOption = widget.pinnedOption?.trim();
    final showPinnedOption =
        (pinnedOption ?? '').isNotEmpty &&
        (_query.trim().isEmpty ||
            pinnedOption!.toLowerCase().contains(_query.trim().toLowerCase()));
    final filteredOptions = normalizedOptions
        .where((option) {
          final matchesQuery =
              _query.trim().isEmpty ||
              option.toLowerCase().contains(_query.trim().toLowerCase());
          final duplicatesPinned =
              showPinnedOption &&
              option.toLowerCase() == pinnedOption!.toLowerCase();
          return matchesQuery && !duplicatesPinned;
        })
        .toList(growable: false);

    return _SelectionBottomSheetShell(
      title: widget.title,
      description: widget.description,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CollectorSearchField(
            hintText: widget.searchHint,
            controller: _searchController,
            readOnly: false,
            onChanged: (value) {
              setState(() {
                _query = value;
              });
            },
          ),
          const SizedBox(height: AppSpacing.md),
          _SheetActionRow(
            label: widget.createActionLabel,
            icon: Icons.add_rounded,
            onTap: _showCreate,
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            child: _showCreatePanel
                ? Padding(
                    key: const ValueKey('create-option-panel'),
                    padding: const EdgeInsets.only(top: AppSpacing.sm),
                    child: _InlineCreatePanel(
                      fieldLabel: widget.createFieldLabel,
                      fieldHint: widget.createFieldHint,
                      submitLabel: widget.createSubmitLabel,
                      controller: _createController,
                      errorText: _createErrorText,
                      onSubmit: () => _submitCreatedValue(normalizedOptions),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (showPinnedOption) ...[
            _SheetSelectableRow(
              label: pinnedOption!,
              selected: widget.selectedValue == pinnedOption,
              leadingIcon: Icons.history_rounded,
              onTap: () => Navigator.of(context).pop(pinnedOption),
            ),
            const SizedBox(height: AppSpacing.xs),
          ],
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 320),
            child: filteredOptions.isEmpty && !showPinnedOption
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Text(
                        widget.emptyStateLabel ?? 'No matches yet',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  )
                : filteredOptions.isEmpty
                ? const SizedBox.shrink()
                : ListView.separated(
                    shrinkWrap: true,
                    itemCount: filteredOptions.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.xs),
                    itemBuilder: (context, index) {
                      final option = filteredOptions[index];
                      final isSelected = widget.selectedValue == option;
                      return _SheetSelectableRow(
                        label: option,
                        selected: isSelected,
                        onTap: () => Navigator.of(context).pop(option),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _TagSearchBottomSheet extends StatefulWidget {
  const _TagSearchBottomSheet({
    required this.availableTags,
    required this.selectedTagIds,
    required this.newTagNames,
  });

  final List<TagModel> availableTags;
  final Set<String> selectedTagIds;
  final List<String> newTagNames;

  @override
  State<_TagSearchBottomSheet> createState() => _TagSearchBottomSheetState();
}

class _TagSearchBottomSheetState extends State<_TagSearchBottomSheet> {
  final _searchController = TextEditingController();
  final _createController = TextEditingController();
  late final Set<String> _workingSelection = {...widget.selectedTagIds};
  late final List<String> _workingNewTagNames = [...widget.newTagNames];
  String _query = '';
  String? _createErrorText;
  var _showCreatePanel = false;

  @override
  void dispose() {
    _searchController.dispose();
    _createController.dispose();
    super.dispose();
  }

  void _showCreate() {
    setState(() {
      _showCreatePanel = true;
      _createErrorText = null;
      if (_createController.text.trim().isEmpty && _query.trim().isNotEmpty) {
        _createController.text = _query.trim();
      }
    });
  }

  void _submitCreatedTag() {
    final value = _createController.text.trim();
    if (value.isEmpty) {
      setState(() {
        _createErrorText = 'Tag name is required.';
      });
      return;
    }

    TagModel? existingTag;
    for (final tag in widget.availableTags) {
      if (tag.name.trim().toLowerCase() == value.toLowerCase()) {
        existingTag = tag;
        break;
      }
    }

    setState(() {
      final existingTagId = existingTag?.id;
      if (existingTagId != null && existingTagId.isNotEmpty) {
        _workingSelection.add(existingTagId);
      } else if (!_workingNewTagNames.any(
        (tagName) => tagName.toLowerCase() == value.toLowerCase(),
      )) {
        _workingNewTagNames.add(value);
      }

      _createController.clear();
      _createErrorText = null;
      _query = '';
      _searchController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final filteredTags =
        widget.availableTags
            .where((tag) {
              final tagName = tag.name.trim().toLowerCase();
              return _query.trim().isEmpty ||
                  tagName.contains(_query.trim().toLowerCase());
            })
            .toList(growable: false)
          ..sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
          );

    return _SelectionBottomSheetShell(
      title: 'Choose tags',
      description:
          'Search, toggle, or create tags without opening a giant chip wall.',
      footer: SizedBox(
        width: double.infinity,
        child: CollectorButton(
          label: 'Apply tags',
          onPressed: () => Navigator.of(context).pop(
            _TagPickerSheetResult.apply(_workingSelection, _workingNewTagNames),
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CollectorSearchField(
            hintText: 'Search tags',
            controller: _searchController,
            readOnly: false,
            onChanged: (value) {
              setState(() {
                _query = value;
              });
            },
          ),
          const SizedBox(height: AppSpacing.md),
          _SheetActionRow(
            label: 'Create tag',
            icon: Icons.add_rounded,
            onTap: _showCreate,
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            child: _showCreatePanel
                ? Padding(
                    key: const ValueKey('create-tag-panel'),
                    padding: const EdgeInsets.only(top: AppSpacing.sm),
                    child: _InlineCreatePanel(
                      fieldLabel: 'Tag name',
                      fieldHint: 'Display shelf',
                      submitLabel: 'Add tag',
                      controller: _createController,
                      errorText: _createErrorText,
                      onSubmit: _submitCreatedTag,
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (_workingNewTagNames.isNotEmpty) ...[
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 150),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _workingNewTagNames.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: AppSpacing.xs),
                itemBuilder: (context, index) {
                  final tagName = _workingNewTagNames[index];
                  return _SheetSelectableRow(
                    label: tagName,
                    selected: true,
                    leadingIcon: Icons.new_label_outlined,
                    onTap: () {
                      setState(() {
                        _workingNewTagNames.removeAt(index);
                      });
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 320),
            child: filteredTags.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Text(
                        'No saved tags match this search.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    itemCount: filteredTags.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.xs),
                    itemBuilder: (context, index) {
                      final tag = filteredTags[index];
                      final tagId = tag.id;
                      if (tagId == null || tagId.isEmpty) {
                        return const SizedBox.shrink();
                      }
                      final isSelected = _workingSelection.contains(tagId);
                      return _SheetSelectableRow(
                        label: tag.name,
                        selected: isSelected,
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _workingSelection.remove(tagId);
                            } else {
                              _workingSelection.add(tagId);
                            }
                          });
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _TagPickerSheetResult {
  const _TagPickerSheetResult({
    required this.selectedTagIds,
    required this.newTagNames,
  });

  factory _TagPickerSheetResult.apply(
    Set<String> selectedTagIds,
    List<String> newTagNames,
  ) {
    return _TagPickerSheetResult(
      selectedTagIds: {...selectedTagIds},
      newTagNames: [...newTagNames],
    );
  }

  final Set<String> selectedTagIds;
  final List<String> newTagNames;
}

class _SelectionBottomSheetShell extends StatelessWidget {
  const _SelectionBottomSheetShell({
    required this.title,
    required this.description,
    required this.child,
    this.footer,
  });

  final String title;
  final String description;
  final Widget child;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return CollectorBottomSheet(
      title: title,
      description: description,
      footer: footer,
      child: child,
    );
  }
}

class _SheetActionRow extends StatelessWidget {
  const _SheetActionRow({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _SheetSelectableRow(
      label: label,
      selected: false,
      leadingIcon: icon,
      onTap: onTap,
    );
  }
}

class _InlineCreatePanel extends StatelessWidget {
  const _InlineCreatePanel({
    required this.fieldLabel,
    required this.fieldHint,
    required this.submitLabel,
    required this.controller,
    required this.onSubmit,
    this.errorText,
  });

  final String fieldLabel;
  final String fieldHint;
  final String submitLabel;
  final TextEditingController controller;
  final VoidCallback onSubmit;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHighest.withValues(alpha: 0.36),
        borderRadius: AppRadii.medium,
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.24)),
      ),
      child: Column(
        children: [
          CollectorTextField(
            label: fieldLabel,
            hintText: fieldHint,
            controller: controller,
            errorText: errorText,
            textInputAction: TextInputAction.done,
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: CollectorButton(
              label: submitLabel,
              onPressed: onSubmit,
              variant: CollectorButtonVariant.secondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetSelectableRow extends StatelessWidget {
  const _SheetSelectableRow({
    required this.label,
    required this.selected,
    required this.onTap,
    this.leadingIcon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? leadingIcon;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.medium,
        child: Ink(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.12)
                : AppColors.surfaceContainer,
            borderRadius: AppRadii.medium,
            border: Border.all(
              color: selected
                  ? AppColors.primary.withValues(alpha: 0.4)
                  : AppColors.outlineVariant.withValues(alpha: 0.18),
            ),
          ),
          child: Row(
            children: [
              if (leadingIcon != null) ...[
                Icon(leadingIcon, color: AppColors.primary, size: 18),
                const SizedBox(width: AppSpacing.sm),
              ],
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.chevron_right_rounded,
                color: selected
                    ? AppColors.primary
                    : AppColors.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BasicsDivider extends StatelessWidget {
  const _BasicsDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 1,
      color: AppColors.onSurfaceVariant.withValues(alpha: 0.24),
    );
  }
}

class _SingleSelectChoiceChip extends StatelessWidget {
  const _SingleSelectChoiceChip({
    required this.label,
    this.tone = _ChipTone.neutral,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final _ChipTone tone;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = _chipPaletteForTone(tone);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? palette.selectedBackground : palette.background,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? palette.selectedBorder : palette.border,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected
                      ? palette.selectedForeground
                      : Colors.transparent,
                  border: Border.all(
                    color: selected
                        ? palette.selectedForeground
                        : palette.border,
                  ),
                ),
                child: selected
                    ? Icon(
                        Icons.check_rounded,
                        size: 12,
                        color: AppColors.background,
                      )
                    : null,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: selected
                      ? palette.selectedForeground
                      : palette.foreground,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _ChipTone { neutral, category, brand, tag }

class _ChipPalette {
  const _ChipPalette({
    required this.background,
    required this.border,
    required this.foreground,
    required this.selectedBackground,
    required this.selectedBorder,
    required this.selectedForeground,
  });

  final Color background;
  final Color border;
  final Color foreground;
  final Color selectedBackground;
  final Color selectedBorder;
  final Color selectedForeground;
}

_ChipPalette _chipPaletteForTone(_ChipTone tone) {
  switch (tone) {
    case _ChipTone.category:
      return _ChipPalette(
        background: AppColors.primary.withValues(alpha: 0.08),
        border: AppColors.primary.withValues(alpha: 0.18),
        foreground: AppColors.primary.withValues(alpha: 0.9),
        selectedBackground: AppColors.primary.withValues(alpha: 0.18),
        selectedBorder: AppColors.primary.withValues(alpha: 0.34),
        selectedForeground: AppColors.primary,
      );
    case _ChipTone.brand:
      return _ChipPalette(
        background: AppColors.secondary.withValues(alpha: 0.08),
        border: AppColors.secondary.withValues(alpha: 0.18),
        foreground: AppColors.secondary.withValues(alpha: 0.9),
        selectedBackground: AppColors.secondary.withValues(alpha: 0.16),
        selectedBorder: AppColors.secondary.withValues(alpha: 0.3),
        selectedForeground: AppColors.secondary,
      );
    case _ChipTone.tag:
      return _ChipPalette(
        background: AppColors.tertiary.withValues(alpha: 0.08),
        border: AppColors.tertiary.withValues(alpha: 0.18),
        foreground: AppColors.tertiary.withValues(alpha: 0.9),
        selectedBackground: AppColors.tertiary.withValues(alpha: 0.16),
        selectedBorder: AppColors.tertiary.withValues(alpha: 0.3),
        selectedForeground: AppColors.tertiary,
      );
    case _ChipTone.neutral:
      return _ChipPalette(
        background: AppColors.surfaceContainerHighest,
        border: AppColors.outlineVariant.withValues(alpha: 0.22),
        foreground: AppColors.onSurfaceVariant,
        selectedBackground: AppColors.primary.withValues(alpha: 0.16),
        selectedBorder: AppColors.primary.withValues(alpha: 0.35),
        selectedForeground: AppColors.primary,
      );
  }
}

class _BoxStatusOption {
  const _BoxStatusOption({required this.label, required this.value});

  final String label;
  final String value;
}
