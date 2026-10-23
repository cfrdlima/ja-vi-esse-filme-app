import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ja_vi_esse_filme/core/links/external_link_opener.dart';
import 'package:ja_vi_esse_filme/core/links/url_launcher_link_opener.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  final trailerUrl = Uri.parse('https://www.youtube.com/watch?v=Way9Dexny3w');
  final blockedUrl = Uri.parse('https://example.com/watch?v=Way9Dexny3w');

  late List<(Uri, LaunchMode)> launched;

  UrlLauncherLinkOpener openerWhoseLaunch(Future<bool> Function() result) =>
      UrlLauncherLinkOpener(
        launch: (url, {mode = LaunchMode.platformDefault}) {
          launched.add((url, mode));
          return result();
        },
      );

  setUp(() => launched = []);

  test('deve abrir a URL permitida fora do app', () async {
    final opener = openerWhoseLaunch(() async => true);

    await opener.open(trailerUrl);

    expect(launched, [(trailerUrl, LaunchMode.externalApplication)]);
  });

  test('deve recusar a URL fora da política', () {
    final opener = openerWhoseLaunch(() async => true);

    expect(
      opener.open(blockedUrl),
      throwsA(
        isA<LinkNotOpened>().having(
          (failure) => failure.reason,
          'reason',
          LinkNotOpenedReason.blocked,
        ),
      ),
    );
  });

  test('não deve chamar o launcher com a URL fora da política', () async {
    final opener = openerWhoseLaunch(() async => true);

    await expectLater(opener.open(blockedUrl), throwsA(isA<LinkNotOpened>()));

    expect(launched, isEmpty);
  });

  test('deve avisar quando nenhum app abre o link', () {
    final opener = openerWhoseLaunch(() async => false);

    expect(
      opener.open(trailerUrl),
      throwsA(
        isA<LinkNotOpened>().having(
          (failure) => failure.reason,
          'reason',
          LinkNotOpenedReason.noApp,
        ),
      ),
    );
  });

  test('deve converter a PlatformException do plugin em falha tipada', () {
    final opener = openerWhoseLaunch(
      () async => throw PlatformException(code: 'ACTIVITY_NOT_FOUND'),
    );

    expect(
      opener.open(trailerUrl),
      throwsA(
        isA<LinkNotOpened>().having(
          (failure) => failure.reason,
          'reason',
          LinkNotOpenedReason.noApp,
        ),
      ),
    );
  });

  test('deve converter qualquer outro erro do plugin em falha tipada', () {
    final opener = openerWhoseLaunch(
      () async => throw ArgumentError('modo não suportado'),
    );

    expect(
      opener.open(trailerUrl),
      throwsA(
        isA<LinkNotOpened>().having(
          (failure) => failure.reason,
          'reason',
          LinkNotOpenedReason.noApp,
        ),
      ),
    );
  });
}
