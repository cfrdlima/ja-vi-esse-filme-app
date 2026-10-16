import 'package:flutter/material.dart';

/// Paleta do tema escuro, traduzida de
/// `design-system/ja-vi-esse-filme/MASTER.md` (seção 2).
abstract final class AppColors {
  static const background = Color(0xFF0F0F23);
  static const card = Color(0xFF1B1B30);
  static const muted = Color(0xFF27273B);
  static const foreground = Color(0xFFF8FAFC);
  static const mutedForeground = Color(0xFF94A3B8);
  static const gold = Color(0xFFCA8A04);
  static const onGold = Color(0xFF0F172A);
  static const indigo = Color(0xFF1E1B4B);
  static const indigoBright = Color(0xFF312E81);
  static const outline = Color(0xFF6366F1);
  static const error = Color(0xFFF87171);
  static const onError = Color(0xFF000000);

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
    onSurface: foreground,
    onSurfaceVariant: mutedForeground,
    surfaceContainer: card,
    surfaceContainerHigh: muted,
    outline: outline,
  );
}
