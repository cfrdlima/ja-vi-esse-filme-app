const _names = '(?:guest_)?session_id|api_key|request_token|access_token';

// `"session_id": "valor"`, aceitando aspas escapadas dentro do valor.
final _jsonField = RegExp(
  '("(?:$_names)"\\s*:\\s*")(?:[^"\\\\]|\\\\.)*"',
  caseSensitive: false,
);

// O mesmo campo dentro de uma string: `\"session_id\": \"valor\"`.
final _escapedJsonField = RegExp(
  '(\\\\"(?:$_names)\\\\"\\s*:\\s*\\\\")(?:[^"\\\\]|\\\\[^"])*(\\\\")',
  caseSensitive: false,
);

// Query (`=`), URL codificada (`%3D`) e `toString` de Map (`: `). O nome não
// pode ser fim de outra palavra, exceto depois de um escape `%XX` (`%3F`).
final _keyValue = RegExp(
  '(?:(?<![A-Za-z0-9])|(?<=%[0-9A-Fa-f]{2}))($_names)(=|%3D|:\\s*)[^\\s&,}\\]"\']+',
  caseSensitive: false,
);

final _bearer = RegExp(r'\b(Bearer)\s+\S+', caseSensitive: false);

/// Mascara segredos do TMDB antes de o texto ir para log ou crash reporter.
/// É a segunda barreira: rede e storage já não devem deixar o segredo chegar.
String redactSecrets(String text) => text
    .replaceAllMapped(_jsonField, (m) => '${m[1]}***"')
    .replaceAllMapped(_escapedJsonField, (m) => '${m[1]}***${m[2]}')
    .replaceAllMapped(_keyValue, (m) => '${m[1]}${m[2]}***')
    .replaceAllMapped(_bearer, (m) => '${m[1]} ***');
