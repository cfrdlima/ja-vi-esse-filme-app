import 'failures.dart';

/// O `Retry-After` vem do servidor; um valor enorme não pode travar o app.
const maxRetryWait = Duration(seconds: 60);

/// Quanto esperar antes de deixar tentar de novo: o `retryAfter` de um 429, ou
/// nada.
Duration retryWaitOf(Failure failure) => switch (failure) {
  RateLimitFailure(:final retryAfter?) => retryAfter,
  _ => Duration.zero,
};
