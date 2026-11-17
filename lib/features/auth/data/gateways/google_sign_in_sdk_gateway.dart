import 'package:google_sign_in/google_sign_in.dart';

import 'auth_gateways.dart';

/// Repasse direto ao `GoogleSignIn`. O `serverClientId` vem do
/// `default_web_client_id` que o plugin do Google Services gera a partir do
/// `google-services.json`, por isso não aparece aqui.
final class GoogleSignInSdkGateway implements GoogleAccountGateway {
  GoogleSignInSdkGateway(this._signIn);

  final GoogleSignIn _signIn;

  // O `initialize` precisa rodar uma única vez e terminar antes de qualquer
  // outra chamada (documentação do `google_sign_in` 7.x).
  late final Future<void> _initialized = _signIn.initialize();

  @override
  Future<String?> authenticate() async {
    await _initialized;
    // Sem `scopeHint` nem `authorizationClient`: só a identidade básica
    // (decisão 010). O objeto da autenticação nunca vai para log, porque o
    // `toString` dele imprime o `idToken`.
    final account = await _signIn.authenticate();
    return account.authentication.idToken;
  }

  @override
  Future<void> signOut() async {
    await _initialized;
    await _signIn.signOut();
  }
}
