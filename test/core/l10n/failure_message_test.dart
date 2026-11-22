import 'package:flutter_test/flutter_test.dart';
import 'package:ja_vi_esse_filme/core/error/failures.dart';
import 'package:ja_vi_esse_filme/core/l10n/app_locale.dart';
import 'package:ja_vi_esse_filme/core/l10n/failure_message.dart';
import 'package:ja_vi_esse_filme/l10n/app_localizations.dart';

void main() {
  final l10n = lookupAppLocalizations(AppLocale.locale);

  test('deve explicar a falta de rede', () {
    expect(failureMessage(l10n, const NetworkFailure()), l10n.failureNetwork);
  });

  test('deve pedir para esperar no limite de requisições', () {
    expect(
      failureMessage(l10n, const RateLimitFailure()),
      l10n.failureRateLimit,
    );
  });

  test('deve avisar que a conta foi desativada', () {
    expect(
      failureMessage(l10n, const AccountDisabledFailure()),
      l10n.failureAccountDisabled,
    );
  });

  test('deve pedir para entrar de novo antes de uma ação sensível', () {
    expect(
      failureMessage(l10n, const RecentLoginRequiredFailure()),
      l10n.failureRecentLoginRequired,
    );
  });

  test('deve pedir para entrar antes de uma ação que precisa de conta', () {
    expect(
      failureMessage(l10n, const SignInRequiredFailure()),
      l10n.failureSignInRequired,
    );
  });

  test('deve avisar que a conta chegou ao teto de listas', () {
    expect(
      failureMessage(l10n, const ListLimitFailure()),
      l10n.failureListLimit,
    );
  });

  test('deve avisar que a lista está cheia', () {
    expect(failureMessage(l10n, const ListFullFailure()), l10n.failureListFull);
  });

  test('deve usar a mensagem genérica nas outras falhas', () {
    const others = <Failure>[
      UnauthorizedFailure(),
      NotFoundFailure(),
      ServerFailure(503),
      UnexpectedFailure('teste'),
    ];

    expect(
      others.map((f) => failureMessage(l10n, f)),
      everyElement(l10n.failureGeneric),
    );
  });

  // A mesma mensagem cobre as falhas do TMDB e as da conta (Firebase).
  test('deve usar uma mensagem genérica que não cita o TMDB', () {
    expect(l10n.failureGeneric, isNot(contains('TMDB')));
  });
}
