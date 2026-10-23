import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ja_vi_esse_filme/features/movies/domain/entities/movie.dart';
import 'package:ja_vi_esse_filme/features/movies/presentation/widgets/movie_poster.dart';

import '../../../../helpers/test_app.dart';

void main() {
  Future<void> pumpPoster(WidgetTester tester, Movie movie) =>
      tester.pumpWidget(
        testApp(
          home: Center(
            child: SizedBox(width: 120, child: MoviePoster(movie: movie)),
          ),
        ),
      );

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
}
