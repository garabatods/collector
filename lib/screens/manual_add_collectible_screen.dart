import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

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
import '../widgets/collector_button.dart';
import '../widgets/collector_panel.dart';
import '../widgets/collector_text_field.dart';

const _formHeaderBottomSpacing = AppSpacing.xl;
const _formSectionSpacing = 40.0;
const _formPanelContentSpacing = AppSpacing.md;
const _visibleSuggestionCount = 5;
const _createValueSentinel = '__create_value__';

class ManualAddCollectibleScreen extends StatefulWidget {
  const ManualAddCollectibleScreen({
    super.key,
    this.collectible,
    this.existingPhotoUrl,
    this.scannedBarcode,
    this.identificationResult,
    this.autofillResult,
    this.initialImage,
    this.selectedTagIds,
    this.newTagNames,
  });

  final CollectibleModel? collectible;
  final String? existingPhotoUrl;
  final String? scannedBarcode;
  final CollectibleIdentificationResult? identificationResult;
  final AddItemAutofillResult? autofillResult;
  final XFile? initialImage;
  final List<String>? selectedTagIds;
  final List<String>? newTagNames;

  @override
  State<ManualAddCollectibleScreen> createState() =>
      _ManualAddCollectibleScreenState();
}

class _ManualAddCollectibleScreenState
    extends State<ManualAddCollectibleScreen> {
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

  static const List<String> _conditionOptions = [
    'Mint',
    'Excellent',
    'Good',
    'Fair',
    'Poor',
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

  XFile? _selectedImage;
  String? _selectedCategory;
  String? _selectedBrand;
  bool _useCustomCategory = false;
  bool _useCustomBrand = false;
  bool _detailsExpanded = false;
  bool _organizationExpanded = false;
  String? _selectedCondition;
  String? _selectedBoxStatus;
  int _quantity = 1;
  bool _isFavorite = false;
  bool _isGrail = false;
  bool _isDuplicate = false;
  bool _isSaving = false;
  String? _titleError;
  String? _categoryError;
  List<String> _topBrands = const [];
  List<String> _moreBrands = const [];
  List<TagModel> _availableTags = const [];
  final Set<String> _selectedTagIds = <String>{};
  final List<String> _newTagNames = <String>[];
  late AddItemFormMode _formMode;

  bool get _isEditing => widget.collectible != null;
  bool get _isComicMode => _formMode == AddItemFormMode.comic;

  @override
  void initState() {
    super.initState();
    _formMode = _resolveInitialFormMode();
    _hydrateFromCollectible();
  }

  @override
  void dispose() {
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
    _organizationExpanded =
        _selectedTagIds.isNotEmpty || _newTagNames.isNotEmpty;
    _loadSuggestions();
  }

  void _hydrateFromIdentification() {
    final identificationResult = widget.identificationResult;
    if (identificationResult == null) {
      return;
    }

    if (_titleController.text.trim().isEmpty) {
      _titleController.text = identificationResult.title;
    }

    final suggestedCategory = identificationResult.suggestedCategory;
    if (suggestedCategory != null && suggestedCategory.isNotEmpty) {
      if (_topCategories.contains(suggestedCategory)) {
        _selectedCategory = suggestedCategory;
        _useCustomCategory = false;
      } else if (_moreCategories.contains(suggestedCategory)) {
        _selectedCategory = suggestedCategory;
        _useCustomCategory = false;
      } else {
        _customCategoryController.text = suggestedCategory;
        _useCustomCategory = true;
      }
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
          identificationResult.volumeCandidate ??
          identificationResult.series ??
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
      _organizationExpanded =
          _selectedTagIds.isNotEmpty || _newTagNames.isNotEmpty;
      return;
    }

    _formMode = autofillResult.formMode;
    _setIfEmpty(_titleController, autofillResult.title);
    _setIfEmpty(_descriptionController, autofillResult.description);
    _setIfEmpty(_franchiseController, autofillResult.franchise);
    _setIfEmpty(_seriesController, autofillResult.seriesOrVolume);
    _setIfEmpty(_characterController, autofillResult.characterOrSubject);
    _setIfEmpty(_releaseYearController, autofillResult.releaseYear?.toString());
    _setIfEmpty(_issueNumberController, autofillResult.issueNumber);

    _applyResolvedCategory(autofillResult.category);
    _applyResolvedBrand(autofillResult.brandOrPublisher);
    _applyTagSuggestions(autofillResult);

    _detailsExpanded = _hasVisibleMetadata();
    _organizationExpanded =
        _selectedTagIds.isNotEmpty || _newTagNames.isNotEmpty;
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

      final counts = <String, int>{};
      for (final item in collectibles) {
        final brand = (item.brand ?? '').trim();
        if (brand.isEmpty) {
          continue;
        }

        counts.update(brand, (value) => value + 1, ifAbsent: () => 1);
      }

      final sortedBrands = counts.entries.toList()
        ..sort((a, b) {
          final byCount = b.value.compareTo(a.value);
          return byCount == 0 ? a.key.compareTo(b.key) : byCount;
        });

      final brands = sortedBrands
          .map((entry) => entry.key)
          .toList(growable: false);
      final topBrands = brands
          .take(_visibleSuggestionCount)
          .toList(growable: false);
      final moreBrands = brands
          .skip(_visibleSuggestionCount)
          .toList(growable: false);
      final pendingBrand = (_selectedBrand ?? '').trim();

      setState(() {
        _topBrands = topBrands;
        _moreBrands = moreBrands;
        _availableTags = tags;

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
    setState(() {
      _useCustomCategory = false;
      _selectedCategory = category;
      _customCategoryController.clear();
      _categoryError = null;
    });
  }

  Future<void> _openCustomCategorySheet() async {
    final value = await _showValueInputSheet(
      title: 'Add category',
      description: 'Create a category when the preset list does not fit.',
      fieldLabel: 'Category name',
      fieldHint: 'Vintage posters',
      submitLabel: 'Save category',
      initialValue: _useCustomCategory ? _customCategoryController.text : '',
    );

    if (!mounted || value == null) {
      return;
    }

    setState(() {
      _customCategoryController.text = value;
      _useCustomCategory = true;
      _selectedCategory = null;
      _categoryError = null;
    });
  }

  void _selectBrand(String brand) {
    setState(() {
      _useCustomBrand = false;
      _selectedBrand = brand;
      _customBrandController.clear();
    });
  }

  Future<void> _openCustomBrandSheet() async {
    final value = await _showValueInputSheet(
      title: _isComicMode ? 'Add publisher' : 'Add brand',
      description: _isComicMode
          ? 'Create a publisher when the saved suggestions do not fit.'
          : 'Create a brand when the saved suggestions do not fit.',
      fieldLabel: _isComicMode ? 'Publisher name' : 'Brand name',
      fieldHint: _isComicMode ? 'IDW Publishing' : 'McFarlane Toys',
      submitLabel: _isComicMode ? 'Save publisher' : 'Save brand',
      initialValue: _useCustomBrand ? _customBrandController.text : '',
    );

    if (!mounted || value == null) {
      return;
    }

    final existingBrand = [..._topBrands, ..._moreBrands]
        .cast<String?>()
        .firstWhere(
          (brand) => (brand ?? '').trim().toLowerCase() == value.toLowerCase(),
          orElse: () => null,
        );

    setState(() {
      _selectedBrand = existingBrand ?? value;
      _useCustomBrand = existingBrand == null;
      _customBrandController.text = existingBrand ?? value;
    });
  }

  void _toggleDetailsExpanded() {
    setState(() {
      _detailsExpanded = !_detailsExpanded;
    });
  }

  void _toggleOrganizationExpanded() {
    setState(() {
      _organizationExpanded = !_organizationExpanded;
    });
  }

  void _toggleCollectorState(CollectorState collectorState) {
    setState(() {
      switch (collectorState) {
        case CollectorState.favorite:
          _isFavorite = !_isFavorite;
          break;
        case CollectorState.grail:
          _isGrail = !_isGrail;
          break;
        case CollectorState.duplicate:
          _isDuplicate = !_isDuplicate;
          break;
      }
    });
  }

  void _removeSelectedTagId(String tagId) {
    setState(() {
      _selectedTagIds.remove(tagId);
    });
  }

  void _removeNewTag(String tagName) {
    setState(() {
      _newTagNames.remove(tagName);
    });
  }

  Future<void> _openCreateTagSheet() async {
    final value = await _showValueInputSheet(
      title: 'Create a new tag',
      description: 'Tags help you group the same collectible in multiple ways.',
      fieldLabel: 'Tag name',
      fieldHint: 'Display shelf',
      submitLabel: 'Add tag',
    );

    if (!mounted || value == null) {
      return;
    }

    _addCustomTagValue(value);
  }

  void _addCustomTagValue(String value) {
    if (value.isEmpty) {
      return;
    }

    TagModel? existingTag;
    for (final tag in _availableTags) {
      if (tag.name.trim().toLowerCase() == value.toLowerCase()) {
        existingTag = tag;
        break;
      }
    }

    setState(() {
      if (existingTag != null) {
        final existingId = existingTag.id;
        if (existingId != null && existingId.isNotEmpty) {
          _selectedTagIds.add(existingId);
        }
      } else if (!_newTagNames.any(
        (tagName) => tagName.toLowerCase() == value.toLowerCase(),
      )) {
        _newTagNames.add(value);
      }
    });
  }

  Future<String?> _showValueInputSheet({
    required String title,
    required String description,
    required String fieldLabel,
    required String fieldHint,
    required String submitLabel,
    String initialValue = '',
  }) async {
    return showModalBottomSheet<String>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _ValueInputBottomSheet(
          title: title,
          description: description,
          fieldLabel: fieldLabel,
          fieldHint: fieldHint,
          submitLabel: submitLabel,
          initialValue: initialValue,
        );
      },
    );
  }

  Future<void> _openCategorySelectorSheet() async {
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
        selectedValue: _useCustomCategory ? null : _selectedCategory,
        createActionLabel: 'Create category',
      ),
    );

    if (!mounted || selected == null) {
      return;
    }

    if (selected == _createValueSentinel) {
      await _openCustomCategorySheet();
      return;
    }

    _selectCategory(selected);
  }

  Future<void> _openBrandSelectorSheet() async {
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
        emptyStateLabel: _brandEmptyLabel,
      ),
    );

    if (!mounted || selected == null) {
      return;
    }

    if (selected == _createValueSentinel) {
      await _openCustomBrandSheet();
      return;
    }

    _selectBrand(selected);
  }

  Future<void> _openSavedTagsPickerSheet() async {
    final selectedIds = await showModalBottomSheet<Set<String>>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _TagSearchBottomSheet(
        availableTags: _availableTags,
        selectedTagIds: _selectedTagIds,
      ),
    );

    if (!mounted || selectedIds == null) {
      return;
    }

    setState(() {
      _selectedTagIds
        ..clear()
        ..addAll(selectedIds);
    });
  }

  void _adjustQuantity(int delta) {
    setState(() {
      _quantity = (_quantity + delta).clamp(1, 999);
    });
  }

  String _resolvedCategory() {
    if (_isComicMode) {
      final resolvedComicCategory = (_selectedCategory ?? '').trim();
      if (resolvedComicCategory.isNotEmpty) {
        return resolvedComicCategory;
      }
      final customComicCategory = _customCategoryController.text.trim();
      return customComicCategory.isEmpty ? 'Comics' : customComicCategory;
    }

    if (_useCustomCategory) {
      return _customCategoryController.text.trim();
    }

    return (_selectedCategory ?? '').trim();
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

  String? _nullableText(TextEditingController controller) {
    final value = controller.text.trim();
    return value.isEmpty ? null : value;
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

  void _applyResolvedCategory(ResolvedMatch<String>? resolvedMatch) {
    final value = resolvedMatch?.resolvedValue?.trim();
    if (value == null || value.isEmpty) {
      return;
    }

    if (resolvedMatch!.hasExistingMatch) {
      _selectedCategory = value;
      _useCustomCategory = false;
      _customCategoryController.clear();
      return;
    }

    _selectedCategory = null;
    _useCustomCategory = true;
    _customCategoryController.text = value;
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
    return _descriptionController.text.trim().isNotEmpty ||
        _franchiseController.text.trim().isNotEmpty ||
        _seriesController.text.trim().isNotEmpty ||
        _characterController.text.trim().isNotEmpty ||
        _releaseYearController.text.trim().isNotEmpty ||
        _issueNumberController.text.trim().isNotEmpty ||
        _selectedCondition != null ||
        _selectedBoxStatus != null;
  }

  String get _screenTitle {
    if (_isEditing) {
      return _isComicMode ? 'Edit comic.' : 'Edit item.';
    }
    return _isComicMode ? 'Add a comic.' : 'Add an item.';
  }

  String get _screenDescription {
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

  String get _seriesFieldLabel =>
      _isComicMode ? 'Series / Volume' : 'Line / Series';

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

      CollectionVocabularyRepository.invalidateCache();
      Navigator.of(context).pop(true);

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            selectedImage == null
                ? _isEditing
                      ? 'Collectible updated.'
                      : 'Collectible added.'
                : photoUploadFailed
                ? _isEditing
                      ? 'Collectible updated, but the photo could not be uploaded.'
                      : 'Collectible added, but the photo could not be uploaded.'
                : _isEditing
                ? 'Collectible and photo updated.'
                : 'Collectible and photo added.',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not add the collectible right now. Please try again.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedImage = _selectedImage;

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
                        CollectorButton(
                          label: 'Back',
                          onPressed: () => Navigator.of(context).pop(),
                          variant: CollectorButtonVariant.icon,
                          icon: Icons.arrow_back_rounded,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          _screenTitle,
                          style: Theme.of(context).textTheme.headlineLarge,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          _screenDescription,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppColors.onSurfaceVariant),
                        ),
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
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    0,
                    AppSpacing.md,
                    140,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _SectionPanel(
                        eyebrow: 'Photo',
                        title: 'Add a photo',
                        description: 'Optional, but helpful.',
                        child: Column(
                          children: [
                            _PhotoPreview(
                              selectedImage: selectedImage,
                              existingPhotoUrl: widget.existingPhotoUrl,
                              lookupImageUrl:
                                  widget.identificationResult?.imageUrl,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Row(
                              children: [
                                Expanded(
                                  child: _ActionTileButton(
                                    icon: Icons.camera_alt_outlined,
                                    label: 'Take photo',
                                    onTap: () => _pickImage(ImageSource.camera),
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: _ActionTileButton(
                                    icon: Icons.photo_library_outlined,
                                    label: 'Photo library',
                                    onTap: () =>
                                        _pickImage(ImageSource.gallery),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: _formSectionSpacing),
                      _SectionPanel(
                        eyebrow: 'Basics',
                        title: _isComicMode
                            ? 'Comic essentials'
                            : 'Just enough to save it',
                        description: _isComicMode
                            ? 'Lead with the issue details, then refine the rest below.'
                            : 'Save the essentials first. Everything else can wait.',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CollectorTextField(
                              label: 'Title',
                              hintText: _isComicMode
                                  ? 'Teenage Mutant Ninja Turtles #4'
                                  : 'Vintage Batman figure',
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
                                helperText: 'Detected from identification',
                                errorText: _categoryError,
                                actionLabel: 'Locked',
                                onTap: () {},
                                isPlaceholder: false,
                                enabled: false,
                              ),
                              const SizedBox(height: AppSpacing.md),
                              const _BasicsDivider(),
                              const SizedBox(height: AppSpacing.md),
                              CollectorTextField(
                                label: 'Series / Volume',
                                hintText: 'Teenage Mutant Ninja Turtles',
                                controller: _seriesController,
                                textInputAction: TextInputAction.next,
                              ),
                              const SizedBox(height: AppSpacing.md),
                              const _BasicsDivider(),
                              const SizedBox(height: AppSpacing.md),
                              CollectorTextField(
                                label: 'Issue number',
                                hintText: '4',
                                controller: _issueNumberController,
                                keyboardType: TextInputType.number,
                                textInputAction: TextInputAction.next,
                              ),
                              const SizedBox(height: AppSpacing.md),
                              const _BasicsDivider(),
                              const SizedBox(height: AppSpacing.md),
                              _SelectionField(
                                label: _brandFieldLabel,
                                value: _resolvedBrandDisplayValue(),
                                helperText: _brandFieldHelperText,
                                actionLabel: 'Choose',
                                onTap: _openBrandSelectorSheet,
                                isPlaceholder: (_resolvedBrand() ?? '')
                                    .trim()
                                    .isEmpty,
                              ),
                              const SizedBox(height: AppSpacing.md),
                              const _BasicsDivider(),
                              const SizedBox(height: AppSpacing.md),
                              CollectorTextField(
                                label: 'Release year',
                                hintText: '1985',
                                controller: _releaseYearController,
                                keyboardType: TextInputType.number,
                                textInputAction: TextInputAction.next,
                              ),
                            ] else ...[
                              _SelectionField(
                                label: 'Category',
                                value: _resolvedCategoryDisplayValue(),
                                helperText: 'Required to save',
                                errorText: _categoryError,
                                actionLabel: 'Browse',
                                onTap: _openCategorySelectorSheet,
                                isPlaceholder: _resolvedCategory()
                                    .trim()
                                    .isEmpty,
                              ),
                              const SizedBox(height: AppSpacing.md),
                              const _BasicsDivider(),
                              const SizedBox(height: AppSpacing.md),
                              _SelectionField(
                                label: _brandFieldLabel,
                                value: _resolvedBrandDisplayValue(),
                                helperText: _brandFieldHelperText,
                                actionLabel: 'Choose',
                                onTap: _openBrandSelectorSheet,
                                isPlaceholder: (_resolvedBrand() ?? '')
                                    .trim()
                                    .isEmpty,
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: _formSectionSpacing),
                      _ExpandableSectionPanel(
                        eyebrow: 'Details',
                        title: _isComicMode
                            ? 'Comic details'
                            : 'Add a little more',
                        description: _isComicMode
                            ? 'Descriptions and condition help once the issue details are in place.'
                            : 'Use this for franchise, line, character, condition, and notes.',
                        expanded: _detailsExpanded,
                        onToggle: _toggleDetailsExpanded,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_isComicMode) ...[
                              _TextAreaField(
                                label: 'Description',
                                hintText:
                                    'Leonardo deals with a betrayal in the present day...',
                                controller: _descriptionController,
                              ),
                            ] else ...[
                              CollectorTextField(
                                label: 'Franchise',
                                hintText: 'Teenage Mutant Ninja Turtles',
                                controller: _franchiseController,
                                textInputAction: TextInputAction.next,
                              ),
                              const SizedBox(height: AppSpacing.md),
                              CollectorTextField(
                                label: _seriesFieldLabel,
                                hintText: 'Vintage Collection',
                                controller: _seriesController,
                                textInputAction: TextInputAction.next,
                              ),
                              const SizedBox(height: AppSpacing.md),
                              CollectorTextField(
                                label: 'Character / Subject',
                                hintText: 'Boba Fett',
                                controller: _characterController,
                                textInputAction: TextInputAction.next,
                              ),
                              const SizedBox(height: AppSpacing.md),
                              CollectorTextField(
                                label: 'Release year',
                                hintText: '2024',
                                controller: _releaseYearController,
                                keyboardType: TextInputType.number,
                                textInputAction: TextInputAction.next,
                              ),
                              const SizedBox(height: AppSpacing.md),
                              _TextAreaField(
                                label: 'Description',
                                hintText:
                                    'Loose figure with soft goods cape and blaster.',
                                controller: _descriptionController,
                              ),
                            ],
                            const SizedBox(height: AppSpacing.lg),
                            Text(
                              'CONDITION',
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                            const SizedBox(height: AppSpacing.xxs),
                            Text(
                              'Choose one condition.',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: AppColors.onSurfaceVariant),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Wrap(
                              spacing: AppSpacing.sm,
                              runSpacing: AppSpacing.sm,
                              children: _conditionOptions
                                  .map(
                                    (condition) => _SingleSelectChoiceChip(
                                      label: condition,
                                      tone: _ChipTone.neutral,
                                      selected: _selectedCondition == condition,
                                      onTap: () {
                                        setState(() {
                                          _selectedCondition =
                                              _selectedCondition == condition
                                              ? null
                                              : condition;
                                        });
                                      },
                                    ),
                                  )
                                  .toList(growable: false),
                            ),
                            if (!_isComicMode) ...[
                              const SizedBox(height: AppSpacing.lg),
                              Text(
                                'BOX STATUS',
                                style: Theme.of(context).textTheme.labelSmall,
                              ),
                              const SizedBox(height: AppSpacing.xxs),
                              Text(
                                'Choose one box status.',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: AppColors.onSurfaceVariant,
                                    ),
                              ),
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
                            ],
                            const SizedBox(height: AppSpacing.lg),
                            _QuantityCard(
                              quantity: _quantity,
                              onDecrement: () => _adjustQuantity(-1),
                              onIncrement: () => _adjustQuantity(1),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            CollectorTextField(
                              label: 'Notes',
                              hintText: _isComicMode
                                  ? 'Raw copy, light spine ticks, bagged and boarded.'
                                  : 'Loose item, complete accessories.',
                              controller: _notesController,
                              textInputAction: TextInputAction.done,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: _formSectionSpacing),
                      _SectionPanel(
                        eyebrow: 'Collector Status',
                        title: 'Mark how it fits your shelf',
                        description:
                            'Use a few structured collector states instead of turning them into tags.',
                        child: _CollectorStatusPanel(
                          isFavorite: _isFavorite,
                          isGrail: _isGrail,
                          isDuplicate: _isDuplicate,
                          onToggle: _toggleCollectorState,
                        ),
                      ),
                      const SizedBox(height: _formSectionSpacing),
                      _ExpandableSectionPanel(
                        eyebrow: 'Organization',
                        title: 'Tags and grouping',
                        description:
                            'Helpful for browsing later, but optional for the first save.',
                        expanded: _organizationExpanded,
                        onToggle: _toggleOrganizationExpanded,
                        child: _TagOrganizerPanel(
                          selectedExistingTags: _selectedExistingTags,
                          newTagNames: _newTagNames,
                          hasSavedTags: _availableTags.isNotEmpty,
                          onManageSavedTags: _openSavedTagsPickerSheet,
                          onCreateTag: _openCreateTagSheet,
                          onRemoveExistingTag: _removeSelectedTagId,
                          onRemoveNewTag: _removeNewTag,
                        ),
                      ),
                      const SizedBox(height: _formSectionSpacing),
                      SizedBox(
                        width: double.infinity,
                        child: CollectorButton(
                          label: _isEditing ? 'Save Changes' : 'Add Item',
                          onPressed: _save,
                          isLoading: _isSaving,
                        ),
                      ),
                    ]),
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

class _PhotoPreview extends StatelessWidget {
  const _PhotoPreview({
    required this.selectedImage,
    this.existingPhotoUrl,
    this.lookupImageUrl,
  });

  final XFile? selectedImage;
  final String? existingPhotoUrl;
  final String? lookupImageUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 220,
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
            ? Stack(
                fit: StackFit.expand,
                children: [
                  Image.file(File(selectedImage!.path), fit: BoxFit.cover),
                  Align(
                    alignment: Alignment.bottomLeft,
                    child: Container(
                      margin: const EdgeInsets.all(AppSpacing.md),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.48),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'Photo ready',
                        style: Theme.of(
                          context,
                        ).textTheme.labelLarge?.copyWith(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              )
            : existingPhotoUrl != null
            ? Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    existingPhotoUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const _PhotoPreviewEmpty(),
                  ),
                  Align(
                    alignment: Alignment.bottomLeft,
                    child: Container(
                      margin: const EdgeInsets.all(AppSpacing.md),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.48),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'Current photo',
                        style: Theme.of(
                          context,
                        ).textTheme.labelLarge?.copyWith(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              )
            : lookupImageUrl != null
            ? Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    lookupImageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const _PhotoPreviewEmpty(),
                  ),
                  Align(
                    alignment: Alignment.bottomLeft,
                    child: Container(
                      margin: const EdgeInsets.all(AppSpacing.md),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.48),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'Suggested image',
                        style: Theme.of(
                          context,
                        ).textTheme.labelLarge?.copyWith(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              )
            : const _PhotoPreviewEmpty(),
      ),
    );
  }
}

class _PhotoPreviewEmpty extends StatelessWidget {
  const _PhotoPreviewEmpty();

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.add_a_photo_outlined, size: 54, color: AppColors.primary),
        SizedBox(height: AppSpacing.md),
        Text('No photo selected yet', textAlign: TextAlign.center),
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
    return CollectorPanel(
      padding: const EdgeInsets.all(AppSpacing.lg),
      backgroundColor: AppColors.surfaceContainer.withValues(alpha: 0.94),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            eyebrow.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.primary,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(
            description,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.onSurfaceVariant),
          ),
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
                        Text(
                          eyebrow.toUpperCase(),
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: AppColors.primary,
                                letterSpacing: 1.1,
                              ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          description,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppColors.onSurfaceVariant),
                        ),
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
    this.enabled = true,
  });

  final String label;
  final String value;
  final String helperText;
  final String actionLabel;
  final VoidCallback onTap;
  final String? errorText;
  final bool isPlaceholder;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: enabled
                ? AppColors.onSurfaceVariant
                : AppColors.onSurfaceVariant.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: AppRadii.medium,
          child: Ink(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: enabled
                  ? AppColors.surfaceContainerHighest.withValues(alpha: 0.4)
                  : AppColors.surfaceContainerHighest.withValues(alpha: 0.24),
              borderRadius: AppRadii.medium,
              border: Border.all(
                color: (errorText ?? '').isNotEmpty
                    ? AppColors.error.withValues(alpha: 0.6)
                    : AppColors.outlineVariant.withValues(alpha: 0.22),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        value,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: isPlaceholder
                              ? AppColors.onSurfaceVariant
                              : AppColors.onSurface,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        errorText ?? helperText,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: (errorText ?? '').isNotEmpty
                              ? AppColors.error
                              : AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                TextButton.icon(
                  onPressed: enabled ? onTap : null,
                  style: TextButton.styleFrom(
                    foregroundColor: enabled
                        ? AppColors.primary
                        : AppColors.onSurfaceVariant,
                  ),
                  icon: Icon(
                    enabled ? Icons.search_rounded : Icons.lock_outline_rounded,
                    size: 16,
                  ),
                  label: Text(actionLabel),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _TextAreaField extends StatelessWidget {
  const _TextAreaField({
    required this.label,
    required this.hintText,
    required this.controller,
  });

  final String label;
  final String hintText;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall,
        ),
        const SizedBox(height: AppSpacing.xs),
        TextField(
          controller: controller,
          minLines: 3,
          maxLines: 5,
          textInputAction: TextInputAction.newline,
          decoration: InputDecoration(
            hintText: hintText,
            alignLabelWithHint: true,
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

class _TagOrganizerPanel extends StatelessWidget {
  const _TagOrganizerPanel({
    required this.selectedExistingTags,
    required this.newTagNames,
    required this.hasSavedTags,
    required this.onManageSavedTags,
    required this.onCreateTag,
    required this.onRemoveExistingTag,
    required this.onRemoveNewTag,
  });

  final List<TagModel> selectedExistingTags;
  final List<String> newTagNames;
  final bool hasSavedTags;
  final VoidCallback onManageSavedTags;
  final VoidCallback onCreateTag;
  final ValueChanged<String> onRemoveExistingTag;
  final ValueChanged<String> onRemoveNewTag;

  @override
  Widget build(BuildContext context) {
    final hasTags = selectedExistingTags.isNotEmpty || newTagNames.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasTags)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHighest.withValues(alpha: 0.38),
              borderRadius: AppRadii.medium,
              border: Border.all(
                color: AppColors.tertiary.withValues(alpha: 0.22),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SELECTED TAGS',
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(color: AppColors.tertiary),
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    ...selectedExistingTags.map(
                      (tag) => _SelectedTagChip(
                        label: tag.name,
                        tone: _ChipTone.tag,
                        onRemove: () => onRemoveExistingTag(tag.id!),
                      ),
                    ),
                    ...newTagNames.map(
                      (tagName) => _SelectedTagChip(
                        label: tagName,
                        tone: _ChipTone.tag,
                        onRemove: () => onRemoveNewTag(tagName),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          )
        else
          Text(
            'Skip tags on the first save if you want. You can always organize it later.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.onSurfaceVariant),
          ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: _ActionTileButton(
                icon: Icons.label_outline_rounded,
                label: hasSavedTags ? 'Browse saved tags' : 'No saved tags yet',
                onTap: hasSavedTags ? onManageSavedTags : onCreateTag,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _ActionTileButton(
                icon: Icons.add_rounded,
                label: 'Create tag',
                onTap: onCreateTag,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

enum CollectorState { favorite, grail, duplicate }

class _CollectorStatusPanel extends StatelessWidget {
  const _CollectorStatusPanel({
    required this.isFavorite,
    required this.isGrail,
    required this.isDuplicate,
    required this.onToggle,
  });

  final bool isFavorite;
  final bool isGrail;
  final bool isDuplicate;
  final ValueChanged<CollectorState> onToggle;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        _StatusToggleChip(
          label: 'Favorite',
          icon: Icons.favorite_rounded,
          selected: isFavorite,
          tone: _ChipTone.tag,
          onTap: () => onToggle(CollectorState.favorite),
        ),
        _StatusToggleChip(
          label: 'Grail',
          icon: Icons.workspace_premium_rounded,
          selected: isGrail,
          tone: _ChipTone.brand,
          onTap: () => onToggle(CollectorState.grail),
        ),
        _StatusToggleChip(
          label: 'Duplicate',
          icon: Icons.copy_all_rounded,
          selected: isDuplicate,
          tone: _ChipTone.category,
          onTap: () => onToggle(CollectorState.duplicate),
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
    this.emptyStateLabel,
  });

  final String title;
  final String description;
  final String searchHint;
  final List<String> options;
  final String? selectedValue;
  final String createActionLabel;
  final String? emptyStateLabel;

  @override
  State<_OptionSearchBottomSheet> createState() =>
      _OptionSearchBottomSheetState();
}

class _OptionSearchBottomSheetState extends State<_OptionSearchBottomSheet> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final normalizedOptions = widget.options.toSet().toList(growable: false)
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    final filteredOptions = normalizedOptions
        .where(
          (option) =>
              _query.trim().isEmpty ||
              option.toLowerCase().contains(_query.trim().toLowerCase()),
        )
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
            onTap: () => Navigator.of(context).pop(_createValueSentinel),
          ),
          const SizedBox(height: AppSpacing.sm),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 320),
            child: filteredOptions.isEmpty
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
  });

  final List<TagModel> availableTags;
  final Set<String> selectedTagIds;

  @override
  State<_TagSearchBottomSheet> createState() => _TagSearchBottomSheetState();
}

class _TagSearchBottomSheetState extends State<_TagSearchBottomSheet> {
  final _searchController = TextEditingController();
  late final Set<String> _workingSelection = {...widget.selectedTagIds};
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
      title: 'Browse saved tags',
      description:
          'Search and toggle the tags you want without opening a giant chip wall.',
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
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: CollectorButton(
              label: 'Apply tags',
              onPressed: () => Navigator.of(context).pop(_workingSelection),
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectionBottomSheetShell extends StatelessWidget {
  const _SelectionBottomSheetShell({
    required this.title,
    required this.description,
    required this.child,
  });

  final String title;
  final String description;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.lg + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.outlineVariant.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(title, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: AppSpacing.sm),
              Text(
                description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              child,
            ],
          ),
        ),
      ),
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

class _SelectedTagChip extends StatelessWidget {
  const _SelectedTagChip({
    required this.label,
    this.tone = _ChipTone.tag,
    required this.onRemove,
  });

  final String label;
  final _ChipTone tone;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final palette = _chipPaletteForTone(tone);
    final maxChipWidth = MediaQuery.sizeOf(context).width * 0.72;

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxChipWidth),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: palette.selectedBackground,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: palette.selectedBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: palette.selectedForeground,
                ),
              ),
            ),
            const SizedBox(width: 6),
            InkWell(
              onTap: onRemove,
              borderRadius: BorderRadius.circular(999),
              child: Padding(
                padding: const EdgeInsets.all(2),
                child: Icon(
                  Icons.close_rounded,
                  size: 16,
                  color: palette.selectedForeground,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionTileButton extends StatelessWidget {
  const _ActionTileButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.onSurface,
        side: BorderSide(
          color: AppColors.outlineVariant.withValues(alpha: 0.28),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(height: AppSpacing.xs),
          Text(label, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _StatusToggleChip extends StatelessWidget {
  const _StatusToggleChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.tone,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final _ChipTone tone;
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
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
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
              Icon(
                icon,
                size: 16,
                color: selected
                    ? palette.selectedForeground
                    : palette.foreground,
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

class _QuantityCard extends StatelessWidget {
  const _QuantityCard({
    required this.quantity,
    required this.onDecrement,
    required this.onIncrement,
  });

  final int quantity;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: AppRadii.medium,
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
                Text('Quantity', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  'Multiple copies only.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          _StepperButton(
            icon: Icons.remove_rounded,
            onTap: quantity > 1 ? onDecrement : null,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Text(
              '$quantity',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          _StepperButton(icon: Icons.add_rounded, onTap: onIncrement),
        ],
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  const _StepperButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.outlineVariant.withValues(alpha: 0.2),
          ),
        ),
        child: Icon(
          icon,
          color: onTap == null
              ? AppColors.onSurfaceVariant.withValues(alpha: 0.4)
              : AppColors.primary,
        ),
      ),
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

class _ValueInputBottomSheet extends StatefulWidget {
  const _ValueInputBottomSheet({
    required this.title,
    required this.description,
    required this.fieldLabel,
    required this.fieldHint,
    required this.submitLabel,
    this.initialValue = '',
  });

  final String title;
  final String description;
  final String fieldLabel;
  final String fieldHint;
  final String submitLabel;
  final String initialValue;

  @override
  State<_ValueInputBottomSheet> createState() => _ValueInputBottomSheetState();
}

class _ValueInputBottomSheetState extends State<_ValueInputBottomSheet> {
  late final TextEditingController _controller;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final value = _controller.text.trim();
    if (value.isEmpty) {
      setState(() {
        _errorText = '${widget.fieldLabel} is required.';
      });
      return;
    }

    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final bottomPadding = keyboardInset == 0 ? AppSpacing.lg : AppSpacing.md;

    return Padding(
      padding: EdgeInsets.only(bottom: keyboardInset),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surfaceContainerHigh,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              bottomPadding,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.outlineVariant.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  widget.title,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  widget.description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                CollectorTextField(
                  label: widget.fieldLabel,
                  hintText: widget.fieldHint,
                  controller: _controller,
                  errorText: _errorText,
                  textInputAction: TextInputAction.done,
                ),
                const SizedBox(height: AppSpacing.lg),
                SizedBox(
                  width: double.infinity,
                  child: CollectorButton(
                    label: widget.submitLabel,
                    onPressed: _submit,
                  ),
                ),
              ],
            ),
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
