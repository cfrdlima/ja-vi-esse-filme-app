import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/theme/app_theme_tokens.dart';
import '../../../../l10n/app_localizations.dart';
import '../widgets/account_section.dart';

/// Aba Perfil: o bloco da conta e a entrada da tela Sobre.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final spacing = Theme.of(context).extension<AppThemeTokens>()!.spacing;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.tabProfile)),
      body: ListView(
        children: [
          // Só o bloco da conta fica na largura de leitura; a lista ocupa a
          // tela toda, para rolar de qualquer ponto no tablet.
          Align(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppSizes.readableWidth,
              ),
              child: Padding(
                padding: EdgeInsets.all(spacing.md),
                child: const AccountSection(),
              ),
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(
              l10n.profileAboutEntry,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go(AppRoutes.about),
          ),
        ],
      ),
    );
  }
}
