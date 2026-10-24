/// Por que um link externo não abriu.
enum LinkNotOpenedReason {
  /// A URL não passou na `ExternalLinkPolicy`.
  blocked,

  /// Nenhum app do aparelho abriu a URL.
  noApp,
}

/// Falha ao abrir um link fora do app. Não carrega a URL, para ela não ir
/// para log.
final class LinkNotOpened implements Exception {
  const LinkNotOpened(this.reason);

  final LinkNotOpenedReason reason;

  @override
  String toString() => 'LinkNotOpened: ${reason.name}';
}

/// Abre URLs fora do app. Widgets e estado dependem só disto, e os testes
/// trocam por um fake.
abstract interface class ExternalLinkOpener {
  /// Lança [LinkNotOpened] quando a URL é recusada ou nenhum app a abre.
  Future<void> open(Uri url);
}
