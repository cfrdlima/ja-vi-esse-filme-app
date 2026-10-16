import 'package:flutter/material.dart';

/// Paleta do tema escuro, traduzida de
/// `design-system/ja-vi-esse-filme/MASTER.md` (seção 2).
abstract final class AppColors {
  static const surfaceLowest = Color(0xFF0A0A1A);
  static const background = Color(0xFF0F0F23);
  static const surfaceLow = Color(0xFF151529);
  static const card = Color(0xFF1B1B30);
  static const muted = Color(0xFF27273B);
  static const surfaceHighest = Color(0xFF2C2C42);
  static const foreground = Color(0xFFF8FAFC);
  static const mutedForeground = Color(0xFF94A3B8);
  static const gold = Color(0xFFCA8A04);
  static const onGold = Color(0xFF0F172A);
  static const indigo = Color(0xFF1E1B4B);
  static const indigoBright = Color(0xFF312E81);
  static const outline = Color(0xFF6366F1);
  static const outlineVariant = Color(0xFF3F3F5A);
  static const watched = Color(0xFF34D399);
  static const onWatched = Color(0xFF0F172A);
  static const error = Color(0xFFF87171);
  static const onError = Color(0xFF000000);
  static const scrim = Color(0xFF000000);

  static const darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: gold,
    onPrimary: onGold,
    secondary: indigoBright,
    onSecondary: foreground,
    secondaryContainer: indigo,
    onSecondaryContainer: foreground,
    error: error,
    onError: onError,
    surface: background,
    surfaceDim: background,
    surfaceBright: surfaceHighest,
    onSurface: foreground,
    onSurfaceVariant: mutedForeground,
    surfaceContainerLowest: surfaceLowest,
    surfaceContainerLow: surfaceLow,
    surfaceContainer: card,
    surfaceContainerHigh: muted,
    surfaceContainerHighest: surfaceHighest,
    outline: outline,
    outlineVariant: outlineVariant,
    scrim: scrim,
  );
}
