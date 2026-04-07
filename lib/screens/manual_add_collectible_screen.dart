import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../features/collection/data/models/barcode_lookup_result.dart';
import '../features/collection/data/models/collectible_model.dart';
import '../features/collection/data/models/tag_model.dart';
import '../features/collection/data/repositories/collectible_photos_repository.dart';
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

class ManualAddCollectibleScreen extends StatefulWidget {
  const ManualAddCollectibleScreen({
    super.key,
    this.collectible,
    this.existingPhotoUrl,
    this.scannedBarcode,
    this.barcodeLookup,
    this.selectedTagIds,
    this.newTagNames,
  });

  final CollectibleModel? collectible;
  final String? existingPhotoUrl;
  final String? scannedBarcode;
  final BarcodeLookupResult? barcodeLookup;
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
  bool _showMoreCategories = false;
  bool _showMoreBrands = false;
  bool _showMoreTags = false;
  bool _detailsExpanded = false;
  String? _selectedCondition;
  String? _selectedBoxStatus;
  int _quantity = 1;
  bool _isSaving = false;
  String? _titleError;
  String? _categoryError;
  List<String> _topBrands = const [];
  List<String> _moreBrands = const [];
  List<TagModel> _availableTags = const [];
  List<TagModel> _topTags = const [];
  List<TagModel> _moreTags = const [];
  final Set<String> _selectedTagIds = <String>{};
  final List<String> _newTagNames = <String>[];

  bool get _isEditing => widget.collectible != null;

  @override
  void initState() {
    super.initState();
    _hydrateFromCollectible();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _customCategoryController.dispose();
    _customBrandController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _hydrateFromCollectible() {
    _selectedTagIds
      ..clear()
      ..addAll(widget.selectedTagIds ?? const []);
    _newTagNames
      ..clear()
      ..addAll(widget.newTagNames ?? const []);

    final collectible = widget.collectible;
    if (collectible == null) {
      _hydrateFromBarcodeLookup();
      _loadSuggestions();
      return;
    }

    _titleController.text = collectible.title;
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

    if (_topCategories.contains(collectible.category)) {
      _selectedCategory = collectible.category;
      _useCustomCategory = false;
    } else if (_moreCategories.contains(collectible.category)) {
      _selectedCategory = collectible.category;
      _useCustomCategory = false;
      _showMoreCategories = true;
    } else {
      _customCategoryController.text = collectible.category;
      _useCustomCategory = true;
    }

    _loadSuggestions();
  }

  void _hydrateFromBarcodeLookup() {
    final barcodeLookup = widget.barcodeLookup;
    if (barcodeLookup == null) {
      return;
    }

    if (_titleController.text.trim().isEmpty) {
      _titleController.text = barcodeLookup.title;
    }

    final suggestedCategory = barcodeLookup.suggestedCategory;
    if (suggestedCategory != null && suggestedCategory.isNotEmpty) {
      if (_topCategories.contains(suggestedCategory)) {
        _selectedCategory = suggestedCategory;
        _useCustomCategory = false;
      } else if (_moreCategories.contains(suggestedCategory)) {
        _selectedCategory = suggestedCategory;
        _useCustomCategory = false;
        _showMoreCategories = true;
      } else {
        _customCategoryController.text = suggestedCategory;
        _useCustomCategory = true;
      }
    }

    if (((_selectedBrand ?? '').trim().isEmpty) &&
        (barcodeLookup.brand ?? '').trim().isNotEmpty) {
      _selectedBrand = barcodeLookup.brand!.trim();
      _useCustomBrand = true;
      _customBrandController.clear();
    }
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

      final brands =
          sortedBrands.map((entry) => entry.key).toList(growable: false);
      final topBrands = brands.take(_visibleSuggestionCount).toList(growable: false);
      final moreBrands =
          brands.skip(_visibleSuggestionCount).toList(growable: false);
      final pendingBrand = (_selectedBrand ?? '').trim();

      setState(() {
        _topBrands = topBrands;
        _moreBrands = moreBrands;
        _availableTags = tags;
        _topTags = tags.take(_visibleSuggestionCount).toList(growable: false);
        _moreTags = tags.skip(_visibleSuggestionCount).toList(growable: false);

        if (pendingBrand.isEmpty) {
          return;
        }

        if (brands.contains(pendingBrand)) {
          _selectedBrand = pendingBrand;
          _useCustomBrand = false;
          if (moreBrands.contains(pendingBrand)) {
            _showMoreBrands = true;
          }
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
        _topTags = const [];
        _moreTags = const [];
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
      title: 'Add brand',
      description: 'Create a brand when the saved suggestions do not fit.',
      fieldLabel: 'Brand name',
      fieldHint: 'McFarlane Toys',
      submitLabel: 'Save brand',
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
      if (existingBrand != null && _moreBrands.contains(existingBrand)) {
        _showMoreBrands = true;
      }
    });
  }

  void _toggleMoreCategories() {
    setState(() {
      _showMoreCategories = !_showMoreCategories;
    });
  }

  void _toggleMoreBrands() {
    setState(() {
      _showMoreBrands = !_showMoreBrands;
    });
  }

  void _toggleMoreTags() {
    setState(() {
      _showMoreTags = !_showMoreTags;
    });
  }

  void _toggleDetailsExpanded() {
    setState(() {
      _detailsExpanded = !_detailsExpanded;
    });
  }

  void _toggleTagSelection(String tagId) {
    setState(() {
      if (_selectedTagIds.contains(tagId)) {
        _selectedTagIds.remove(tagId);
      } else {
        _selectedTagIds.add(tagId);
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

  void _adjustQuantity(int delta) {
    setState(() {
      _quantity = (_quantity + delta).clamp(1, 999);
    });
  }

  String _resolvedCategory() {
    if (_useCustomCategory) {
      return _customCategoryController.text.trim();
    }

    return (_selectedCategory ?? '').trim();
  }

  String? _resolvedBrand() {
    final selectedBrand = (_selectedBrand ?? '').trim();
    return selectedBrand.isEmpty ? null : selectedBrand;
  }

  String? _nullableText(TextEditingController controller) {
    final value = controller.text.trim();
    return value.isEmpty ? null : value;
  }

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
            (widget.scannedBarcode ?? widget.collectible?.barcode)?.trim(),
        title: title,
        category: category,
        brand: _resolvedBrand(),
        franchise: widget.collectible?.franchise,
        lineOrSeries:
            widget.collectible?.lineOrSeries ?? widget.collectible?.series,
        characterOrSubject: widget.collectible?.characterOrSubject,
        itemCondition: _selectedCondition,
        boxStatus: _selectedBoxStatus,
        quantity: _quantity,
        isFavorite: widget.collectible?.isFavorite ?? false,
        isGrail: widget.collectible?.isGrail ?? false,
        isDuplicate: widget.collectible?.isDuplicate ?? false,
        openToTrade: widget.collectible?.openToTrade ?? false,
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
          (widget.barcodeLookup?.imageUrl ?? '').isNotEmpty) {
        try {
          await _photosRepository.uploadPrimaryPhotoFromRemoteImage(
            collectibleId: collectibleId,
            imageUrl: widget.barcodeLookup!.imageUrl!,
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
                  colors: [
                    AppColors.featureGlow,
                    AppColors.background,
                  ],
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
                          _isEditing
                              ? 'Edit item.'
                              : 'Add an item.',
                          style: Theme.of(context).textTheme.headlineLarge,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Save the basics first. Add more only if it helps.',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.onSurfaceVariant,
                                  ),
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
                    delegate: SliverChildListDelegate(
                      [
                        _SectionPanel(
                          eyebrow: 'Photo',
                          title: 'Add a photo',
                          description: 'Optional, but helpful.',
                          child: Column(
                            children: [
                              _PhotoPreview(
                                selectedImage: selectedImage,
                                existingPhotoUrl: widget.existingPhotoUrl,
                                lookupImageUrl: widget.barcodeLookup?.imageUrl,
                              ),
                              const SizedBox(height: AppSpacing.md),
                              Row(
                                children: [
                                  Expanded(
                                    child: _ActionTileButton(
                                      icon: Icons.camera_alt_outlined,
                                      label: 'Take photo',
                                      onTap: () =>
                                          _pickImage(ImageSource.camera),
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
                          title: 'Just enough to save it',
                          description: 'Pick a category and give it a title.',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CollectorTextField(
                                label: 'Title',
                                hintText: 'Vintage Batman figure',
                                controller: _titleController,
                                errorText: _titleError,
                                textInputAction: TextInputAction.next,
                              ),
                              const SizedBox(height: AppSpacing.md),
                              const _BasicsDivider(),
                              const SizedBox(height: AppSpacing.md),
                              _CategoryPicker(
                                topCategories: _topCategories,
                                moreCategories: _moreCategories,
                                selectedCategory: _selectedCategory,
                                useCustomCategory: _useCustomCategory,
                                showMoreCategories: _showMoreCategories,
                                customCategoryValue:
                                    _customCategoryController.text.trim(),
                                categoryError: _categoryError,
                                onCategorySelected: _selectCategory,
                                onCustomSelected: _openCustomCategorySheet,
                                onToggleMore: _toggleMoreCategories,
                              ),
                              const SizedBox(height: AppSpacing.md),
                              const _BasicsDivider(),
                              const SizedBox(height: AppSpacing.md),
                              _BrandPicker(
                                label: 'Brand',
                                tone: _ChipTone.brand,
                                topOptions: _topBrands,
                                moreOptions: _moreBrands,
                                selectedValue: _selectedBrand,
                                useCustomValue: _useCustomBrand,
                                customValue:
                                    _customBrandController.text.trim().isNotEmpty
                                        ? _customBrandController.text.trim()
                                        : (_selectedBrand ?? '').trim(),
                                showMoreOptions: _showMoreBrands,
                                onOptionSelected: _selectBrand,
                                onCustomSelected: _openCustomBrandSheet,
                                onToggleMore: _toggleMoreBrands,
                                createActionLabel: 'Add brand',
                                emptyHelperText:
                                    'Brands from your collection will show up here as you add more items.',
                              ),
                              const SizedBox(height: AppSpacing.md),
                              const _BasicsDivider(),
                              const SizedBox(height: AppSpacing.md),
                              _TagsPicker(
                                topTags: _topTags,
                                moreTags: _moreTags,
                                showMoreTags: _showMoreTags,
                                selectedTagIds: _selectedTagIds,
                                newTagNames: _newTagNames,
                                onToggleMore: _toggleMoreTags,
                                onToggleTag: _toggleTagSelection,
                                onCreateTag: _openCreateTagSheet,
                                onRemoveExistingTag: _removeSelectedTagId,
                                onRemoveNewTag: _removeNewTag,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: _formSectionSpacing),
                        _ExpandableSectionPanel(
                          eyebrow: 'Details',
                          title: 'Add a little more',
                          description: 'Only if it matters for this piece.',
                          expanded: _detailsExpanded,
                          onToggle: _toggleDetailsExpanded,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'CONDITION',
                                style: Theme.of(context).textTheme.labelSmall,
                              ),
                              const SizedBox(height: AppSpacing.xxs),
                              Text(
                                'Choose one condition.',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.onSurfaceVariant,
                                    ),
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
                                        selected:
                                            _selectedCondition == condition,
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
                              const SizedBox(height: AppSpacing.lg),
                              Text(
                                'BOX STATUS',
                                style: Theme.of(context).textTheme.labelSmall,
                              ),
                              const SizedBox(height: AppSpacing.xxs),
                              Text(
                                'Choose one box status.',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
                              const SizedBox(height: AppSpacing.lg),
                              _QuantityCard(
                                quantity: _quantity,
                                onDecrement: () => _adjustQuantity(-1),
                                onIncrement: () => _adjustQuantity(1),
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              CollectorTextField(
                                label: 'Notes',
                                hintText: 'Loose item, complete accessories.',
                                controller: _notesController,
                                textInputAction: TextInputAction.done,
                              ),
                            ],
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
                      ],
                    ),
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
                  Image.file(
                    File(selectedImage!.path),
                    fit: BoxFit.cover,
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
                        'Photo ready',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: Colors.white,
                            ),
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
                            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                  color: Colors.white,
                                ),
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
                                style: Theme.of(context)
                                    .textTheme
                                    .labelLarge
                                    ?.copyWith(color: Colors.white),
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
        Icon(
          Icons.add_a_photo_outlined,
          size: 54,
          color: AppColors.primary,
        ),
        SizedBox(height: AppSpacing.md),
        Text(
          'No photo selected yet',
          textAlign: TextAlign.center,
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
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            description,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
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
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
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
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.onSurfaceVariant,
                                  ),
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
            crossFadeState:
                expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 180),
          ),
        ],
      ),
    );
  }
}

class _ScannedBarcodeBanner extends StatelessWidget {
  const _ScannedBarcodeBanner({
    required this.barcode,
  });

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
            child: const Icon(
              Icons.qr_code_rounded,
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

class _CategoryPicker extends StatelessWidget {
  const _CategoryPicker({
    required this.topCategories,
    required this.moreCategories,
    required this.selectedCategory,
    required this.useCustomCategory,
    required this.showMoreCategories,
    required this.customCategoryValue,
    required this.categoryError,
    required this.onCategorySelected,
    required this.onCustomSelected,
    required this.onToggleMore,
  });

  final List<String> topCategories;
  final List<String> moreCategories;
  final String? selectedCategory;
  final bool useCustomCategory;
  final bool showMoreCategories;
  final String customCategoryValue;
  final String? categoryError;
  final ValueChanged<String> onCategorySelected;
  final VoidCallback onCustomSelected;
  final VoidCallback onToggleMore;

  @override
  Widget build(BuildContext context) {
    return _SuggestionPicker(
      label: 'Category',
      tone: _ChipTone.category,
      topOptions: topCategories,
      moreOptions: moreCategories,
      selectedValue: selectedCategory,
      useCustomValue: useCustomCategory,
      customValue: customCategoryValue,
      showMoreOptions: showMoreCategories,
      errorText: categoryError,
      onOptionSelected: onCategorySelected,
      onCustomSelected: onCustomSelected,
      onToggleMore: onToggleMore,
      createActionLabel: 'Add category',
    );
  }
}

class _BrandPicker extends StatelessWidget {
  const _BrandPicker({
    required this.label,
    required this.tone,
    required this.topOptions,
    required this.moreOptions,
    required this.selectedValue,
    required this.useCustomValue,
    required this.customValue,
    required this.showMoreOptions,
    required this.onOptionSelected,
    required this.onCustomSelected,
    required this.onToggleMore,
    required this.createActionLabel,
    this.emptyHelperText,
  });

  final String label;
  final _ChipTone tone;
  final List<String> topOptions;
  final List<String> moreOptions;
  final String? selectedValue;
  final bool useCustomValue;
  final String customValue;
  final bool showMoreOptions;
  final ValueChanged<String> onOptionSelected;
  final VoidCallback onCustomSelected;
  final VoidCallback onToggleMore;
  final String createActionLabel;
  final String? emptyHelperText;

  @override
  Widget build(BuildContext context) {
    final resolvedSelectedValue = (selectedValue ?? '').trim();
    final hasCustomSelectedValue =
        useCustomValue &&
        resolvedSelectedValue.isNotEmpty &&
        !topOptions.contains(resolvedSelectedValue) &&
        !moreOptions.contains(resolvedSelectedValue);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SuggestionPicker(
          label: label,
          tone: tone,
          topOptions: topOptions,
          moreOptions: moreOptions,
          selectedValue: selectedValue,
          useCustomValue: useCustomValue,
          customValue: hasCustomSelectedValue ? resolvedSelectedValue : customValue,
          showMoreOptions: showMoreOptions,
          onOptionSelected: onOptionSelected,
          onCustomSelected: onCustomSelected,
          onToggleMore: onToggleMore,
          createActionLabel: createActionLabel,
          errorText: null,
          emptyHelperText: emptyHelperText,
        ),
      ],
    );
  }
}

class _SuggestionPicker extends StatelessWidget {
  const _SuggestionPicker({
    required this.label,
    required this.tone,
    required this.topOptions,
    required this.moreOptions,
    required this.selectedValue,
    required this.useCustomValue,
    required this.customValue,
    required this.showMoreOptions,
    required this.onOptionSelected,
    required this.onCustomSelected,
    required this.onToggleMore,
    required this.createActionLabel,
    this.errorText,
    this.emptyHelperText,
  });

  final String label;
  final _ChipTone tone;
  final List<String> topOptions;
  final List<String> moreOptions;
  final String? selectedValue;
  final bool useCustomValue;
  final String customValue;
  final bool showMoreOptions;
  final ValueChanged<String> onOptionSelected;
  final VoidCallback onCustomSelected;
  final VoidCallback onToggleMore;
  final String createActionLabel;
  final String? errorText;
  final String? emptyHelperText;

  @override
  Widget build(BuildContext context) {
    final hasMoreOptions = moreOptions.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PickerSectionHeader(
          label: label.toUpperCase(),
          helperText: 'Choose one option.',
          showToggle: hasMoreOptions,
          expanded: showMoreOptions,
          onToggle: onToggleMore,
        ),
        const SizedBox(height: AppSpacing.sm),
        if (useCustomValue && customValue.isNotEmpty) ...[
          _CustomValueSummaryCard(
            title: 'Custom selection',
            value: customValue,
            tone: tone,
            onEdit: onCustomSelected,
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        if (topOptions.isNotEmpty)
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              ...topOptions.map(
                (option) => _SingleSelectChoiceChip(
                  label: option,
                  tone: tone,
                  selected: !useCustomValue && selectedValue == option,
                  onTap: () => onOptionSelected(option),
                ),
              ),
            ],
          )
        else if ((emptyHelperText ?? '').isNotEmpty) ...[
          Text(
            emptyHelperText!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
          ),
        ],
        if (showMoreOptions && moreOptions.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: moreOptions
                .map(
                (option) => _SingleSelectChoiceChip(
                  label: option,
                  tone: tone,
                  selected: !useCustomValue && selectedValue == option,
                  onTap: () => onOptionSelected(option),
                ),
                )
                .toList(growable: false),
          ),
        ],
        const SizedBox(height: AppSpacing.sm),
        _ValueCreatorButton(
          label: useCustomValue && customValue.isNotEmpty
              ? 'Edit ${label.toLowerCase()}'
              : createActionLabel,
          onTap: onCustomSelected,
        ),
        if (errorText != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            errorText!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.error,
                ),
          ),
        ],
      ],
    );
  }
}

class _TagsPicker extends StatelessWidget {
  const _TagsPicker({
    required this.topTags,
    required this.moreTags,
    required this.showMoreTags,
    required this.selectedTagIds,
    required this.newTagNames,
    required this.onToggleMore,
    required this.onToggleTag,
    required this.onCreateTag,
    required this.onRemoveExistingTag,
    required this.onRemoveNewTag,
  });

  final List<TagModel> topTags;
  final List<TagModel> moreTags;
  final bool showMoreTags;
  final Set<String> selectedTagIds;
  final List<String> newTagNames;
  final VoidCallback onToggleMore;
  final ValueChanged<String> onToggleTag;
  final VoidCallback onCreateTag;
  final ValueChanged<String> onRemoveExistingTag;
  final ValueChanged<String> onRemoveNewTag;

  @override
  Widget build(BuildContext context) {
    final selectedExistingTags = [
      ...topTags,
      ...moreTags,
    ].where((tag) => selectedTagIds.contains(tag.id)).toList(growable: false);
    final hasExistingSuggestions = topTags.isNotEmpty || moreTags.isNotEmpty;
    final hasMoreTags = moreTags.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PickerSectionHeader(
          label: 'TAGS',
          helperText: 'Add one or more tags.',
          showToggle: hasMoreTags,
          expanded: showMoreTags,
          onToggle: onToggleMore,
        ),
        const SizedBox(height: AppSpacing.sm),
        if (selectedExistingTags.isNotEmpty || newTagNames.isNotEmpty) ...[
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
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.tertiary,
                      ),
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
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        if (selectedExistingTags.isEmpty && newTagNames.isEmpty) ...[
          Text(
            'Selected tags will collect here as you add them.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        if (topTags.isNotEmpty)
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: topTags
                .where((tag) => (tag.id ?? '').isNotEmpty)
                .map(
                (tag) => _TagSuggestionChip(
                  label: tag.name,
                  selected: selectedTagIds.contains(tag.id),
                  onTap: () => onToggleTag(tag.id!),
                ),
                )
                .toList(growable: false),
          ),
        if (!hasExistingSuggestions) ...[
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _ValueCreatorButton(
                label: 'Create new tag',
                onTap: onCreateTag,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Your saved tags will start showing up here as you use them.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
          ),
        ] else
          const SizedBox(height: AppSpacing.sm),
        if (showMoreTags && moreTags.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: moreTags
                .where((tag) => (tag.id ?? '').isNotEmpty)
                .map(
                (tag) => _TagSuggestionChip(
                  label: tag.name,
                  selected: selectedTagIds.contains(tag.id),
                  onTap: () => onToggleTag(tag.id!),
                ),
                )
                .toList(growable: false),
          ),
        ],
        if (hasExistingSuggestions)
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _ValueCreatorButton(
                label: 'Create new tag',
                onTap: onCreateTag,
              ),
            ],
          ),
      ],
    );
  }
}

class _PickerSectionHeader extends StatelessWidget {
  const _PickerSectionHeader({
    required this.label,
    required this.showToggle,
    required this.expanded,
    required this.onToggle,
    this.helperText,
  });

  final String label;
  final bool showToggle;
  final bool expanded;
  final VoidCallback onToggle;
  final String? helperText;

  @override
  Widget build(BuildContext context) {
    final labelStyle = Theme.of(context).textTheme.labelSmall;
    final toggleStyle = Theme.of(context).textTheme.labelMedium?.copyWith(
          color: AppColors.primary,
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: labelStyle,
              ),
            ),
            if (showToggle)
              TextButton(
                onPressed: onToggle,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 0),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  foregroundColor: AppColors.primary,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      expanded ? 'Show less' : 'Show more',
                      style: toggleStyle,
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      expanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      size: 18,
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ),
          ],
        ),
        if ((helperText ?? '').isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xxs),
          Text(
            helperText!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
          ),
        ],
      ],
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

class _CustomValueSummaryCard extends StatelessWidget {
  const _CustomValueSummaryCard({
    required this.title,
    required this.value,
    required this.tone,
    required this.onEdit,
  });

  final String title;
  final String value;
  final _ChipTone tone;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final palette = _chipPaletteForTone(tone);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: palette.selectedBackground,
        borderRadius: AppRadii.medium,
        border: Border.all(color: palette.selectedBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.toUpperCase(),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: palette.selectedForeground,
                      ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: palette.selectedForeground,
                      ),
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: onEdit,
            style: TextButton.styleFrom(
              foregroundColor: palette.selectedForeground,
            ),
            icon: const Icon(Icons.edit_rounded, size: 16),
            label: const Text('Edit'),
          ),
        ],
      ),
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
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: palette.selectedBackground,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: palette.selectedBorder,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: palette.selectedForeground,
                ),
          ),
          const SizedBox(width: 6),
          InkWell(
            onTap: onRemove,
            borderRadius: BorderRadius.circular(999),
            child: Icon(
              Icons.close_rounded,
              size: 16,
              color: palette.selectedForeground,
            ),
          ),
        ],
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
          Text(
            label,
            textAlign: TextAlign.center,
          ),
        ],
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
                Text(
                  'Quantity',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
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
          _StepperButton(
            icon: Icons.add_rounded,
            onTap: onIncrement,
          ),
        ],
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  const _StepperButton({
    required this.icon,
    required this.onTap,
  });

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
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
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

class _TagSuggestionChip extends StatelessWidget {
  const _TagSuggestionChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = _chipPaletteForTone(_ChipTone.tag);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.pill,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? palette.selectedBackground : palette.background,
            borderRadius: AppRadii.pill,
            border: Border.all(
              color: selected ? palette.selectedBorder : palette.border,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                selected ? Icons.check_rounded : Icons.add_rounded,
                size: 14,
                color: selected
                    ? palette.selectedForeground
                    : palette.foreground,
              ),
              const SizedBox(width: 6),
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

class _ValueCreatorButton extends StatelessWidget {
  const _ValueCreatorButton({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.onSurface,
        side: BorderSide(
          color: AppColors.outlineVariant.withValues(alpha: 0.24),
        ),
        backgroundColor: AppColors.surfaceContainerHighest.withValues(alpha: 0.2),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 10,
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: AppRadii.medium,
        ),
      ),
      icon: const Icon(Icons.add_rounded),
      label: Text(label),
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

enum _ChipTone {
  neutral,
  category,
  brand,
  tag,
}

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
  const _BoxStatusOption({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;
}
