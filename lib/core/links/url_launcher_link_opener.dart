import 'package:url_launcher/url_launcher.dart';

import 'external_link_opener.dart';
import 'external_link_policy.dart';

/// Assinatura do `launchUrl` do plugin, para os testes não chamarem o
/// platform channel.
typedef LaunchUrl = Future<bool> Function(Uri url, {LaunchMode mode});

/// [ExternalLinkOpener] sobre o `url_launcher` (decisão 009).
final class UrlLauncherLinkOpener implements ExternalLinkOpener {
  UrlLauncherLinkOpener({
    this._launch = launchUrl,
    this._policy = ExternalLinkPolicy.app,
  });

  final LaunchUrl _launch;
  final ExternalLinkPolicy _policy;

  // Sem `canLaunchUrl`: ele pediria `<queries>` no manifest, e o
  // `launchUrl` já diz se abriu.
  @override
  Future<void> open(Uri url) async {
    if (!_policy.allows(url)) {
      throw const LinkNotOpened(LinkNotOpenedReason.blocked);
    }
    final bool opened;
    // O contrato promete só `LinkNotOpened`. Além da `PlatformException`, o
    // plugin lança `ArgumentError` e afins, que não podem escapar do toque.
    try {
      opened = await _launch(url, mode: LaunchMode.externalApplication);
    } on Object {
      throw const LinkNotOpened(LinkNotOpenedReason.noApp);
    }
    if (!opened) throw const LinkNotOpened(LinkNotOpenedReason.noApp);
  }
}
