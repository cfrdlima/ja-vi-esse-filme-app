/// Como terminou um pedido de exclusão da conta. Fechar o seletor do Google
/// na reautenticação é um resultado esperado, e não uma falha (decisão 015).
sealed class AccountDeletionOutcome {
  const AccountDeletionOutcome();
}

/// A conta e os documentos dela foram apagados.
final class AccountDeleted extends AccountDeletionOutcome {
  const AccountDeleted();

  // Igual por tipo, como o `SignInCancelled`.
  @override
  bool operator ==(Object other) => other is AccountDeleted;

  @override
  int get hashCode => (AccountDeleted).hashCode;
}

/// A pessoa fechou o seletor do Google, e nada foi apagado.
final class AccountDeletionCancelled extends AccountDeletionOutcome {
  const AccountDeletionCancelled();

  @override
  bool operator ==(Object other) => other is AccountDeletionCancelled;

  @override
  int get hashCode => (AccountDeletionCancelled).hashCode;
}
