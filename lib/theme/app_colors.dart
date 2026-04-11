import 'package:flutter/material.dart';

abstract final class AppColors {
  static const background = Color(0xFF0B0E14);
  static const white = Color(0xFFFFFFFF);

  static const surface = Color(0xFF0B0E14);
  static const surfaceDim = Color(0xFF0B0E14);
  static const surfaceBright = Color(0xFF282C36);
  static const surfaceContainerLowest = Color(0xFF000000);
  static const surfaceContainerLow = Color(0xFF10131A);
  static const surfaceContainer = Color(0xFF161A21);
  static const surfaceContainerHigh = Color(0xFF1C2028);
  static const surfaceContainerHighest = Color(0xFF22262F);

  static const primary = Color(0xFFA3A6FF);
  static const primaryDim = Color(0xFF6063EE);
  static const primaryContainer = Color(0xFF9396FF);
  static const onPrimary = Color(0xFF0F00A4);
  static const onPrimaryContainer = Color(0xFF0A0081);

  static const secondary = Color(0xFFFF716A);
  static const secondaryContainer = Color(0xFFA80619);
  static const onSecondary = Color(0xFF490005);
  static const onSecondaryContainer = Color(0xFFFFDBD8);

  static const tertiary = Color(0xFFFFA5D9);
  static const tertiaryContainer = Color(0xFFFF8ED2);
  static const onTertiary = Color(0xFF701455);
  static const onTertiaryContainer = Color(0xFF63054A);

  static const outline = Color(0xFF73757D);
  static const outlineVariant = Color(0xFF45484F);
  static const onSurface = Color(0xFFECEDF6);
  static const onSurfaceVariant = Color(0xFFA9ABB3);

  static const error = Color(0xFFFF6E84);
  static const errorContainer = Color(0xFFA70138);
  static const onError = Color(0xFF490013);
  static const onErrorContainer = Color(0xFFFFB2B9);

  static const success = Color(0xFF4ADE80);
  static const warning = Color(0xFFF59E0B);
  static const dashboardGlow = Color(0xFF161C35);
  static const featureGlow = Color(0xFF171C34);
  static const aiPhotoGlow = Color(0xFF171C32);
  static const authGlow = Color(0x14171C35);
  static const splashGlow = Color(0x26242A6B);
  static const softShadow = Color(0x16000000);
  static const primaryShadow = Color(0x336063EE);
  static const primaryShadowStrong = Color(0x4D6063EE);
  static const primaryShadowHalo = Color(0x526063EE);
  static const categoryRoseBackground = Color(0x1AA80619);
  static const categoryRoseBorder = Color(0x33FFA5D9);
  static const categoryRoseForeground = Color(0xFFFFA5D9);
  static const categoryVioletBackground = Color(0x1A4E3B9A);
  static const categoryVioletBorder = Color(0x339396FF);
  static const categoryVioletForeground = Color(0xFFA3A6FF);
  static const categoryAmberBackground = Color(0x1AF59E0B);
  static const categoryAmberBorder = Color(0x33FFD38A);
  static const categoryAmberForeground = Color(0xFFFFD08A);
  static const categoryAzureBackground = Color(0x1A0E7490);
  static const categoryAzureBorder = Color(0x3386E3FF);
  static const categoryAzureForeground = Color(0xFF86E3FF);
  static const categoryEmeraldBackground = Color(0x1A0F766E);
  static const categoryEmeraldBorder = Color(0x3391F2C0);
  static const categoryEmeraldForeground = Color(0xFF91F2C0);
  static const categorySlateBackground = Color(0x1A334155);
  static const categorySlateBorder = Color(0x33CBD5E1);
  static const categorySlateForeground = Color(0xFFE2E8F0);

  static const primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryDim, primary],
  );
}
