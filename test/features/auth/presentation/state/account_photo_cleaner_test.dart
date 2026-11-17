import 'package:flutter_test/flutter_test.dart';
import 'package:ja_vi_esse_filme/features/auth/domain/entities/app_user.dart';
import 'package:ja_vi_esse_filme/features/auth/domain/entities/auth_state.dart';
import 'package:ja_vi_esse_filme/features/auth/presentation/state/account_photo_cleaner.dart';
import 'package:ja_vi_esse_filme/features/auth/presentation/state/session_notifier.dart';

import '../../../../helpers/fake_auth_repository.dart';

void main() {
  late FakeAuthRepository repository;
  late SessionNotifier session;
  late List<String> evicted;

  const anaPhoto = 'https://lh3.googleusercontent.com/a/ana';
  final ana = AppUser(uid: 'ana1', displayName: 'Ana', photoUrl: anaPhoto);

  setUp(() {
    repository = FakeAuthRepository();
    session = SessionNotifier(repository: repository);
    evicted = [];
    AccountPhotoCleaner(session: session, evict: evicted.add);
  });

  tearDown(() async {
    session.dispose();
    await repository.close();
  });

  Future<void> emit(AuthState state) async {
    repository.emit(state);
    await pumpEventQueue();
  }

  test('deve apagar a foto do cache quando a sessão fecha', () async {
    await emit(SignedIn(ana));

    await emit(const SignedOut());

    expect(evicted, [anaPhoto]);
  });

  test('deve apagar a foto da conta anterior quando a conta troca', () async {
    await emit(SignedIn(ana));

    await emit(
      SignedIn(
        AppUser(uid: 'bia2', photoUrl: 'https://x.googleusercontent.com/b'),
      ),
    );

    expect(evicted, [anaPhoto]);
  });

  test('não deve apagar a foto enquanto a sessão continua aberta', () async {
    await emit(SignedIn(ana));

    await emit(SignedIn(ana));

    expect(evicted, isEmpty);
  });

  test('não deve apagar nada quando a conta não tem foto', () async {
    await emit(SignedIn(AppUser(uid: 'ana1')));

    await emit(const SignedOut());

    expect(evicted, isEmpty);
  });
}
