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

/// 429 do TMDB, ou `too-many-requests` do Firebase Auth: limite de
/// requisições atingido.
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

/// Login recusado porque a conta foi desativada no Firebase Auth.
final class AccountDisabledFailure extends Failure {
  const AccountDisabledFailure();
}

/// Ação sensível (como excluir a conta) que exige um login recente. A pessoa
/// entra de novo com o Google e tenta outra vez.
final class RecentLoginRequiredFailure extends Failure {
  const RecentLoginRequiredFailure();
}

/// Qualquer outra resposta que o app não sabe tratar (status inesperado ou
/// corpo que não é o JSON esperado).
final class UnexpectedFailure extends Failure {
  const UnexpectedFailure(this.reason);

  /// Texto fixo escrito no código, que vai para o `toString` e para o log.
  /// Nunca receba aqui corpo de resposta, URL ou mensagem de outra exceção.
  final String reason;

  @override
  String toString() => 'UnexpectedFailure: $reason';
}
