import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/l10n/failure_message.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/state/session_notifier.dart';
import '../../../auth/presentation/state/session_state.dart';
import '../../../auth/presentation/widgets/google_sign_in_button.dart';
import 'account_skeleton.dart';
import 'sign_out_failed_panel.dart';
import 'signed_in_panel.dart';
import 'signed_out_panel.dart';

/// Bloco da conta no Perfil, que segue o estado da sessão.
class AccountSection extends StatelessWidget {
  const AccountSection({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.select<SessionNotifier, SessionState>(
      (notifier) => notifier.state,
    );
    final signInButton = GoogleSignInButton(
      onPressed: () => unawaited(context.read<SessionNotifier>().signIn()),
    );
    return switch (state) {
      SessionLoading() => const AccountSkeleton(),
      SessionSignedOut() => SignedOutPanel(action: signInButton),
      SessionSigningIn() => const SignedOutPanel(
        action: GoogleSignInButton.loading(),
      ),
      SessionSignInFailed(:final failure) => SignedOutPanel(
        error: failureMessage(AppLocalizations.of(context), failure),
        action: signInButton,
      ),
      SessionSignedIn(:final user) => SignedInPanel(
        user: user,
        action: const _SignOutButton(),
      ),
      SessionSignOutFailed(:final failure) => SignOutFailedPanel(
        message: failureMessage(AppLocalizations.of(context), failure),
        onRetry: () => unawaited(context.read<SessionNotifier>().signOut()),
      ),
    };
  }
}

class _SignOutButton extends StatelessWidget {
  const _SignOutButton();

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () => unawaited(context.read<SessionNotifier>().signOut()),
      icon: const Icon(Icons.logout),
      label: Text(AppLocalizations.of(context).profileSignOut),
    );
  }
}
