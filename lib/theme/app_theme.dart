import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_fonts.dart';

abstract final class AppTheme {
  static ThemeData dark() {
    final base = ThemeData.dark(useMaterial3: true);

    final headlineTheme = base.textTheme.apply(
      fontFamily: AppFonts.plusJakartaSans,
      displayColor: AppColors.onSurface,
      bodyColor: AppColors.onSurface,
    );
    final bodyTheme = base.textTheme.apply(
      fontFamily: AppFonts.inter,
      displayColor: AppColors.onSurface,
      bodyColor: AppColors.onSurface,
    );

    final textTheme = bodyTheme.copyWith(
      displayLarge: headlineTheme.displayLarge?.copyWith(
        color: AppColors.onSurface,
        fontWeight: FontWeight.w800,
        letterSpacing: -2.4,
      ),
      displayMedium: headlineTheme.displayMedium?.copyWith(
        color: AppColors.onSurface,
        fontWeight: FontWeight.w800,
        letterSpacing: -1.8,
      ),
      displaySmall: headlineTheme.displaySmall?.copyWith(
        color: AppColors.onSurface,
        fontWeight: FontWeight.w800,
        letterSpacing: -1.4,
      ),
      headlineLarge: headlineTheme.headlineLarge?.copyWith(
        color: AppColors.onSurface,
        fontWeight: FontWeight.w800,
        letterSpacing: -1.2,
      ),
      headlineMedium: headlineTheme.headlineMedium?.copyWith(
        color: AppColors.onSurface,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.8,
      ),
      headlineSmall: headlineTheme.headlineSmall?.copyWith(
        color: AppColors.onSurface,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
      ),
      titleLarge: headlineTheme.titleLarge?.copyWith(
        color: AppColors.onSurface,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
      ),
      titleMedium: headlineTheme.titleMedium?.copyWith(
        color: AppColors.onSurface,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
      ),
      titleSmall: headlineTheme.titleSmall?.copyWith(
        color: AppColors.onSurface,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.1,
      ),
      bodyLarge: bodyTheme.bodyLarge?.copyWith(
        color: AppColors.onSurface,
        height: 1.5,
      ),
      bodyMedium: bodyTheme.bodyMedium?.copyWith(
        color: AppColors.onSurface,
        height: 1.5,
      ),
      bodySmall: bodyTheme.bodySmall?.copyWith(
        color: AppColors.onSurfaceVariant,
        height: 1.4,
      ),
      labelLarge: bodyTheme.labelLarge?.copyWith(
        color: AppColors.onSurface,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.2,
      ),
      labelMedium: bodyTheme.labelMedium?.copyWith(
        color: AppColors.onSurfaceVariant,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.4,
      ),
      labelSmall: bodyTheme.labelSmall?.copyWith(
        color: AppColors.onSurfaceVariant,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.6,
      ),
    );

    final colorScheme = const ColorScheme.dark().copyWith(
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      primaryContainer: AppColors.primaryContainer,
      onPrimaryContainer: AppColors.onPrimaryContainer,
      secondary: AppColors.secondary,
      onSecondary: AppColors.onSecondary,
      secondaryContainer: AppColors.secondaryContainer,
      onSecondaryContainer: AppColors.onSecondaryContainer,
      tertiary: AppColors.tertiary,
      onTertiary: AppColors.onTertiary,
      tertiaryContainer: AppColors.tertiaryContainer,
      onTertiaryContainer: AppColors.onTertiaryContainer,
      error: AppColors.error,
      onError: AppColors.onError,
      errorContainer: AppColors.errorContainer,
      onErrorContainer: AppColors.onErrorContainer,
      surface: AppColors.surface,
      onSurface: AppColors.onSurface,
      surfaceContainerLowest: AppColors.surfaceContainerLowest,
      surfaceContainerLow: AppColors.surfaceContainerLow,
      surfaceContainer: AppColors.surfaceContainer,
      surfaceContainerHigh: AppColors.surfaceContainerHigh,
      surfaceContainerHighest: AppColors.surfaceContainerHighest,
      surfaceDim: AppColors.surfaceDim,
      surfaceBright: AppColors.surfaceBright,
      surfaceTint: AppColors.primary,
      outline: AppColors.outline,
      outlineVariant: AppColors.outlineVariant,
    );

    return base.copyWith(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      canvasColor: AppColors.background,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background.withValues(alpha: 0.7),
        elevation: 0,
        centerTitle: false,
        foregroundColor: AppColors.onSurface,
        titleTextStyle: textTheme.titleLarge,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceContainerHighest,
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: AppColors.onSurfaceVariant.withValues(alpha: 0.38),
          fontStyle: FontStyle.italic,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: AppColors.primary.withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }

  static ThemeData adaptForViewport(
    ThemeData theme, {
    required double width,
    required double height,
    required double textScale,
  }) {
    final profile = _typographyProfileForViewport(
      width: width,
      height: height,
      textScale: textScale,
    );
    if (profile == null) {
      return theme;
    }

    return theme.copyWith(
      textTheme: _scaledTextTheme(
        theme.textTheme,
        titleScale: profile.titleScale,
        bodyScale: profile.bodyScale,
      ),
      appBarTheme: theme.appBarTheme.copyWith(
        titleTextStyle: _scaledTextStyle(
          theme.appBarTheme.titleTextStyle,
          scale: profile.titleScale,
        ),
      ),
    );
  }

  static _ViewportTypographyProfile? _typographyProfileForViewport({
    required double width,
    required double height,
    required double textScale,
  }) {
    final veryCompact =
        width <= 380 || height <= 720 || (width <= 400 && height <= 780);
    if (veryCompact) {
      return const _ViewportTypographyProfile(titleScale: 0.6, bodyScale: 0.76);
    }

    final compact = width < 390 || height < 780 || textScale > 1.05;
    if (compact) {
      return const _ViewportTypographyProfile(titleScale: 0.78, bodyScale: 0.9);
    }

    return null;
  }

  static TextTheme _scaledTextTheme(
    TextTheme textTheme, {
    required double titleScale,
    required double bodyScale,
  }) {
    return textTheme.copyWith(
      displayLarge: _scaledTextStyle(textTheme.displayLarge, scale: titleScale),
      displayMedium: _scaledTextStyle(
        textTheme.displayMedium,
        scale: titleScale,
      ),
      displaySmall: _scaledTextStyle(textTheme.displaySmall, scale: titleScale),
      headlineLarge: _scaledTextStyle(
        textTheme.headlineLarge,
        scale: titleScale,
      ),
      headlineMedium: _scaledTextStyle(
        textTheme.headlineMedium,
        scale: titleScale,
      ),
      headlineSmall: _scaledTextStyle(
        textTheme.headlineSmall,
        scale: titleScale,
      ),
      titleLarge: _scaledTextStyle(textTheme.titleLarge, scale: titleScale),
      titleMedium: _scaledTextStyle(textTheme.titleMedium, scale: titleScale),
      titleSmall: _scaledTextStyle(textTheme.titleSmall, scale: titleScale),
      bodyLarge: _scaledTextStyle(textTheme.bodyLarge, scale: bodyScale),
      bodyMedium: _scaledTextStyle(textTheme.bodyMedium, scale: bodyScale),
      bodySmall: _scaledTextStyle(textTheme.bodySmall, scale: bodyScale),
      labelLarge: _scaledTextStyle(textTheme.labelLarge, scale: bodyScale),
      labelMedium: _scaledTextStyle(textTheme.labelMedium, scale: bodyScale),
      labelSmall: _scaledTextStyle(textTheme.labelSmall, scale: bodyScale),
    );
  }

  static TextStyle? _scaledTextStyle(
    TextStyle? style, {
    required double scale,
  }) {
    if (style == null || style.fontSize == null) {
      return style;
    }

    return style.copyWith(fontSize: style.fontSize! * scale);
  }
}

class _ViewportTypographyProfile {
  const _ViewportTypographyProfile({
    required this.titleScale,
    required this.bodyScale,
  });

  final double titleScale;
  final double bodyScale;
}
