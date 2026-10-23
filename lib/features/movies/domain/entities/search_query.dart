/// Termo de busca de filmes já normalizado e dentro dos limites.
final class SearchQuery {
  /// Recusa com [InvalidSearchQuery] o termo fora de [minLength] e
  /// [maxLength] depois de normalizado.
  factory SearchQuery(String raw) {
    final text = raw.trim().replaceAll(_whitespace, ' ');
    // Conta code points, e não unidades UTF-16: um emoji vale um caractere.
    final length = text.runes.length;
    if (length < minLength) {
      throw const InvalidSearchQuery(InvalidSearchQueryReason.tooShort);
    }
    if (length > maxLength) {
      throw const InvalidSearchQuery(InvalidSearchQueryReason.tooLong);
    }
    return SearchQuery._(text);
  }

  const SearchQuery._(this.text);

  static const minLength = 2;
  static const maxLength = 100;

  static final _whitespace = RegExp(r'\s+');

  final String text;

  @override
  bool operator ==(Object other) => other is SearchQuery && other.text == text;

  @override
  int get hashCode => text.hashCode;

  // Sem o termo: o que a pessoa busca não vai para log nem relatório de erro
  // (política de privacidade, seção 2).
  @override
  String toString() => 'SearchQuery(${text.runes.length} caracteres)';
}

enum InvalidSearchQueryReason { tooShort, tooLong }

/// O termo digitado não serve para buscar.
final class InvalidSearchQuery implements Exception {
  const InvalidSearchQuery(this.reason);

  final InvalidSearchQueryReason reason;

  @override
  String toString() => 'InvalidSearchQuery: ${reason.name}';
}
