import 'package:flutter_test/flutter_test.dart';
import 'package:ja_vi_esse_filme/features/auth/domain/entities/app_user.dart';
import 'package:ja_vi_esse_filme/features/auth/domain/entities/auth_state.dart';

void main() {
  AppUser ana() => AppUser(uid: 'abc123', email: 'ana@example.com');

  test('deve considerar iguais dois estados logados com o mesmo usuário', () {
    expect(SignedIn(ana()), SignedIn(ana()));
  });

  test('deve dar o mesmo hashCode a estados logados iguais', () {
    expect(SignedIn(ana()).hashCode, SignedIn(ana()).hashCode);
  });

  test('deve diferenciar o estado logado do deslogado', () {
    expect(SignedIn(ana()), isNot(const SignedOut()));
  });

  test('deve esconder os dados do usuário no toString do estado logado', () {
    expect(SignedIn(ana()).toString(), isNot(contains('ana@example.com')));
  });
}
