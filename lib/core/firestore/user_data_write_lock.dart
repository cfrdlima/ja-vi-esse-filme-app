/// Trava as escritas nos dados do usuário enquanto a exclusão da conta apaga
/// os documentos (decisão 015): uma marca que chegasse ao servidor depois
/// da última leitura vazia ficaria órfã em `users/{uid}` (`/revisar` da
/// sessão 024). Um só objeto, montado no `main.dart` e compartilhado pela
/// conta e pela Estante.
final class UserDataWriteLock {
  bool _locked = false;

  bool get isLocked => _locked;

  void lock() => _locked = true;

  void unlock() => _locked = false;
}
