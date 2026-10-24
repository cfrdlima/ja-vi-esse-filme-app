import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ja_vi_esse_filme/core/l10n/app_locale.dart';
import 'package:ja_vi_esse_filme/core/links/external_link_opener.dart';
import 'package:ja_vi_esse_filme/features/movies/domain/entities/trailer.dart';
import 'package:ja_vi_esse_filme/features/movies/presentation/widgets/trailer_list.dart';
import 'package:ja_vi_esse_filme/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import '../../../../helpers/fake_link_opener.dart';
import '../../../../helpers/test_app.dart';

void main() {
  final l10n = lookupAppLocalizations(AppLocale.locale);

  final dubbed = Trailer(
    key: 'Way9Dexny3w',
    name: 'Trailer oficial dublado',
    kind: TrailerKind.trailer,
    official: true,
    language: 'pt',
  );
  final unnamedTeaser = Trailer(
    key: 'U2Qp5pL3ovA',
    name: '',
    kind: TrailerKind.teaser,
    official: true,
    language: 'en',
  );

  Widget list(FakeLinkOpener opener, {List<Trailer>? trailers}) =>
      Provider<ExternalLinkOpener>.value(
        value: opener,
        child: testApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: TrailerList(trailers: trailers ?? [dubbed, unnamedTeaser]),
            ),
          ),
        ),
      );

  testWidgets('deve mostrar o nome de cada trailer', (tester) async {
    await tester.pumpWidget(list(FakeLinkOpener()));

    expect(find.text('Trailer oficial dublado'), findsOneWidget);
  });

  testWidgets('deve mostrar o tipo e o site abaixo do nome', (tester) async {
    await tester.pumpWidget(list(FakeLinkOpener()));

    expect(
      find.text(l10n.trailerSubtitle(l10n.trailerKindTrailer)),
      findsOneWidget,
    );
  });

  testWidgets('deve usar o tipo como nome do trailer sem nome', (tester) async {
    await tester.pumpWidget(list(FakeLinkOpener()));

    expect(find.text(l10n.trailerKindTeaser), findsOneWidget);
  });

  testWidgets('deve ler o trailer sem nome sem repetir o tipo', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(list(FakeLinkOpener()));

    expect(
      tester.getSemantics(find.byKey(ValueKey(unnamedTeaser.key))).label,
      l10n.trailerUnnamedSemantics(l10n.trailerKindTeaser),
    );
    semantics.dispose();
  });

  testWidgets('deve abrir o trailer tocado no YouTube', (tester) async {
    final opener = FakeLinkOpener();
    await tester.pumpWidget(list(opener));

    await tester.tap(find.text('Trailer oficial dublado'));
    await tester.pump();

    expect(opener.opened, [dubbed.youtubeUrl]);
  });

  testWidgets('deve abrir o trailer pelo toque do leitor de tela', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final opener = FakeLinkOpener();
    await tester.pumpWidget(list(opener));

    tester.semantics.tap(
      find.semantics.byLabel(
        l10n.trailerSemantics(
          'Trailer oficial dublado',
          l10n.trailerKindTrailer,
        ),
      ),
    );
    await tester.pump();

    expect(opener.opened, [dubbed.youtubeUrl]);
    semantics.dispose();
  });

  testWidgets('deve avisar quando nenhum app abre o trailer', (tester) async {
    final opener = FakeLinkOpener(
      failure: const LinkNotOpened(LinkNotOpenedReason.noApp),
    );
    await tester.pumpWidget(list(opener));

    await tester.tap(find.text('Trailer oficial dublado'));
    await tester.pump();

    expect(find.text(l10n.trailerOpenFailed), findsOneWidget);
  });

  testWidgets('deve ler o trailer como link que sai do app', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(list(FakeLinkOpener()));

    expect(
      tester.getSemantics(find.byKey(ValueKey(dubbed.key))),
      matchesSemantics(
        label: l10n.trailerSemantics(
          'Trailer oficial dublado',
          l10n.trailerKindTrailer,
        ),
        isLink: true,
        hasTapAction: true,
      ),
    );
    semantics.dispose();
  });

  testWidgets('deve ter alvo de toque de pelo menos 48dp', (tester) async {
    await tester.pumpWidget(list(FakeLinkOpener()));

    expect(
      tester.getSize(find.byKey(ValueKey(dubbed.key))).height,
      greaterThanOrEqualTo(48),
    );
  });

  testWidgets('não deve estourar o layout com fonte grande', (tester) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(2)),
        child: list(FakeLinkOpener()),
      ),
    );

    expect(tester.takeException(), isNull);
  });
}
