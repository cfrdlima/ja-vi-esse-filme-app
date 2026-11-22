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
import 'core/firestore/user_data_write_lock.dart';
import 'core/l10n/app_locale.dart';
import 'core/licenses/font_licenses.dart';
import 'core/links/external_link_opener.dart';
import 'core/links/url_launcher_link_opener.dart';
import 'core/network/tmdb_client.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/data/gateways/cloud_firestore_account_documents.dart';
import 'features/auth/data/gateways/firebase_auth_sdk_gateway.dart';
import 'features/auth/data/gateways/firestore_account_cache.dart';
import 'features/auth/data/gateways/google_sign_in_sdk_gateway.dart';
import 'features/auth/data/repositories/firebase_auth_repository.dart';
import 'features/auth/data/repositories/unavailable_auth_repository.dart';
import 'features/auth/data/stale_account_cache.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/presentation/state/account_photo_cleaner.dart';
import 'features/auth/presentation/state/session_notifier.dart';
import 'features/movies/data/datasources/movie_remote_data_source.dart';
import 'features/movies/data/repositories/tmdb_movie_repository.dart';
import 'features/movies/domain/repositories/movie_repository.dart';
import 'features/shelf/data/gateways/cloud_firestore_movie_lists_gateway.dart';
import 'features/shelf/data/gateways/cloud_firestore_shelf_gateway.dart';
import 'features/shelf/data/repositories/firestore_movie_lists_repository.dart';
import 'features/shelf/data/repositories/firestore_shelf_repository.dart';
import 'features/shelf/data/repositories/unavailable_movie_lists_repository.dart';
import 'features/shelf/data/repositories/unavailable_shelf_repository.dart';
import 'features/shelf/domain/repositories/movie_lists_repository.dart';
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
      final writeLock = UserDataWriteLock();
      final shelfRepository = composeShelfRepository(
        firebaseAvailable: firebaseAvailable,
        connect: () => _connectFirestoreShelf(writeLock),
      );
      final movieListsRepository = composeMovieListsRepository(
        firebaseAvailable: firebaseAvailable,
        connect: () => _connectFirestoreLists(writeLock),
      );
      runApp(
        MainApp(
          movieRepository: _composeMovieRepository(),
          authRepository: composeAuthRepository(
            firebaseAvailable: firebaseAvailable,
            connect: () => _connectFirebaseAuth(
              () => closeUserDataStreams(shelfRepository, movieListsRepository),
              writeLock,
            ),
          ),
          shelfRepository: shelfRepository,
          movieListsRepository: movieListsRepository,
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
/// `initializeApp`), [connect] não é chamado: o `FirebaseFirestore.instance`
/// lançaria `no-app` e derrubaria o app inteiro.
@visibleForTesting
ShelfRepository composeShelfRepository({
  required bool firebaseAvailable,
  required ShelfRepository Function() connect,
}) => firebaseAvailable ? connect() : const UnavailableShelfRepository();

/// Sem o Firebase, [connect] não é chamado, como na Estante.
@visibleForTesting
MovieListsRepository composeMovieListsRepository({
  required bool firebaseAvailable,
  required MovieListsRepository Function() connect,
}) => firebaseAvailable ? connect() : const UnavailableMovieListsRepository();

/// Os streams da Estante e das listas, que o logout fecha antes de limpar o
/// cache do Firestore (decisão 010).
@visibleForTesting
Future<void> closeUserDataStreams(
  ShelfRepository shelf,
  MovieListsRepository lists,
) async {
  // Uma falha na Estante não pode deixar as listas ouvindo durante o
  // `terminate()`.
  try {
    await shelf.closeStreams();
  } finally {
    await lists.closeStreams();
  }
}

/// Sem o Firebase, [connect] não é chamado: o `FirebaseAuth.instance`
/// lançaria `no-app` e derrubaria o app inteiro.
@visibleForTesting
AuthRepository composeAuthRepository({
  required bool firebaseAvailable,
  required AuthRepository Function() connect,
}) => firebaseAvailable ? connect() : const UnavailableAuthRepository();

// A foto da conta só fica no cache em memória (ver `AccountAvatar`).
void _evictCachedImage(String url) => unawaited(NetworkImage(url).evict());

// O logout fecha os streams da Estante e das listas antes de limpar o cache
// do Firestore (decisão 010). No início, o cache de uma conta que já saiu é
// limpo, caso a limpeza do último logout tenha falhado.
AuthRepository _connectFirebaseAuth(
  Future<void> Function() closeStreams,
  UserDataWriteLock writeLock,
) {
  final firestore = FirebaseFirestore.instance;
  final cache = FirestoreAccountCache(
    closeStreams: closeStreams,
    terminate: firestore.terminate,
    clearPersistence: firestore.clearPersistence,
    waitForPendingWrites: firestore.waitForPendingWrites,
  );
  final repository = FirebaseAuthRepository(
    firebase: FirebaseAuthSdkGateway(FirebaseAuth.instance),
    google: GoogleSignInSdkGateway(GoogleSignIn.instance),
    cache: cache,
    documents: cloudFirestoreAccountDocuments(firestore),
    reportError: logUnhandledError,
    writeLock: writeLock,
  );
  unawaited(
    clearStaleAccountCache(account: repository.authStateChanges, cache: cache),
  );
  return repository;
}

// O `uid` é lido a cada chamada, e não guardado: a conta pode mudar
// (decisão 013).
ShelfRepository _connectFirestoreShelf(UserDataWriteLock writeLock) =>
    FirestoreShelfRepository(
      writeLock: writeLock,
      gateway: CloudFirestoreShelfGateway(
        firestore: FirebaseFirestore.instance,
      ),
      currentUid: () => FirebaseAuth.instance.currentUser?.uid,
    );

// As escritas num filme vão pelo mesmo gateway da Estante (decisão 019).
MovieListsRepository _connectFirestoreLists(UserDataWriteLock writeLock) =>
    FirestoreMovieListsRepository(
      lists: CloudFirestoreMovieListsGateway(
        firestore: FirebaseFirestore.instance,
      ),
      movies: CloudFirestoreShelfGateway(firestore: FirebaseFirestore.instance),
      currentUid: () => FirebaseAuth.instance.currentUser?.uid,
      writeLock: writeLock,
    );

class MainApp extends StatefulWidget {
  const MainApp({
    required this.movieRepository,
    required this.authRepository,
    required this.shelfRepository,
    required this.movieListsRepository,
    required this.linkOpener,
    required this.appVersion,
    required this.evictPhoto,
    super.key,
  });

  final MovieRepository movieRepository;
  final AuthRepository authRepository;
  final ShelfRepository shelfRepository;
  final MovieListsRepository movieListsRepository;
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
        Provider<MovieListsRepository>.value(
          value: widget.movieListsRepository,
        ),
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
