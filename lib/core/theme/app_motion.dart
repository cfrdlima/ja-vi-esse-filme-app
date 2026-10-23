import 'package:flutter/animation.dart';

/// Durações e curvas da seção 7 do `MASTER.md`.
abstract final class AppMotion {
  static const short = Duration(milliseconds: 150);
  static const medium = Duration(milliseconds: 250);
  static const curve = Curves.easeOutCubic;

  /// Meio ciclo do pulso do skeleton (override `descobrir.md`: 1200 ms ida e
  /// volta).
  static const skeletonPulse = Duration(milliseconds: 600);
  static const skeletonCurve = Curves.easeInOut;

  /// Opacidade no fundo do pulso (a outra ponta é 1).
  static const skeletonMinOpacity = 0.5;
}
