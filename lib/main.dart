import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
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
import 'features/auth/data/gateways/firestore_account_cache.dart';
import 'features/auth/data/gateways/google_sign_in_sdk_gateway.dart';
import 'features/auth/data/repositories/firebase_auth_repository.dart';
import 'features/auth/data/repositories/unavailable_auth_repository.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/presentation/state/account_photo_cleaner.dart';
import 'features/auth/presentation/state/session_notifier.dart';
import 'features/movies/data/datasources/movie_remote_data_source.dart';
import 'features/movies/data/repositories/tmdb_movie_repository.dart';
import 'features/movies/domain/repositories/movie_repository.dart';
import 'features/shelf/data/gateways/cloud_firestore_shelf_gateway.dart';
import 'features/shelf/data/repositories/firestore_shelf_repository.dart';
import 'features/shelf/data/repositories/unavailable_shelf_repository.dart';
import 'features/shelf/domain/repositories/shelf_repository.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  registerErrorHandlers();
  registerFontLicenses();
  await bootstrapApp(
    initialize: _initializeFirebase,
    run: () {
      final firebaseAvailable = Firebase.apps.isNotEmpty;
      final shelfRepository = composeShelfRepository(
        firebaseAvailable: firebaseAvailable,
        connect: _connectFirestoreShelf,
      );
      runApp(
        MainApp(
          movieRepository: _composeMovieRepository(),
          authRepository: composeAuthRepository(
            firebaseAvailable: firebaseAvailable,
            connect: () => _connectFirebaseAuth(shelfRepository),
          ),
          shelfRepository: shelfRepository,
          linkOpener: UrlLauncherLinkOpener(),
          appVersion: AppConfig.appVersion,
          evictPhoto: _evictCachedImage,
        ),
      );
    },
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
ShelfRepository composeShelfRepository({
  required bool firebaseAvailable,
  required ShelfRepository Function() connect,
}) => firebaseAvailable ? connect() : const UnavailableShelfRepository();

@visibleForTesting
AuthRepository composeAuthRepository({
  required bool firebaseAvailable,
  required AuthRepository Function() connect,
}) => firebaseAvailable ? connect() : const UnavailableAuthRepository();

// A foto da conta só fica no cache em memória (ver `AccountAvatar`).
void _evictCachedImage(String url) => unawaited(NetworkImage(url).evict());

// O logout fecha os streams da Estante antes de limpar o cache do
// Firestore (decisão 010).
AuthRepository _connectFirebaseAuth(ShelfRepository shelf) {
  final firestore = FirebaseFirestore.instance;
  return FirebaseAuthRepository(
    firebase: FirebaseAuthSdkGateway(FirebaseAuth.instance),
    google: GoogleSignInSdkGateway(GoogleSignIn.instance),
    cache: FirestoreAccountCache(
      closeStreams: shelf.closeStreams,
      terminate: firestore.terminate,
      clearPersistence: firestore.clearPersistence,
      waitForPendingWrites: firestore.waitForPendingWrites,
    ),
  );
}

// O `uid` é lido a cada chamada, e não guardado: a conta pode mudar
// (decisão 013).
ShelfRepository _connectFirestoreShelf() => FirestoreShelfRepository(
  gateway: CloudFirestoreShelfGateway(firestore: FirebaseFirestore.instance),
  currentUid: () => FirebaseAuth.instance.currentUser?.uid,
);

class MainApp extends StatefulWidget {
  const MainApp({
    required this.movieRepository,
    required this.authRepository,
    required this.shelfRepository,
    required this.linkOpener,
    required this.appVersion,
    required this.evictPhoto,
    super.key,
  });

  final MovieRepository movieRepository;
  final AuthRepository authRepository;
  final ShelfRepository shelfRepository;
  final ExternalLinkOpener linkOpener;
  final String appVersion;

  /// Tira uma imagem do cache. Serve para apagar a foto da conta no logout.
  final void Function(String url) evictPhoto;

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
        Provider<AuthRepository>.value(value: widget.authRepository),
        Provider<ShelfRepository>.value(value: widget.shelfRepository),
        // Não preguiçoso: a sessão passa a ouvir a conta desde o início, e
        // não só quando a primeira tela a pedir.
        ChangeNotifierProvider(
          create: (_) {
            final session = SessionNotifier(repository: widget.authRepository);
            // Ouve a sessão enquanto ela existir; some junto no dispose dela.
            AccountPhotoCleaner(session: session, evict: widget.evictPhoto);
            return session;
          },
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
