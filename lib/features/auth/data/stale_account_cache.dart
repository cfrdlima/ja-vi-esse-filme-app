import '../domain/entities/auth_state.dart';
import 'gateways/auth_gateways.dart';

/// Limpa no início do app o cache de uma conta que já saiu (`security-auditor`
/// da sessão 022). Se a limpeza do logout falhou e o app fechou antes do
/// "tentar de novo", o cache da conta ficaria no aparelho para sempre.
///
/// Só limpa quando o primeiro estado da conta é deslogado: aí nada leu o
/// Firestore ainda, porque deslogado a Estante não o assina. Uma falha (a
/// pessoa entrou rápido, e a instância já começou) fica para o próximo
/// início, sem derrubar o app.
Future<void> clearStaleAccountCache({
  required Stream<AuthState> account,
  required AccountCacheGateway cache,
}) async {
  final AuthState first;
  try {
    first = await account.first;
  } on Exception {
    return;
  }
  if (first is! SignedOut) return;
  try {
    await cache.clearUnused();
  } on Exception {
    return;
  }
}
