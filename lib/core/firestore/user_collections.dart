/// Nomes das coleções do Firestore, num lugar só. O SDK do cliente não
/// lista subcoleções, e a exclusão da conta apaga só as de [all] (decisões
/// 010 e 015).
abstract final class UserCollections {
  static const users = 'users';

  /// Um documento por filme marcado (decisão 013).
  static const movies = 'movies';

  /// Uma lista personalizada, só com o nome. Os filmes dela ficam no mapa
  /// `lists` do documento do filme (decisão 019).
  static const lists = 'lists';

  /// As subcoleções de `users/{uid}`. Toda subcoleção nova entra aqui, nas
  /// regras e nos testes delas no mesmo ciclo. O teste
  /// `firestore/test/rules-file.test.js` confere esta lista com os `match`
  /// do `firestore.rules`. Só um nível: nenhuma subcoleção tem outra dentro
  /// (decisão 019).
  static const all = [movies, lists];
}
