import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ja_vi_esse_filme/core/links/external_link_opener.dart';
import 'package:ja_vi_esse_filme/core/widgets/external_link_tile.dart';
import 'package:provider/provider.dart';

import '../../helpers/fake_link_opener.dart';
import '../../helpers/test_app.dart';

void main() {
  final url = Uri.https('www.youtube.com', '/watch', {'v': 'Way9Dexny3w'});

  Widget tile(FakeLinkOpener opener) => Provider<ExternalLinkOpener>.value(
    value: opener,
    child: testApp(
      home: Scaffold(
        body: ExternalLinkTile(
          url: url,
          icon: Icons.link,
          title: 'Título',
          subtitle: 'Subtítulo',
          semanticsLabel: 'Título. Abre fora do app',
          failureMessage: 'Não abriu.',
        ),
      ),
    ),
  );

  testWidgets('deve abrir a URL ao tocar', (tester) async {
    final opener = FakeLinkOpener();
    await tester.pumpWidget(tile(opener));

    await tester.tap(find.text('Título'));
    await tester.pump();

    expect(opener.opened, [url]);
  });

  testWidgets('deve avisar quando nenhum app abre a URL', (tester) async {
    await tester.pumpWidget(
      tile(
        FakeLinkOpener(failure: const LinkNotOpened(LinkNotOpenedReason.noApp)),
      ),
    );

    await tester.tap(find.text('Título'));
    await tester.pump();

    expect(find.text('Não abriu.'), findsOneWidget);
  });

  testWidgets('deve ser um nó só de link com o rótulo dado', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(tile(FakeLinkOpener()));

    expect(
      tester.getSemantics(find.byType(ExternalLinkTile)),
      matchesSemantics(
        label: 'Título. Abre fora do app',
        isLink: true,
        hasTapAction: true,
      ),
    );
    semantics.dispose();
  });
}
