import 'package:flutter/material.dart';

/// Escala tipográfica da seção 3 do `MASTER.md`: Playfair Display nos
/// títulos e Inter no texto e na interface. As famílias são empacotadas
/// em `assets/fonts/` e declaradas no `pubspec.yaml`.
abstract final class AppTypography {
  static const headingFamily = 'PlayfairDisplay';
  static const bodyFamily = 'Inter';

  // O MASTER.md não herda o letterSpacing do M3 (0,25–0,5), que deixa a
  // Inter aberta demais; só os labels ganham um leve respiro.
  static const _labelLetterSpacing = 0.1;

  static final textTheme = TextTheme(
    displayLarge: _heading(FontWeight.w700, size: 57, lineHeight: 64),
    displayMedium: _heading(FontWeight.w700, size: 45, lineHeight: 52),
    displaySmall: _heading(FontWeight.w700, size: 36, lineHeight: 44),
    headlineLarge: _heading(FontWeight.w700, size: 32, lineHeight: 40),
    headlineMedium: _heading(FontWeight.w700, size: 28, lineHeight: 36),
    headlineSmall: _heading(FontWeight.w600, size: 24, lineHeight: 32),
    titleLarge: _heading(FontWeight.w600, size: 22, lineHeight: 28),
    titleMedium: _body(FontWeight.w600, size: 16, lineHeight: 24),
    titleSmall: _body(FontWeight.w600, size: 14, lineHeight: 20),
    bodyLarge: _body(FontWeight.w400, size: 16, lineHeight: 24),
    bodyMedium: _body(FontWeight.w400, size: 14, lineHeight: 20),
    bodySmall: _body(FontWeight.w400, size: 12, lineHeight: 16),
    labelLarge: _label(size: 14, lineHeight: 20),
    labelMedium: _label(size: 12, lineHeight: 16),
    labelSmall: _label(size: 11, lineHeight: 16),
  );

  static TextStyle _heading(
    FontWeight weight, {
    required double size,
    required double lineHeight,
  }) => _style(headingFamily, weight, size, lineHeight);

  static TextStyle _body(
    FontWeight weight, {
    required double size,
    required double lineHeight,
  }) => _style(bodyFamily, weight, size, lineHeight);

  static TextStyle _label({required double size, required double lineHeight}) =>
      _style(
        bodyFamily,
        FontWeight.w500,
        size,
        lineHeight,
      ).copyWith(letterSpacing: _labelLetterSpacing);

  // O MASTER.md dá a altura de linha em dp; o TextStyle espera um
  // multiplicador do tamanho da fonte.
  static TextStyle _style(
    String family,
    FontWeight weight,
    double size,
    double lineHeight,
  ) => TextStyle(
    fontFamily: family,
    fontWeight: weight,
    fontSize: size,
    height: lineHeight / size,
    letterSpacing: 0,
  );
}
