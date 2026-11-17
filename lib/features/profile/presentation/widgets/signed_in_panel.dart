import 'package:flutter/material.dart';

import '../../../../core/theme/app_sizes.dart';
import '../../../../core/theme/app_theme_tokens.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/domain/entities/app_user.dart';
import 'account_avatar.dart';

/// Bloco da conta logada: nome, e-mail e a ação de sair (override
/// `perfil.md`). A [action] é o [SignOutButton], pronto ou saindo, ou o
/// aviso das marcas sem sincronizar.
class SignedInPanel extends StatelessWidget {
  const SignedInPanel({required this.user, required this.action, super.key});

  final AppUser user;

  final Widget action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacing = theme.extension<AppThemeTokens>()!.spacing;
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            AccountAvatar(user: user),
            SizedBox(width: spacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.displayName ?? l10n.profileUnnamedAccount,
                    style: theme.textTheme.titleLarge,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (user.email case final email?)
                    Text(
                      email,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: spacing.lg),
        action,
      ],
    );
  }
}

/// O "Sair" do Perfil. Enquanto o app espera as marcas chegarem ao servidor,
/// fica desabilitado com "Saindo" e o indicador no lugar do ícone.
class SignOutButton extends StatelessWidget {
  const SignOutButton({required VoidCallback this.onPressed, super.key});

  const SignOutButton.loading({super.key}) : onPressed = null;

  /// `null` só no [SignOutButton.loading].
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final loading = onPressed == null;
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: loading
          ? const SizedBox.square(
              dimension: AppSizes.buttonProgress,
              child: CircularProgressIndicator(
                strokeWidth: AppSizes.buttonProgressStroke,
              ),
            )
          : const Icon(Icons.logout),
      label: Text(loading ? l10n.profileSigningOut : l10n.profileSignOut),
    );
  }
}
