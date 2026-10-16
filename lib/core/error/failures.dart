/// Falhas de domínio tipadas. Dart puro: `domain/` pode importar sem conhecer
/// `http`. As mensagens nunca carregam URL, token ou `session_id`.
sealed class Failure implements Exception {
  const Failure();
}

/// Sem conexão, DNS, TLS ou timeout.
final class NetworkFailure extends Failure {
  const NetworkFailure();
}

/// 401: token do app ou sessão do usuário inválidos.
final class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure();
}

/// 404: o recurso não existe no TMDB.
final class NotFoundFailure extends Failure {
  const NotFoundFailure();
}

/// 429: limite de requisições atingido.
final class RateLimitFailure extends Failure {
  const RateLimitFailure({this.retryAfter});

  /// Vem do header `Retry-After`, que o TMDB não documenta; pode faltar.
  final Duration? retryAfter;
}

/// 5xx: falha do lado do TMDB.
final class ServerFailure extends Failure {
  const ServerFailure(this.statusCode);

  final int statusCode;
}

/// Qualquer outra resposta que o app não sabe tratar (status inesperado ou
/// corpo que não é o JSON esperado).
final class UnexpectedFailure extends Failure {
  const UnexpectedFailure(this.reason);

  final String reason;

  @override
  String toString() => 'UnexpectedFailure: $reason';
}
