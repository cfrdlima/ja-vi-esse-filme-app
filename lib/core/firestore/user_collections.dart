/// Nomes das coleções do Firestore, num lugar só. O SDK do cliente não
/// lista subcoleções, e a exclusão da conta apaga só as de [all] (decisões
/// 010 e 015).
abstract final class UserCollections {
  static const users = 'users';

  /// Um documento por filme marcado (decisão 013).
  static const movies = 'movies';

  /// As subcoleções de `users/{uid}`. Toda subcoleção nova entra aqui, nas
  /// regras e nos testes delas no mesmo ciclo. O teste
  /// `firestore/test/rules-file.test.js` confere esta lista com os `match`
  /// do `firestore.rules`.
  static const all = [movies];
}
