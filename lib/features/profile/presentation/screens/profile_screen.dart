import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../l10n/app_localizations.dart';

/// Aba Perfil. Até a conta TMDB (Fase 2), só leva à tela Sobre.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.tabProfile)),
      body: ListView(
        children: [
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
