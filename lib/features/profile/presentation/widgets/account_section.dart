import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/l10n/failure_message.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/state/session_notifier.dart';
import '../../../auth/presentation/state/session_state.dart';
import '../../../auth/presentation/widgets/google_sign_in_button.dart';
import 'account_skeleton.dart';
import 'sign_out_failed_panel.dart';
import 'signed_in_panel.dart';
import 'signed_out_panel.dart';
import 'unsynced_sign_out_prompt.dart';

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
    final panel = switch (state) {
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
        action: SignOutButton(
          onPressed: () => unawaited(context.read<SessionNotifier>().signOut()),
        ),
      ),
      SessionSigningOut(:final user) => SignedInPanel(
        user: user,
        action: const SignOutButton.loading(),
      ),
      SessionUnsyncedSignOut(:final user) => SignedInPanel(
        user: user,
        action: UnsyncedSignOutPrompt(
          onConfirm: context.read<SessionNotifier>().confirmSignOut,
          onCancel: context.read<SessionNotifier>().cancelSignOut,
        ),
      ),
      SessionDeletingAccount(:final user) => SignedInPanel(
        user: user,
        action: const SignOutButton.loading(),
      ),
      SessionDeleteAccountFailed(:final user) => SignedInPanel(
        user: user,
        action: SignOutButton(
          onPressed: () => unawaited(context.read<SessionNotifier>().signOut()),
        ),
      ),
      SessionSignOutFailed(:final failure) => SignOutFailedPanel(
        message: failureMessage(AppLocalizations.of(context), failure),
        onRetry: () => unawaited(context.read<SessionNotifier>().signOut()),
      ),
    };
    // A troca de estado não é instantânea (MASTER.md §7), exceto com o
    // "reduzir movimento" ligado.
    return AnimatedSwitcher(
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : AppMotion.medium,
      child: KeyedSubtree(key: ValueKey(_layoutOf(state)), child: panel),
    );
  }

  // Deslogado, entrando e falha no login têm o mesmo layout: só o botão e a
  // mensagem mudam, sem refazer a transição do bloco inteiro.
  static String _layoutOf(SessionState state) => switch (state) {
    SessionLoading() => 'loading',
    SessionSignedOut() ||
    SessionSigningIn() ||
    SessionSignInFailed() => 'signedOut',
    SessionSignedIn() ||
    SessionSigningOut() ||
    SessionUnsyncedSignOut() ||
    SessionDeletingAccount() ||
    SessionDeleteAccountFailed() => 'signedIn',
    SessionSignOutFailed() => 'signOutFailed',
  };
}
