import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme_tokens.dart';

/// Célula 2:3 de carregamento, com o mesmo formato do pôster. A opacidade
/// vem de fora, para a grade inteira pulsar com um controller só.
class PosterSkeleton extends StatelessWidget {
  const PosterSkeleton({required this.opacity, super.key});

  final Animation<double> opacity;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final radii = theme.extension<AppThemeTokens>()!.radii;
    return FadeTransition(
      opacity: opacity,
      child: AspectRatio(
        aspectRatio: 2 / 3,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(radii.md),
          ),
        ),
      ),
    );
  }
}
