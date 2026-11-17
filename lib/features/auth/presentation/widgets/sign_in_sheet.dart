import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/l10n/failure_message.dart';
import '../../../../core/theme/app_theme_tokens.dart';
import '../../../../l10n/app_localizations.dart';
import '../state/session_notifier.dart';
import '../state/session_state.dart';
import 'google_sign_in_button.dart';

/// Abre a folha de login e completa com verdadeiro se a pessoa entrou. Fechar
/// a folha sem entrar completa com falso.
Future<bool> showSignInSheet(BuildContext context) async {
  final radius = Theme.of(context).extension<AppThemeTokens>()!.radii.lg;
  final signedIn = await showModalBottomSheet<bool>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(radius)),
    ),
    builder: (_) => const SignInSheet(),
  );
  return signedIn ?? false;
}

/// Folha de login para uma ação que precisa de conta (override
/// `detalhes.md`, "Folha de login"). Fecha sozinha quando a conta entra.
class SignInSheet extends StatefulWidget {
  const SignInSheet({super.key});

  @override
  State<SignInSheet> createState() => _SignInSheetState();
}

class _SignInSheetState extends State<SignInSheet> {
  late final SessionNotifier _session = context.read<SessionNotifier>();
  bool _closed = false;

  @override
  void initState() {
    super.initState();
    _session.addListener(_closeWhenSignedIn);
  }

  @override
  void dispose() {
    _session.removeListener(_closeWhenSignedIn);
    super.dispose();
  }

  void _closeWhenSignedIn() {
    if (_closed || _session.state is! SessionSignedIn) return;
    _closed = true;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacing = theme.extension<AppThemeTokens>()!.spacing;
    final l10n = AppLocalizations.of(context);
    final state = context.watch<SessionNotifier>().state;
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(spacing.lg, 0, spacing.lg, spacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(
                      l10n.signInSheetTitle,
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                ),
                const CloseButton(),
              ],
            ),
            SizedBox(height: spacing.sm),
            Text(
              l10n.signInSheetBody,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: spacing.lg),
            if (state case SessionSignInFailed(:final failure)) ...[
              Semantics(
                liveRegion: true,
                child: Text(
                  failureMessage(l10n, failure),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ),
              SizedBox(height: spacing.md),
            ],
            Center(
              child: state is SessionSigningIn
                  ? const GoogleSignInButton.loading()
                  : GoogleSignInButton(
                      onPressed: () => unawaited(_session.signIn()),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
