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
}
