import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import 'core/bootstrap/app_bootstrap.dart';
import 'core/config/app_config.dart';
import 'core/error/error_handlers.dart';
import 'core/l10n/app_locale.dart';
import 'core/licenses/font_licenses.dart';
import 'core/links/external_link_opener.dart';
import 'core/links/url_launcher_link_opener.dart';
import 'core/network/tmdb_client.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/data/gateways/firebase_auth_sdk_gateway.dart';
import 'features/auth/data/gateways/google_sign_in_sdk_gateway.dart';
import 'features/auth/data/repositories/firebase_auth_repository.dart';
import 'features/auth/data/repositories/unavailable_auth_repository.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/presentation/state/session_notifier.dart';
import 'features/movies/data/datasources/movie_remote_data_source.dart';
import 'features/movies/data/repositories/tmdb_movie_repository.dart';
import 'features/movies/domain/repositories/movie_repository.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  registerErrorHandlers();
  registerFontLicenses();
  await bootstrapApp(
    initialize: _initializeFirebase,
    run: () => runApp(
      MainApp(
        movieRepository: _composeMovieRepository(),
        authRepository: composeAuthRepository(
          firebaseAvailable: Firebase.apps.isNotEmpty,
          connect: _connectFirebaseAuth,
        ),
        linkOpener: UrlLauncherLinkOpener(),
        appVersion: AppConfig.appVersion,
      ),
    ),
    report: logUnhandledError,
  );
}

Future<void> _initializeFirebase() async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
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

/// Sem o Firebase (o `bootstrapApp` sobe o app mesmo com falha no
/// `initializeApp`), [connect] não é chamado: o `FirebaseAuth.instance`
/// lançaria `no-app` e derrubaria o app inteiro.
@visibleForTesting
AuthRepository composeAuthRepository({
  required bool firebaseAvailable,
  required AuthRepository Function() connect,
}) => firebaseAvailable ? connect() : const UnavailableAuthRepository();

AuthRepository _connectFirebaseAuth() => FirebaseAuthRepository(
  firebase: FirebaseAuthSdkGateway(FirebaseAuth.instance),
  google: GoogleSignInSdkGateway(GoogleSignIn.instance),
);

class MainApp extends StatefulWidget {
  const MainApp({
    required this.movieRepository,
    required this.authRepository,
    required this.linkOpener,
    required this.appVersion,
    super.key,
  });

  final MovieRepository movieRepository;
  final AuthRepository authRepository;
  final ExternalLinkOpener linkOpener;
  final String appVersion;

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  // Criado uma vez só: recriar o router a cada build perderia a pilha de
  // navegação.
  late final GoRouter _router = createAppRouter(
    movieRepository: widget.movieRepository,
    appVersion: widget.appVersion,
  );

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Acima do `MaterialApp`, para alcançar as rotas de todas as abas.
    return MultiProvider(
      providers: [
        Provider<ExternalLinkOpener>.value(value: widget.linkOpener),
        // Não preguiçoso: a sessão passa a ouvir a conta desde o início, e
        // não só quando a primeira tela a pedir.
        ChangeNotifierProvider(
          create: (_) => SessionNotifier(repository: widget.authRepository),
          lazy: false,
        ),
      ],
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
