import 'package:flutter/material.dart';

import '../../../../core/theme/app_sizes.dart';
import '../../../../core/theme/app_theme_tokens.dart';
import '../../../../core/widgets/skeleton_pulse.dart';
import '../../../../l10n/app_localizations.dart';

/// Bloco da conta enquanto o primeiro estado dela não chega: o círculo do
/// avatar e duas barras, no lugar do nome e do e-mail (override `perfil.md`).
class AccountSkeleton extends StatelessWidget {
  const AccountSkeleton({super.key});

  static const _lineWidths = [0.6, 0.8];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final color = theme.colorScheme.surfaceContainer;
    return Semantics(
      label: AppLocalizations.of(context).profileAccountLoading,
      liveRegion: true,
      child: ExcludeSemantics(
        child: SkeletonPulse(
          builder: (_, opacity) => FadeTransition(
            opacity: opacity,
            child: Row(
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                  child: const SizedBox.square(
                    dimension: AppSizes.profileAvatar,
                  ),
                ),
                SizedBox(width: tokens.spacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final width in _lineWidths)
                        Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: tokens.spacing.xs,
                          ),
                          child: FractionallySizedBox(
                            widthFactor: width,
                            child: Container(
                              height: tokens.spacing.md,
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(
                                  tokens.radii.sm,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
