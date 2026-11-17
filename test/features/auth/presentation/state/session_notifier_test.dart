import 'package:flutter_test/flutter_test.dart';
import 'package:ja_vi_esse_filme/features/auth/domain/entities/app_user.dart';
import 'package:ja_vi_esse_filme/features/auth/domain/entities/auth_state.dart';
import 'package:ja_vi_esse_filme/features/auth/presentation/state/session_notifier.dart';
import 'package:ja_vi_esse_filme/features/auth/presentation/state/session_state.dart';

import '../../../../helpers/fake_auth_repository.dart';

void main() {
  late FakeAuthRepository repository;
  late SessionNotifier notifier;

  final ana = AppUser(uid: 'abc123', displayName: 'Ana');

  setUp(() {
    repository = FakeAuthRepository();
    notifier = SessionNotifier(repository: repository);
  });

  tearDown(() async {
    notifier.dispose();
    await repository.close();
  });

  test('deve começar carregando, antes do primeiro estado da conta', () {
    expect(notifier.state, isA<SessionLoading>());
  });

  test('deve ficar deslogado quando a conta emite SignedOut', () async {
    repository.emit(const SignedOut());
    await pumpEventQueue();

    expect(notifier.state, isA<SessionSignedOut>());
  });

  test(
    'deve ficar logado com o usuário quando a conta emite SignedIn',
    () async {
      repository.emit(SignedIn(ana));
      await pumpEventQueue();

      expect(
        notifier.state,
        isA<SessionSignedIn>().having((s) => s.user, 'user', ana),
      );
    },
  );

  test('deve avisar os ouvintes quando a conta muda', () async {
    var notified = 0;
    notifier.addListener(() => notified++);

    repository.emit(const SignedOut());
    await pumpEventQueue();

    expect(notified, 1);
  });

  test('deve parar de ouvir a conta no dispose', () async {
    final other = FakeAuthRepository();
    addTearDown(other.close);
    SessionNotifier(repository: other).dispose();

    expect(other.hasListener, isFalse);
  });
}
