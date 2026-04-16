import 'package:flutter/material.dart';

import '../core/collector_haptics.dart';
import '../core/data/archive_repository.dart';
import '../core/data/archive_types.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/archive_bootstrap_gate.dart';
import '../widgets/category_icon.dart';
import '../widgets/collector_loading_overlay.dart';
import '../widgets/collector_panel.dart';
import '../widgets/collector_sticky_back_button.dart';
import '../widgets/collector_text_field.dart';
import 'category_collection_screen.dart';

class AllCategoriesScreen extends StatefulWidget {
  const AllCategoriesScreen({super.key});

  @override
  State<AllCategoriesScreen> createState() => _AllCategoriesScreenState();
}

class _AllCategoriesScreenState extends State<AllCategoriesScreen> {
  final _archiveRepository = ArchiveRepository.instance;
  final _searchController = TextEditingController();

  late final Stream<ArchiveLibraryPage> _stream;
  var _query = '';
  var _didChangeCollection = false;

  @override
  void initState() {
    super.initState();
    _stream = _archiveRepository.watchLibraryPage(limit: 1);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _handleBack() {
    Navigator.of(context).pop(_didChangeCollection);
  }

  Future<void> _openCategory(String category) async {
    CollectorHaptics.light();
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => CategoryCollectionScreen(category: category),
      ),
    );

    if (changed == true) {
      _didChangeCollection = true;
      await _archiveRepository.syncIfNeeded(force: true);
    }
  }

  List<ArchiveLibraryCategoryStat> _filterCategories(
    List<ArchiveLibraryCategoryStat> categories,
  ) {
    final terms = _query
        .trim()
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((term) => term.isNotEmpty)
        .toList(growable: false);

    if (terms.isEmpty) {
      return categories;
    }

    return categories
        .where((category) {
          final haystack = category.category.toLowerCase();
          return terms.every(haystack.contains);
        })
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
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
          ArchiveBootstrapGate(
            child: SafeArea(
              child: StreamBuilder<ArchiveLibraryPage>(
                stream: _stream,
                builder: (context, snapshot) {
                  final data = snapshot.data;

                  if (snapshot.hasError && data == null) {
                    return const _AllCategoriesMessage(
                      title: 'Could not load categories.',
                      description: 'Try again once your archive is connected.',
                    );
                  }

                  if (data == null) {
                    return const CollectorLoadingOverlay(
                      label: 'Loading categories...',
                    );
                  }

                  final categories = data.categoryStats;
                  final filteredCategories = _filterCategories(categories);

                  return Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      72,
                      AppSpacing.md,
                      AppSpacing.lg,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Categories',
                          style: Theme.of(context).textTheme.headlineLarge,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          '${categories.length} ${categories.length == 1 ? 'shelf' : 'shelves'} in your collection.',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppColors.onSurfaceVariant),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        CollectorSearchField(
                          hintText: 'Search categories',
                          controller: _searchController,
                          readOnly: false,
                          fillColor: AppColors.surfaceContainerHighest
                              .withValues(alpha: 0.78),
                          onChanged: (value) {
                            setState(() {
                              _query = value;
                            });
                          },
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Expanded(
                          child: categories.isEmpty
                              ? const _AllCategoriesMessage(
                                  title: 'No categories yet.',
                                  description:
                                      'Add a collectible and its category will show up here.',
                                )
                              : filteredCategories.isEmpty
                              ? _AllCategoriesMessage(
                                  title: 'No matching categories.',
                                  description:
                                      'Nothing matched "${_query.trim()}".',
                                )
                              : ListView.separated(
                                  physics: const BouncingScrollPhysics(),
                                  itemCount: filteredCategories.length,
                                  separatorBuilder: (_, _) =>
                                      const SizedBox(height: AppSpacing.sm),
                                  itemBuilder: (context, index) {
                                    final category = filteredCategories[index];
                                    return _AllCategoryRow(
                                      category: category,
                                      onTap: () =>
                                          _openCategory(category.category),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          CollectorStickyBackButton(onPressed: _handleBack),
        ],
      ),
    );
  }
}

class _AllCategoryRow extends StatelessWidget {
  const _AllCategoryRow({required this.category, required this.onTap});

  final ArchiveLibraryCategoryStat category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final itemLabel = category.count == 1
        ? '1 item'
        : '${category.count} items';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainer.withValues(alpha: 0.88),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: AppColors.outlineVariant.withValues(alpha: 0.18),
            ),
          ),
          child: Row(
            children: [
              CategoryIcon(category: category.category, size: 36),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.category,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      itemLabel,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AllCategoriesMessage extends StatelessWidget {
  const _AllCategoriesMessage({required this.title, required this.description});

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: CollectorPanel(
        padding: const EdgeInsets.all(AppSpacing.lg),
        backgroundColor: AppColors.surfaceContainer.withValues(alpha: 0.88),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              description,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
