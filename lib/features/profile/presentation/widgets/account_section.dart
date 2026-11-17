import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../auth/presentation/state/session_notifier.dart';
import '../../../auth/presentation/state/session_state.dart';
import 'account_skeleton.dart';

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
      _ => const SizedBox.shrink(),
    };
  }
}
