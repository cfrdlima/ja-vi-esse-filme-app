import 'package:flutter_test/flutter_test.dart';
import 'package:ja_vi_esse_filme/core/bootstrap/app_bootstrap.dart';

void main() {
  late List<String> calls;

  setUp(() {
    calls = [];
  });

  test('deve inicializar antes de subir o app', () async {
    await bootstrapApp(
      initialize: () async => calls.add('initialize'),
      run: () => calls.add('run'),
      report: (_, _) {},
    );

    expect(calls, ['initialize', 'run']);
  });

  group('quando a inicialização falha', () {
    final failure = StateError('Firebase indisponível');
    late List<Object> reported;

    Future<void> bootstrapWithFailure() => bootstrapApp(
      initialize: () async => throw failure,
      run: () => calls.add('run'),
      report: (error, _) => reported.add(error),
    );

    setUp(() {
      reported = [];
    });

    test('deve reportar a falha', () async {
      await bootstrapWithFailure();

      expect(reported, [failure]);
    });

    test('deve subir o app mesmo assim', () async {
      await bootstrapWithFailure();

      expect(calls, ['run']);
    });
  });
}
