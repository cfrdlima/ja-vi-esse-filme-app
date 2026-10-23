import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ja_vi_esse_filme/core/l10n/app_locale.dart';
import 'package:ja_vi_esse_filme/core/theme/app_motion.dart';
import 'package:ja_vi_esse_filme/features/movies/domain/entities/movie.dart';
import 'package:ja_vi_esse_filme/features/movies/presentation/widgets/movie_poster.dart';
import 'package:ja_vi_esse_filme/l10n/app_localizations.dart';

import '../../../../helpers/test_app.dart';

void main() {
  final l10n = lookupAppLocalizations(AppLocale.locale);

  Future<void> pumpPoster(
    WidgetTester tester,
    Movie movie, {
    bool disableAnimations = false,
  }) => tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(
        disableAnimations: disableAnimations,
        devicePixelRatio: 3,
      ),
      child: testApp(
        home: Center(
          child: SizedBox(width: 120, child: MoviePoster(movie: movie)),
        ),
      ),
    ),
  );

  CachedNetworkImage image(WidgetTester tester) =>
      tester.widget<CachedNetworkImage>(find.byType(CachedNetworkImage));

  const withPoster = Movie(id: 1, title: 'Com pôster', posterPath: '/p.jpg');

  testWidgets('deve desenhar o placeholder quando não há pôster', (
    tester,
  ) async {
    await pumpPoster(tester, const Movie(id: 1, title: 'Sem pôster'));

    expect(find.byType(CachedNetworkImage), findsNothing);
    expect(find.byIcon(Icons.movie_outlined), findsOneWidget);
  });

  testWidgets('deve carregar o pôster do TMDB em w342', (tester) async {
    await pumpPoster(
      tester,
      const Movie(id: 1, title: 'Com pôster', posterPath: '/p.jpg'),
    );

    final image = tester.widget<CachedNetworkImage>(
      find.byType(CachedNetworkImage),
    );
    expect(image.imageUrl, 'https://image.tmdb.org/t/p/w342/p.jpg');
  });

  testWidgets('deve ter proporção 2:3', (tester) async {
    await pumpPoster(tester, const Movie(id: 1, title: 'Sem pôster'));

    expect(tester.getSize(find.byType(MoviePoster)), const Size(120, 180));
  });

  testWidgets('deve anunciar o título do filme como imagem', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpPoster(tester, const Movie(id: 1, title: 'Matrix'));

    expect(
      tester.getSemantics(find.byType(MoviePoster)),
      matchesSemantics(label: 'Matrix', isImage: true),
    );
    semantics.dispose();
  });

  testWidgets('deve anunciar filme sem título como sem título', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpPoster(tester, const Movie(id: 1, title: ''));

    expect(
      tester.getSemantics(find.byType(MoviePoster)),
      matchesSemantics(label: l10n.movieUntitled, isImage: true),
    );
    semantics.dispose();
  });

  testWidgets('deve usar as durações de fade do design system', (tester) async {
    await pumpPoster(tester, withPoster);

    expect(
      (image(tester).fadeInDuration, image(tester).fadeOutDuration),
      (AppMotion.medium, AppMotion.short),
    );
  });

  testWidgets('não deve animar o fade com o reduzir movimento', (tester) async {
    await pumpPoster(tester, withPoster, disableAnimations: true);

    expect(
      (image(tester).fadeInDuration, image(tester).fadeOutDuration),
      (Duration.zero, Duration.zero),
    );
  });

  testWidgets('deve decodificar a imagem na largura da célula', (tester) async {
    await pumpPoster(tester, withPoster);

    // 120dp de célula × devicePixelRatio 3.
    expect(image(tester).memCacheWidth, 360);
  });
}
