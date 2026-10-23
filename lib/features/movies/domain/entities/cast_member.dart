/// Pessoa do elenco de um filme, no papel que fez nele.
final class CastMember {
  const CastMember({
    required this.id,
    required this.name,
    required this.character,
    this.profilePath,
  });

  final int id;
  final String name;

  /// Vazio quando o TMDB não informa o personagem.
  final String character;

  /// Caminho da foto no TMDB, ou `null` quando não há foto.
  final String? profilePath;
}
