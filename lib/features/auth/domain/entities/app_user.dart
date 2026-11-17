/// Usuário logado pela conta Google no Firebase (decisão 010).
final class AppUser {
  /// Recusa com [ArgumentError] o [uid] vazio: as regras do Firestore usam o
  /// `uid` no caminho `users/{uid}`, e um vazio apontaria para outro lugar.
  AppUser({
    required this.uid,
    this.displayName,
    this.email,
    this.photoUrl,
  }) {
    // Sem o valor na mensagem: o `uid` não vai para log (CLAUDE.md).
    if (uid.trim().isEmpty) throw ArgumentError('não pode ser vazio', 'uid');
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
}
