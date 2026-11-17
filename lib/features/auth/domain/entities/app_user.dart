/// Usuário logado pela conta Google no Firebase (decisão 010).
final class AppUser {
  const AppUser({
    required this.uid,
    this.displayName,
    this.email,
    this.photoUrl,
  });

  final String uid;

  /// A conta Google pode não ter nome nem foto públicos.
  final String? displayName;
  final String? email;
  final String? photoUrl;
}
