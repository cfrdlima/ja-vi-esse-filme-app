import 'package:flutter_test/flutter_test.dart';
import 'package:ja_vi_esse_filme/features/auth/domain/entities/app_user.dart';
import 'package:ja_vi_esse_filme/features/auth/domain/entities/sign_in_outcome.dart';

void main() {
  AppUser ana() => AppUser(uid: 'abc123', email: 'ana@example.com');

  test('deve considerar iguais dois logins concluídos com o mesmo usuário', () {
    expect(SignInCompleted(ana()), SignInCompleted(ana()));
  });

  test('deve dar o mesmo hashCode a logins concluídos iguais', () {
    expect(SignInCompleted(ana()).hashCode, SignInCompleted(ana()).hashCode);
  });

  test('deve diferenciar o login concluído do cancelado', () {
    expect(SignInCompleted(ana()), isNot(const SignInCancelled()));
  });

  test('deve esconder os dados do usuário no toString do login concluído', () {
    expect(
      SignInCompleted(ana()).toString(),
      isNot(contains('ana@example.com')),
    );
  });

  // O tear-off cria instâncias novas, sem `const`, como um `map` do stream
  // faria.
  test('deve considerar iguais dois logins cancelados criados sem const', () {
    const make = SignInCancelled.new;

    expect(make(), make());
  });

  test(
    'deve dar o mesmo hashCode a dois logins cancelados criados sem const',
    () {
      const make = SignInCancelled.new;

      expect(make().hashCode, make().hashCode);
    },
  );
}
