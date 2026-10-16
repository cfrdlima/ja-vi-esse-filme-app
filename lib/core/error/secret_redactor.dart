final _secretParam = RegExp(r'\b(api_key|session_id|request_token)=[^&\s]+');
final _bearerToken = RegExp(r'\bBearer\s+\S+');

/// Mascara segredos do TMDB antes de o texto ir para log ou crash reporter.
String redactSecrets(String text) => text
    .replaceAllMapped(_secretParam, (match) => '${match[1]}=***')
    .replaceAll(_bearerToken, 'Bearer ***');
