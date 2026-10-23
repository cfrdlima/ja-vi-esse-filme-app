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
}
