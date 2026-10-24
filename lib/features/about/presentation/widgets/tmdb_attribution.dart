import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../../../../core/theme/app_sizes.dart';
import '../../../../core/theme/app_theme_tokens.dart';
import '../../../../core/widgets/section_title.dart';
import '../../../../l10n/app_localizations.dart';

/// Atribuição que os termos do TMDB exigem (§3): o logo, menor que o nome
/// do app, e o aviso de não endosso.
class TmdbAttribution extends StatelessWidget {
  const TmdbAttribution({super.key});

  /// Texto exato dos termos, fora do ARB: traduzir mudaria o aviso que os
  /// termos pedem. A tradução vem logo antes, do ARB.
  static const noticeOriginal =
      'This application uses TMDB and the TMDB APIs but is not endorsed, '
      'certified, or otherwise approved by TMDB.';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacing = theme.extension<AppThemeTokens>()!.spacing;
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(text: l10n.aboutTmdbTitle),
        SizedBox(height: spacing.sm),
        Semantics(
          label: l10n.aboutTmdbLogoSemantics,
          image: true,
          excludeSemantics: true,
          child: Image.asset(
            'assets/images/tmdb_logo.png',
            width: AppSizes.tmdbLogoWidth,
          ),
        ),
        SizedBox(height: spacing.md),
        Text(l10n.aboutTmdbNotice, style: theme.textTheme.bodyMedium),
        SizedBox(height: spacing.sm),
        Semantics(
          // Para o leitor de tela pronunciar em inglês, e não com a voz pt-BR.
          attributedLabel: AttributedString(
            noticeOriginal,
            attributes: [
              LocaleStringAttribute(
                range: const TextRange(start: 0, end: noticeOriginal.length),
                locale: const Locale('en'),
              ),
            ],
          ),
          excludeSemantics: true,
          child: Text(
            noticeOriginal,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}
