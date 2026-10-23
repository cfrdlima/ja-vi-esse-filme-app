import 'package:flutter/material.dart';

import '../../../../core/theme/app_sizes.dart';
import '../../../../core/theme/app_theme_tokens.dart';
import '../../../../l10n/app_localizations.dart';
import 'poster_skeleton.dart';
import 'skeleton_pulse.dart';

/// Carregando dos detalhes: o pôster, as linhas do cabeçalho e um bloco de
/// parágrafo, no lugar em que o conteúdo vai aparecer.
class MovieDetailsSkeleton extends StatelessWidget {
  const MovieDetailsSkeleton({super.key});

  static const _headerLines = [1.0, 0.6, 0.4];
  static const _paragraphLines = [1.0, 1.0, 1.0, 0.7];

  @override
  Widget build(BuildContext context) {
    final spacing = Theme.of(context).extension<AppThemeTokens>()!.spacing;
    return Semantics(
      label: AppLocalizations.of(context).movieDetailsLoading,
      liveRegion: true,
      child: ExcludeSemantics(
        child: SkeletonPulse(
          builder: (_, opacity) => SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.all(spacing.md),
            // A mesma largura máxima do conteúdo, para nada pular de lugar
            // no tablet quando o filme chega.
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppSizes.readableWidth,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: AppSizes.detailsPosterWidth,
                          child: PosterSkeleton(opacity: opacity),
                        ),
                        SizedBox(width: spacing.md),
                        Expanded(
                          child: _Lines(widths: _headerLines, opacity: opacity),
                        ),
                      ],
                    ),
                    SizedBox(height: spacing.lg),
                    _Lines(widths: _paragraphLines, opacity: opacity),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Barras com a altura de uma linha de texto, cada uma com uma fração da
/// largura disponível.
class _Lines extends StatelessWidget {
  const _Lines({required this.widths, required this.opacity});

  final List<double> widths;
  final Animation<double> opacity;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    return FadeTransition(
      opacity: opacity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final width in widths)
            Padding(
              padding: EdgeInsets.only(bottom: tokens.spacing.sm),
              child: FractionallySizedBox(
                widthFactor: width,
                child: Container(
                  height: tokens.spacing.md,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(tokens.radii.sm),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
