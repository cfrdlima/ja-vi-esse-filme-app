import 'package:flutter/material.dart';

import '../../../../core/theme/app_sizes.dart';
import '../../../../core/theme/app_theme_tokens.dart';
import '../../../../core/widgets/skeleton_pulse.dart';
import 'poster_skeleton.dart';

/// Padding e delegate comuns às grades de pôsteres (Descobrir, Buscar e
/// Estante) e ao skeleton delas, para o layout não pular entre os estados.
abstract final class PosterGrid {
  static EdgeInsets padding(AppThemeTokens tokens) =>
      EdgeInsets.all(tokens.spacing.md);

  static SliverGridDelegate delegate(AppThemeTokens tokens) =>
      SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: AppSizes.posterGridMaxExtent,
        childAspectRatio: 2 / 3,
        mainAxisSpacing: tokens.spacing.sm,
        crossAxisSpacing: tokens.spacing.sm,
      );
}

/// Só monta a grade quando sobra largura depois do padding. O Android pode
/// fazer o primeiro layout com a janela ainda sem largura, e o
/// `SliverGridDelegateWithMaxCrossAxisExtent` não aceita largura zero.
class PosterGridWidthGuard extends StatelessWidget {
  const PosterGridWidthGuard({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;
    final horizontalPadding = PosterGrid.padding(tokens).horizontal;
    return LayoutBuilder(
      builder: (_, constraints) => constraints.maxWidth > horizontalPadding
          ? child
          : const SizedBox.shrink(),
    );
  }
}

/// Grade de skeleton, com todas as células no mesmo pulso, anunciada ao
/// leitor de tela com [label].
class PosterGridSkeleton extends StatelessWidget {
  const PosterGridSkeleton({required this.label, super.key});

  final String label;

  static const _cellCount = 12;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;
    return PosterGridWidthGuard(
      child: Semantics(
        label: label,
        liveRegion: true,
        child: ExcludeSemantics(
          child: SkeletonPulse(
            builder: (_, opacity) => GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              padding: PosterGrid.padding(tokens),
              gridDelegate: PosterGrid.delegate(tokens),
              itemCount: _cellCount,
              itemBuilder: (_, _) => PosterSkeleton(opacity: opacity),
            ),
          ),
        ),
      ),
    );
  }
}
