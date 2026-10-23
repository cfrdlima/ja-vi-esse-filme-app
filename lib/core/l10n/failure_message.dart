import '../../l10n/app_localizations.dart';
import '../error/failures.dart';

/// Texto de UI de uma falha de domínio (decisão 004: o domínio não tem texto).
/// Nunca mostra o detalhe técnico da falha.
String failureMessage(AppLocalizations l10n, Failure failure) =>
    switch (failure) {
      NetworkFailure() => l10n.failureNetwork,
      RateLimitFailure() => l10n.failureRateLimit,
      UnauthorizedFailure() ||
      NotFoundFailure() ||
      ServerFailure() ||
      UnexpectedFailure() => l10n.failureGeneric,
    };
