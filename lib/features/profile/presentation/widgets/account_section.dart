import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../auth/presentation/state/session_notifier.dart';
import '../../../auth/presentation/state/session_state.dart';
import '../../../auth/presentation/widgets/google_sign_in_button.dart';
import 'account_skeleton.dart';
import 'signed_out_panel.dart';

/// Bloco da conta no Perfil, que segue o estado da sessão.
class AccountSection extends StatelessWidget {
  const AccountSection({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.select<SessionNotifier, SessionState>(
      (notifier) => notifier.state,
    );
    return switch (state) {
      SessionLoading() => const AccountSkeleton(),
      SessionSignedOut() => SignedOutPanel(
        action: GoogleSignInButton(
          onPressed: () => unawaited(context.read<SessionNotifier>().signIn()),
        ),
      ),
      SessionSigningIn() => const SignedOutPanel(
        action: GoogleSignInButton.loading(),
      ),
      _ => const SizedBox.shrink(),
    };
  }
}
