/// Usuário logado pela conta Google no Firebase (decisão 010).
final class AppUser {
  /// Recusa com [ArgumentError] o [uid] vazio, com `/` ou com espaço nas
  /// pontas: as regras do Firestore usam o `uid` no caminho `users/{uid}`, e
  /// qualquer um deles apontaria para outro documento.
  AppUser({required this.uid, this.displayName, this.email, this.photoUrl}) {
    // Sem o valor na mensagem: o `uid` não vai para log (CLAUDE.md).
    if (uid.trim().isEmpty) throw ArgumentError('não pode ser vazio', 'uid');
    if (uid.contains('/')) throw ArgumentError('não pode ter barra', 'uid');
    if (uid.trim() != uid) {
      throw ArgumentError('não pode ter espaço nas pontas', 'uid');
    }
  }

  final String uid;

  /// A conta Google pode não ter nome nem foto públicos.
  final String? displayName;
  final String? email;
  final String? photoUrl;

  @override
  bool operator ==(Object other) =>
      other is AppUser &&
      other.uid == uid &&
      other.displayName == displayName &&
      other.email == email &&
      other.photoUrl == photoUrl;

  @override
  int get hashCode => Object.hash(uid, displayName, email, photoUrl);

  // Sem nenhum campo: nome, e-mail, foto e `uid` não vão para log nem para
  // relatório de erro (CLAUDE.md, segurança).
  @override
  String toString() => 'AppUser(dados ocultos)';
}
