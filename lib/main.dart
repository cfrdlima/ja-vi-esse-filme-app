import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import 'core/config/app_config.dart';
import 'core/error/error_handlers.dart';
import 'core/l10n/app_locale.dart';
import 'core/links/external_link_opener.dart';
import 'core/links/url_launcher_link_opener.dart';
import 'core/network/tmdb_client.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/movies/data/datasources/movie_remote_data_source.dart';
import 'features/movies/data/repositories/tmdb_movie_repository.dart';
import 'features/movies/domain/repositories/movie_repository.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  registerErrorHandlers();
  runApp(
    MainApp(
      movieRepository: _composeMovieRepository(),
      linkOpener: UrlLauncherLinkOpener(),
    ),
  );
}

// Único ponto que monta as dependências concretas (CLAUDE.md). O
// `http.Client` vive o app inteiro, por isso não é fechado.
MovieRepository _composeMovieRepository() {
  final client = TmdbClient(
    httpClient: http.Client(),
    config: AppConfig.fromEnvironment(),
  );
  return TmdbMovieRepository(remote: MovieRemoteDataSource(client: client));
}

class MainApp extends StatefulWidget {
  const MainApp({
    required this.movieRepository,
    required this.linkOpener,
    super.key,
  });

  final MovieRepository movieRepository;
  final ExternalLinkOpener linkOpener;

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  // Criado uma vez só: recriar o router a cada build perderia a pilha de
  // navegação.
  late final GoRouter _router = createAppRouter(
    movieRepository: widget.movieRepository,
  );

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Acima do `MaterialApp`, para alcançar as rotas de todas as abas.
    return Provider<ExternalLinkOpener>.value(
      value: widget.linkOpener,
      child: MaterialApp.router(
        theme: AppTheme.dark(),
        locale: AppLocale.locale,
        supportedLocales: AppLocale.supportedLocales,
        localizationsDelegates: AppLocale.delegates,
        routerConfig: _router,
      ),
    );
  }
}
