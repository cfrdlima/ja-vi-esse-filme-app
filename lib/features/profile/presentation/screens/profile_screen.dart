import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../l10n/app_localizations.dart';
import '../widgets/account_section.dart';

/// Aba Perfil: o bloco da conta e a entrada da tela Sobre.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.tabProfile)),
      body: ListView(
        children: [
          const AccountSection(),
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
