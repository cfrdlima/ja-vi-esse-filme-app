import 'package:flutter/material.dart';

import '../../../../core/theme/app_sizes.dart';
import '../../../../core/theme/app_theme_tokens.dart';
import '../../../../l10n/app_localizations.dart';
import '../widgets/tmdb_attribution.dart';

/// Atribuição ao TMDB, política de privacidade e licenças (override
/// `sobre.md`). É estática: não pede nada à rede.
class AboutScreen extends StatelessWidget {
  const AboutScreen({required this.appVersion, super.key});

  /// Vem do build (`APP_VERSION`); vazia quando o build não a informa.
  final String appVersion;

  @override
  Widget build(BuildContext context) {
    final spacing = Theme.of(context).extension<AppThemeTokens>()!.spacing;
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context).aboutTitle)),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(spacing.md),
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AppSizes.readableWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _AppIdentity(appVersion: appVersion),
                SizedBox(height: spacing.lg),
                const TmdbAttribution(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AppIdentity extends StatelessWidget {
  const _AppIdentity({required this.appVersion});

  final String appVersion;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.appName, style: theme.textTheme.headlineSmall),
        if (appVersion.isNotEmpty)
          Text(
            l10n.aboutVersion(appVersion),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
      ],
    );
  }
}
