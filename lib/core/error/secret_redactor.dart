// Do TMDB (`session_id`, `api_key`, `request_token`) e dos tokens do Firebase
// e do Google, em snake_case ou camelCase (`id_token` e `idToken`).
const _names =
    '(?:guest_)?session_id|api_key|request_token|'
    'access_?token|id_?token|refresh_?token';

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

// Token sem nome de campo por perto: JWT (o `idToken` do Google e do Firebase
// começa por `eyJ`, o `{"` em base64url) e o access token do Google (`ya29.`).
final _bareToken = RegExp(r'\beyJ[\w-]+\.[\w-]+\.[\w-]*|\bya29\.[\w-]+');

// O e-mail da conta Google não vai para log (CLAUDE.md). O domínio precisa de
// um ponto, para uma menção como `@ana` ficar como está.
final _email = RegExp(r'[\w.+-]+@[A-Za-z0-9-]+(?:\.[A-Za-z0-9-]+)+');

/// Mascara segredos do TMDB, do Firebase e do Google, e o e-mail, antes de o
/// texto ir para log ou crash reporter.
/// É a segunda barreira: rede e storage já não devem deixar o segredo chegar.
String redactSecrets(String text) => text
    .replaceAllMapped(_jsonField, (m) => '${m[1]}***"')
    .replaceAllMapped(_escapedJsonField, (m) => '${m[1]}***${m[2]}')
    .replaceAllMapped(_keyValue, (m) => '${m[1]}${m[2]}***')
    .replaceAllMapped(_bearer, (m) => '${m[1]} ***')
    .replaceAll(_bareToken, '***')
    .replaceAll(_email, '***');
