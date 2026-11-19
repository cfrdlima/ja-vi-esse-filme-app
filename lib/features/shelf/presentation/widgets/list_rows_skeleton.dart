import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme_tokens.dart';
import '../../../../core/widgets/skeleton_pulse.dart';

/// Skeleton de linhas, para a aba Listas e a folha Adicionar à lista
/// (override `estante.md`): o mesmo pulso dos pôsteres.
class ListRowsSkeleton extends StatelessWidget {
  const ListRowsSkeleton({required this.label, this.rows = 6, super.key});

  final String label;
  final int rows;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    return Semantics(
      label: label,
      liveRegion: true,
      child: ExcludeSemantics(
        child: SkeletonPulse(
          builder: (_, opacity) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < rows; i++)
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: tokens.spacing.md,
                    vertical: tokens.spacing.xs,
                  ),
                  child: FadeTransition(
                    opacity: opacity,
                    child: Container(
                      height: kMinInteractiveDimension,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainer,
                        borderRadius: BorderRadius.circular(tokens.radii.md),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
