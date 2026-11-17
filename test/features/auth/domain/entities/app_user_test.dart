import 'package:flutter_test/flutter_test.dart';
import 'package:ja_vi_esse_filme/features/auth/domain/entities/app_user.dart';

void main() {
  test('deve guardar uid, nome, e-mail e foto', () {
    final user = AppUser(
      uid: 'abc123',
      displayName: 'Ana',
      email: 'ana@example.com',
      photoUrl: 'https://lh3.googleusercontent.com/a/foto',
    );

    expect(
      [user.uid, user.displayName, user.email, user.photoUrl],
      [
        'abc123',
        'Ana',
        'ana@example.com',
        'https://lh3.googleusercontent.com/a/foto',
      ],
    );
  });

  test('deve aceitar usuário sem nome, e-mail e foto', () {
    final user = AppUser(uid: 'abc123');

    expect([user.displayName, user.email, user.photoUrl], [null, null, null]);
  });

  test('deve recusar uid vazio', () {
    expect(() => AppUser(uid: ''), throwsArgumentError);
  });

  test('deve recusar uid só com espaços', () {
    expect(() => AppUser(uid: '   '), throwsArgumentError);
  });

  group('igualdade', () {
    AppUser ana({
      String uid = 'abc123',
      String? displayName = 'Ana',
      String? email = 'ana@example.com',
      String? photoUrl = 'https://lh3.googleusercontent.com/a/foto',
    }) => AppUser(
      uid: uid,
      displayName: displayName,
      email: email,
      photoUrl: photoUrl,
    );

    test('deve considerar iguais usuários com os mesmos dados', () {
      expect(ana(), ana());
    });

    test('deve dar o mesmo hashCode a usuários iguais', () {
      expect(ana().hashCode, ana().hashCode);
    });

    test('deve diferenciar usuários com uid diferente', () {
      expect(ana(), isNot(ana(uid: 'outro')));
    });

    test('deve diferenciar usuários com nome diferente', () {
      expect(ana(), isNot(ana(displayName: 'Bia')));
    });

    test('deve diferenciar usuários com e-mail diferente', () {
      expect(ana(), isNot(ana(email: 'bia@example.com')));
    });

    test('deve diferenciar usuários com foto diferente', () {
      expect(ana(), isNot(ana(photoUrl: null)));
    });
  });

  test('deve esconder uid, nome, e-mail e foto no toString', () {
    final text = AppUser(
      uid: 'abc123',
      displayName: 'Ana',
      email: 'ana@example.com',
      photoUrl: 'https://lh3.googleusercontent.com/a/foto',
    ).toString();

    expect(
      text,
      allOf(
        isNot(contains('abc123')),
        isNot(contains('Ana')),
        isNot(contains('ana@example.com')),
        isNot(contains('googleusercontent')),
      ),
    );
  });
}
