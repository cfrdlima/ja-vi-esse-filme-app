import 'package:ja_vi_esse_filme/core/links/external_link_opener.dart';

/// Guarda as URLs pedidas e, com [failure], falha como o abridor de verdade.
final class FakeLinkOpener implements ExternalLinkOpener {
  FakeLinkOpener({this.failure});

  final LinkNotOpened? failure;
  final opened = <Uri>[];

  @override
  Future<void> open(Uri url) async {
    opened.add(url);
    if (failure case final failure?) throw failure;
  }
}
