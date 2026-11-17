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
    AppUser ana({String? photoUrl}) => AppUser(
      uid: 'abc123',
      displayName: 'Ana',
      email: 'ana@example.com',
      photoUrl: photoUrl,
    );

    test('deve considerar iguais usuários com os mesmos dados', () {
      expect(ana(), ana());
    });

    test('deve dar o mesmo hashCode a usuários iguais', () {
      expect(ana().hashCode, ana().hashCode);
    });

    test('deve diferenciar usuários com algum dado diferente', () {
      expect(
        ana(),
        isNot(ana(photoUrl: 'https://lh3.googleusercontent.com/a/x')),
      );
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
