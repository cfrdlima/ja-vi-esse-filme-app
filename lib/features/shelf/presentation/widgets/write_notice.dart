import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/l10n/failure_message.dart';
import '../../../../core/widgets/action_snack_bar.dart';
import '../../../../l10n/app_localizations.dart';

/// Roda a [action] e, se ela falhar, mostra a falha num `SnackBar` com
/// "tentar de novo", que roda a [action] outra vez. Com [onSuccess], mostra
/// também o aviso do sucesso.
///
/// Recebe o [messenger] e o [l10n] já pegos, e não o contexto: a tela pode
/// sair antes de o servidor responder.
Future<void> runWithNotice(
  ScaffoldMessengerState messenger,
  AppLocalizations l10n,
  Future<void> Function() action, {
  SnackBar? onSuccess,
}) async {
  try {
    await action();
    if (onSuccess != null) messenger.showSnackBar(onSuccess);
  } on Failure catch (failure) {
    messenger.showSnackBar(
      actionSnackBar(
        messenger: messenger,
        message: failureMessage(l10n, failure),
        actionLabel: l10n.retry,
        onAction: () => unawaited(
          runWithNotice(messenger, l10n, action, onSuccess: onSuccess),
        ),
      ),
    );
  }
}
