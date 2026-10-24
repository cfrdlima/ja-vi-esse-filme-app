import 'package:flutter/material.dart';

import '../../../../core/links/app_links.dart';
import '../../../../core/theme/app_theme_tokens.dart';
import '../../../../core/widgets/external_link_tile.dart';
import '../../../../core/widgets/section_title.dart';
import '../../../../l10n/app_localizations.dart';

/// Resumo da política de privacidade e o link para a versão publicada
/// (decisão 006), que abre fora do app.
class PrivacySection extends StatelessWidget {
  const PrivacySection({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacing = theme.extension<AppThemeTokens>()!.spacing;
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(text: l10n.aboutPrivacyTitle),
        SizedBox(height: spacing.sm),
        Text(l10n.aboutPrivacySummary, style: theme.textTheme.bodyMedium),
        SizedBox(height: spacing.sm),
        ExternalLinkTile(
          url: AppLinks.privacyPolicy,
          icon: Icons.privacy_tip_outlined,
          title: l10n.aboutPrivacyPolicyLink,
          subtitle: l10n.aboutPrivacyPolicySubtitle,
          semanticsLabel: l10n.aboutPrivacyPolicySemantics,
          failureMessage: l10n.aboutPrivacyPolicyOpenFailed,
        ),
      ],
    );
  }
}
