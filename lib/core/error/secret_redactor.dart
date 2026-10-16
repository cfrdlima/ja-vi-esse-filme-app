const _secretNames = 'api_key|session_id|request_token';
final _secretParam = RegExp('\\b($_secretNames)=[^&\\s]+');
final _secretJsonField = RegExp('"($_secretNames)"\\s*:\\s*"[^"]*"');
final _bearerToken = RegExp(r'\bBearer\s+\S+');

/// Mascara segredos do TMDB antes de o texto ir para log ou crash reporter.
/// Cobre query string, campos JSON (resposta da criação de sessão) e o header
/// `Authorization: Bearer`.
String redactSecrets(String text) => text
    .replaceAllMapped(_secretParam, (match) => '${match[1]}=***')
    .replaceAllMapped(_secretJsonField, (match) => '"${match[1]}": "***"')
    .replaceAll(_bearerToken, 'Bearer ***');
