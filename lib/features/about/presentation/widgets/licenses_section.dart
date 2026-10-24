import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme_tokens.dart';
import '../../../../core/widgets/section_title.dart';
import '../../../../l10n/app_localizations.dart';

/// Leva à página de licenças do Flutter, que junta as dos pacotes e as das
/// fontes (`registerFontLicenses`).
class LicensesSection extends StatelessWidget {
  const LicensesSection({required this.appVersion, super.key});

  /// Vazia quando o build não a informa; aí a página não mostra versão.
  final String appVersion;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacing = theme.extension<AppThemeTokens>()!.spacing;
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(text: l10n.aboutLicensesTitle),
        SizedBox(height: spacing.sm),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.description_outlined),
          title: Text(
            l10n.aboutLicensesEntry,
            style: theme.textTheme.bodyLarge,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => showLicensePage(
            context: context,
            applicationName: l10n.appName,
            applicationVersion: appVersion.isEmpty ? null : appVersion,
          ),
        ),
      ],
    );
  }
}
