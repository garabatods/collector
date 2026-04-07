import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_spacing.dart';
import '../widgets/collector_button.dart';
import '../widgets/collector_chip.dart';
import '../widgets/collector_text_field.dart';
import '../widgets/exhibition_card.dart';

class ComponentLibraryScreen extends StatelessWidget {
  const ComponentLibraryScreen({
    super.key,
    required this.isSupabaseConfigured,
  });

  final bool isSupabaseConfigured;

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
                  colors: [
                    AppColors.componentLibraryGlow,
                    AppColors.background,
                  ],
                ),
              ),
            ),
          ),
          CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                expandedHeight: 92,
                toolbarHeight: 76,
                backgroundColor: Colors.transparent,
                flexibleSpace: ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                    child: Container(
                      color: AppColors.background.withValues(alpha: 0.72),
                    ),
                  ),
                ),
                title: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: AppColors.surfaceContainerHighest,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.collections_bookmark_outlined,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'Collector',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ],
                ),
                actions: const [
                  Padding(
                    padding: EdgeInsets.only(right: AppSpacing.md),
                    child: Icon(
                      Icons.search,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.md,
                  120,
                ),
                sliver: SliverList(
                  delegate: SliverChildListDelegate(
                    [
                      _HeroIntro(isSupabaseConfigured: isSupabaseConfigured),
                      const SizedBox(height: AppSpacing.section),
                      const _SectionHeader(
                        index: '01.',
                        title: 'Color Palette',
                        label: 'CORE_VALUES',
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      const _ColorPaletteGrid(),
                      const SizedBox(height: AppSpacing.section),
                      const _SectionHeader(
                        index: '02.',
                        title: 'Typography Scale',
                        label: 'SPEC_GRADES',
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      const _TypographySection(),
                      const SizedBox(height: AppSpacing.section),
                      const _ActionsAndIndicators(),
                      const SizedBox(height: AppSpacing.section),
                      const _SectionHeader(
                        index: '05.',
                        title: 'Form Components',
                        label: 'INPUT_MODES',
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      const _FormSection(),
                      const SizedBox(height: AppSpacing.section),
                      const _SectionHeader(
                        index: '06.',
                        title: 'Exhibition Cards',
                        label: 'GALLERY_UI',
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      const ExhibitionHeroCard(
                        eyebrow: 'Featured Archive',
                        title: 'The Sovereign Series',
                        description:
                            'Exploring the rarest prototypes from the 1980s space era collections.',
                      ),
                      const SizedBox(height: AppSpacing.md),
                      const ExhibitionGridCard(
                        title: 'Vanguard #402',
                        subtitle: 'Issue 1994  •  Grade 9.2',
                        value: '\$1,240',
                        delta: '+12.4%',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: const _BottomBarPreview(),
    );
  }
}

class _HeroIntro extends StatelessWidget {
  const _HeroIntro({required this.isSupabaseConfigured});

  final bool isSupabaseConfigured;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Design System',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppColors.primary,
              ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Obsidian\nArchive',
          style: Theme.of(context).textTheme.displayMedium,
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'A high-end UI library for the modern collector. Editorial prestige meets archival precision through tonal depth and light-emitting surfaces.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            CollectorChip(
              label: isSupabaseConfigured ? 'Supabase linked' : 'Config pending',
              tone: isSupabaseConfigured
                  ? CollectorChipTone.primary
                  : CollectorChipTone.secondary,
            ),
            const CollectorChip(
              label: 'Digital Curator',
              tone: CollectorChipTone.tertiary,
            ),
          ],
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.index,
    required this.title,
    required this.label,
  });

  final String index;
  final String title;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Text(
                '$index $title',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.outline,
                  ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Divider(
          height: 1,
          color: AppColors.outlineVariant.withValues(alpha: 0.1),
        ),
      ],
    );
  }
}

class _ColorPaletteGrid extends StatelessWidget {
  const _ColorPaletteGrid();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        _PaletteSwatch(
          color: AppColors.primary,
          value: '#A3A6FF',
          name: 'Electric Indigo',
          role: 'Primary Action',
          foreground: AppColors.onPrimary,
        ),
        SizedBox(height: AppSpacing.md),
        _PaletteSwatch(
          color: AppColors.secondary,
          value: '#FF716A',
          name: 'Collector-Red',
          role: 'Critical CTA',
          foreground: AppColors.onSecondary,
        ),
        SizedBox(height: AppSpacing.md),
        _PaletteSwatch(
          color: AppColors.surfaceContainerHigh,
          value: '#1C2028',
          name: 'Surface High',
          role: 'Elevated Panels',
          foreground: AppColors.onSurface,
          hasBorder: true,
        ),
        SizedBox(height: AppSpacing.md),
        _PaletteSwatch(
          color: AppColors.surface,
          value: '#0B0E14',
          name: 'Nocturnal Navy',
          role: 'Base Layer',
          foreground: AppColors.onSurface,
          hasBorder: true,
        ),
      ],
    );
  }
}

class _PaletteSwatch extends StatelessWidget {
  const _PaletteSwatch({
    required this.color,
    required this.value,
    required this.name,
    required this.role,
    required this.foreground,
    this.hasBorder = false,
  });

  final Color color;
  final String value;
  final String name;
  final String role;
  final Color foreground;
  final bool hasBorder;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 152,
          padding: const EdgeInsets.all(AppSpacing.md),
          alignment: Alignment.bottomLeft,
          decoration: BoxDecoration(
            color: color,
            borderRadius: AppRadii.medium,
            border: hasBorder
                ? Border.all(
                    color: AppColors.outlineVariant.withValues(alpha: 0.2),
                  )
                : null,
          ),
          child: Text(
            value,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: foreground,
                ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(name, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          role.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall,
        ),
      ],
    );
  }
}

class _TypographySection extends StatelessWidget {
  const _TypographySection();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _TypeRow(
          label: 'Display Large',
          sample: 'Collector Elite',
          note: 'Plus Jakarta Sans - 800 - -0.04em',
          styleType: _TypeStyle.display,
        ),
        SizedBox(height: AppSpacing.xl),
        _TypeRow(
          label: 'Heading Medium',
          sample: 'Archival Preservation Methods',
          note: 'Plus Jakarta Sans - 700 - -0.02em',
          styleType: _TypeStyle.heading,
        ),
        SizedBox(height: AppSpacing.xl),
        _TypeRow(
          label: 'Body Regular',
          sample:
              'The act of cataloging a rare toy or first-edition comic should feel as prestigious as the item itself.',
          note: 'Inter - 400 - Standard',
          styleType: _TypeStyle.body,
        ),
        SizedBox(height: AppSpacing.xl),
        _TypeRow(
          label: 'Label Small',
          sample: 'MINT CONDITION GRADE 9.8',
          note: 'Inter - 700 - +0.05em',
          styleType: _TypeStyle.label,
        ),
      ],
    );
  }
}

enum _TypeStyle { display, heading, body, label }

class _TypeRow extends StatelessWidget {
  const _TypeRow({
    required this.label,
    required this.sample,
    required this.note,
    required this.styleType,
  });

  final String label;
  final String sample;
  final String note;
  final _TypeStyle styleType;

  @override
  Widget build(BuildContext context) {
    final sampleStyle = switch (styleType) {
      _TypeStyle.display => Theme.of(context).textTheme.displayLarge,
      _TypeStyle.heading => Theme.of(context).textTheme.headlineMedium,
      _TypeStyle.body => Theme.of(context).textTheme.bodyLarge,
      _TypeStyle.label => Theme.of(context).textTheme.labelMedium?.copyWith(
            color: AppColors.primary,
          ),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(sample, style: sampleStyle),
        const SizedBox(height: AppSpacing.xs),
        Text(
          note,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.outline,
              ),
        ),
      ],
    );
  }
}

class _ActionsAndIndicators extends StatelessWidget {
  const _ActionsAndIndicators();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _SectionHeader(
          index: '03.',
          title: 'Actions',
          label: 'INTERACTION',
        ),
        const SizedBox(height: AppSpacing.lg),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: const [
            CollectorButton(label: 'Primary Action', onPressed: _noop),
            CollectorButton(
              label: 'Secondary',
              onPressed: _noop,
              variant: CollectorButtonVariant.secondary,
            ),
            CollectorButton(
              label: 'Remove Item',
              onPressed: _noop,
              variant: CollectorButtonVariant.tertiary,
            ),
            CollectorButton(
              label: '',
              onPressed: _noop,
              icon: Icons.add,
              variant: CollectorButtonVariant.icon,
            ),
            CollectorButton(
              label: '',
              onPressed: _noop,
              icon: Icons.center_focus_strong,
              variant: CollectorButtonVariant.icon,
            ),
            CollectorButton(
              label: '',
              onPressed: _noop,
              icon: Icons.favorite,
              variant: CollectorButtonVariant.icon,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.section),
        const _SectionHeader(
          index: '04.',
          title: 'Indicators',
          label: 'STATUS',
        ),
        const SizedBox(height: AppSpacing.lg),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: const [
            CollectorChip(label: 'Mint', tone: CollectorChipTone.primary),
            CollectorChip(
              label: 'Near Mint',
              tone: CollectorChipTone.secondary,
            ),
            CollectorChip(label: 'Boxed', tone: CollectorChipTone.tertiary),
            CollectorChip(label: 'Grade 9.8'),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: const BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: AppRadii.medium,
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Text(
                    'Collection Progress'.toUpperCase(),
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                  const Spacer(),
                  Text(
                    '84%',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: AppColors.primary,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              ClipRRect(
                borderRadius: AppRadii.pill,
                child: LinearProgressIndicator(
                  minHeight: 8,
                  value: 0.84,
                  backgroundColor: AppColors.surfaceContainerHighest,
                  valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FormSection extends StatelessWidget {
  const _FormSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const CollectorTextField(
          label: 'Item Name',
          hintText: 'e.g. Vintage 1977 Stormtrooper',
          prefixIcon: Icons.edit,
        ),
        const SizedBox(height: AppSpacing.lg),
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: AppRadii.medium,
            border: Border.all(
              color: AppColors.outlineVariant.withValues(alpha: 0.1),
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.notifications_active,
                color: AppColors.secondary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Price Alerts',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Notify me when value shifts greater than 5%',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Switch(
                value: true,
                onChanged: (_) {},
                activeThumbColor: Colors.white,
                activeTrackColor: AppColors.primary,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Estimated Value Range'.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppColors.primary,
            inactiveTrackColor: AppColors.surfaceContainerHighest,
            thumbColor: AppColors.onBackground,
            overlayColor: AppColors.primary.withValues(alpha: 0.12),
          ),
          child: RangeSlider(
            values: RangeValues(0.2, 0.7),
            min: 0,
            max: 1,
            onChanged: _noopRange,
          ),
        ),
        Row(
          children: [
            Text('\$0.00', style: Theme.of(context).textTheme.bodySmall),
            const Spacer(),
            Text('\$5,000.00', style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ],
    );
  }
}

class _BottomBarPreview extends StatelessWidget {
  const _BottomBarPreview();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: AppRadii.lg,
        topRight: AppRadii.lg,
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.sm,
            AppSpacing.sm,
            AppSpacing.sm,
            AppSpacing.lg,
          ),
          color: AppColors.background.withValues(alpha: 0.8),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _BottomNavItem(icon: Icons.home_outlined, label: 'Home'),
              _BottomNavItem(icon: Icons.grid_view_outlined, label: 'Library'),
              _BottomNavItem(
                icon: Icons.center_focus_strong,
                label: 'Scan',
                active: true,
              ),
              _BottomNavItem(icon: Icons.favorite_outline, label: 'Wishlist'),
              _BottomNavItem(icon: Icons.person_outline, label: 'Profile'),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  const _BottomNavItem({
    required this.icon,
    required this.label,
    this.active = false,
  });

  final IconData icon;
  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final foreground = active ? AppColors.primary : AppColors.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: active
            ? AppColors.primary.withValues(alpha: 0.1)
            : Colors.transparent,
        borderRadius: AppRadii.medium,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: foreground),
          const SizedBox(height: 4),
          Text(
            label.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: foreground,
                  fontSize: 9,
                ),
          ),
        ],
      ),
    );
  }
}

void _noop() {}

void _noopRange(RangeValues _) {}
