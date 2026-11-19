import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ja_vi_esse_filme/core/links/external_link_opener.dart';
import 'package:ja_vi_esse_filme/core/theme/app_theme_tokens.dart';
import 'package:ja_vi_esse_filme/features/auth/data/repositories/unavailable_auth_repository.dart';
import 'package:ja_vi_esse_filme/features/auth/domain/entities/app_user.dart';
import 'package:ja_vi_esse_filme/features/auth/domain/entities/auth_state.dart';
import 'package:ja_vi_esse_filme/features/auth/domain/repositories/auth_repository.dart';
import 'package:ja_vi_esse_filme/features/auth/presentation/state/session_notifier.dart';
import 'package:ja_vi_esse_filme/features/auth/presentation/state/session_state.dart';
import 'package:ja_vi_esse_filme/features/shelf/data/repositories/unavailable_movie_lists_repository.dart';
import 'package:ja_vi_esse_filme/features/shelf/data/repositories/unavailable_shelf_repository.dart';
import 'package:ja_vi_esse_filme/features/shelf/domain/repositories/shelf_repository.dart';
import 'package:ja_vi_esse_filme/main.dart';
import 'package:provider/provider.dart';

import 'helpers/fake_auth_repository.dart';
import 'helpers/fake_link_opener.dart';
import 'helpers/fake_movie_lists_repository.dart';
import 'helpers/fake_shelf_repository.dart';
import 'helpers/stub_movie_repository.dart';

void main() {
  late FakeAuthRepository authRepository;
  late FakeShelfRepository shelfRepository;
  late FakeMovieListsRepository movieListsRepository;
  late List<String> evictedPhotos;

  setUp(() {
    authRepository = FakeAuthRepository();
    shelfRepository = FakeShelfRepository();
    movieListsRepository = FakeMovieListsRepository();
    evictedPhotos = [];
  });
  tearDown(() async {
    shelfRepository.close();
    await authRepository.close();
  });

  MainApp app({ExternalLinkOpener? linkOpener, String appVersion = ''}) =>
      MainApp(
        movieRepository: StubMovieRepository(),
        authRepository: authRepository,
        shelfRepository: shelfRepository,
        movieListsRepository: movieListsRepository,
        linkOpener: linkOpener ?? FakeLinkOpener(),
        appVersion: appVersion,
        evictPhoto: evictedPhotos.add,
      );

  testWidgets('o app deve usar o tema escuro do design system', (tester) async {
    await tester.pumpWidget(app());

    final context = tester.element(find.byType(Scaffold).first);
    expect(Theme.of(context).extension<AppThemeTokens>(), AppThemeTokens.dark);
  });

  testWidgets('o app deve ficar no modo escuro mesmo com o sistema claro', (
    tester,
  ) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

    await tester.pumpWidget(app());

    final context = tester.element(find.byType(Scaffold).first);
    expect(Theme.of(context).brightness, Brightness.dark);
  });

  testWidgets('o app deve usar o locale pt_BR', (tester) async {
    await tester.pumpWidget(app());

    final context = tester.element(find.byType(Scaffold).first);
    expect(Localizations.localeOf(context), const Locale('pt', 'BR'));
  });

  testWidgets('os textos do Material devem sair em português', (tester) async {
    await tester.pumpWidget(app());

    final context = tester.element(find.byType(Scaffold).first);
    expect(MaterialLocalizations.of(context).backButtonTooltip, 'Voltar');
  });

  testWidgets('o app deve entregar a Estante às telas', (tester) async {
    await tester.pumpWidget(app());

    final context = tester.element(find.byType(Scaffold).first);
    expect(context.read<ShelfRepository>(), same(shelfRepository));
  });

  testWidgets('o app deve entregar a conta às telas', (tester) async {
    await tester.pumpWidget(app());

    final context = tester.element(find.byType(Scaffold).first);
    expect(context.read<AuthRepository>(), same(authRepository));
  });

  testWidgets('o app deve abrir no shell de navegação', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsOneWidget);
  });

  testWidgets('as telas devem receber o abridor de links do app', (
    tester,
  ) async {
    final opener = FakeLinkOpener();
    await tester.pumpWidget(app(linkOpener: opener));

    final context = tester.element(find.byType(Scaffold).first);
    expect(context.read<ExternalLinkOpener>(), same(opener));
  });

  testWidgets('o Sobre deve mostrar a versão recebida pelo app', (
    tester,
  ) async {
    // Já deslogada: a conta carregando pulsaria o skeleton do Perfil para
    // sempre, e o `pumpAndSettle` não terminaria.
    authRepository.emit(const SignedOut());
    await tester.pumpWidget(app(appVersion: '9.9.9'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Perfil'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sobre o app'));
    await tester.pumpAndSettle();

    expect(find.text('Versão 9.9.9'), findsOneWidget);
  });

  testWidgets('as telas devem receber a sessão ligada à conta do app', (
    tester,
  ) async {
    await tester.pumpWidget(app());

    authRepository.emit(const SignedOut());
    await tester.pump();

    final context = tester.element(find.byType(Scaffold).first);
    expect(context.read<SessionNotifier>().state, isA<SessionSignedOut>());
  });

  testWidgets('o logout deve tirar a foto da conta do cache', (tester) async {
    const photo = 'https://lh3.googleusercontent.com/a/ana';
    await tester.pumpWidget(app());
    authRepository.emit(SignedIn(AppUser(uid: 'ana1', photoUrl: photo)));
    await tester.pump();

    authRepository.emit(const SignedOut());
    await tester.pump();

    expect(evictedPhotos, [photo]);
  });

  testWidgets('a sessão deve parar de ouvir a conta quando o app sai', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await tester.pump();

    await tester.pumpWidget(const SizedBox());

    expect(authRepository.hasListener, isFalse);
  });

  group('composeShelfRepository', () {
    test('deve usar a Estante indisponível quando o Firebase não subiu', () {
      final repository = composeShelfRepository(
        firebaseAvailable: false,
        connect: () => throw StateError('não deveria tocar no Firebase'),
      );

      expect(repository, isA<UnavailableShelfRepository>());
    });

    test('deve conectar ao Firestore quando o Firebase subiu', () {
      final connected = FakeShelfRepository();

      final repository = composeShelfRepository(
        firebaseAvailable: true,
        connect: () => connected,
      );

      expect(repository, same(connected));
    });
  });

  group('composeMovieListsRepository', () {
    test('deve usar as listas indisponíveis quando o Firebase não subiu', () {
      final repository = composeMovieListsRepository(
        firebaseAvailable: false,
        connect: () => throw StateError('não deveria tocar no Firebase'),
      );

      expect(repository, isA<UnavailableMovieListsRepository>());
    });

    test('deve conectar ao Firestore quando o Firebase subiu', () {
      final connected = FakeMovieListsRepository();

      final repository = composeMovieListsRepository(
        firebaseAvailable: true,
        connect: () => connected,
      );

      expect(repository, same(connected));
    });
  });

  // O logout fecha os streams antes de limpar o cache (decisão 010).
  group('closeUserDataStreams', () {
    test('deve fechar os streams da Estante', () async {
      await closeUserDataStreams(shelfRepository, movieListsRepository);

      expect(shelfRepository.closeStreamsCalls, 1);
    });

    test('deve fechar os streams das listas', () async {
      await closeUserDataStreams(shelfRepository, movieListsRepository);

      expect(movieListsRepository.closeStreamsCalls, 1);
    });
  });

  group('composeAuthRepository', () {
    test('deve usar a conta indisponível quando o Firebase não subiu', () {
      final repository = composeAuthRepository(
        firebaseAvailable: false,
        connect: () => throw StateError('não deveria tocar no Firebase'),
      );

      expect(repository, isA<UnavailableAuthRepository>());
    });

    test('deve conectar ao Firebase quando ele subiu', () {
      final connected = FakeAuthRepository();
      addTearDown(connected.close);

      final repository = composeAuthRepository(
        firebaseAvailable: true,
        connect: () => connected,
      );

      expect(repository, same(connected));
    });
  });
}
