import 'failures.dart';

/// Quanto esperar antes de deixar tentar de novo: o `retryAfter` de um 429, ou
/// nada.
Duration retryWaitOf(Failure failure) => switch (failure) {
  RateLimitFailure(:final retryAfter?) => retryAfter,
  _ => Duration.zero,
};
