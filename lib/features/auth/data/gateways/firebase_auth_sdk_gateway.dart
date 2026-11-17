import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/entities/app_user.dart';
import 'auth_gateways.dart';

/// Repasse direto ao `FirebaseAuth`, sem regra: as regras e a tradução dos
/// erros ficam no `FirebaseAuthRepository`, que é testado com fakes.
final class FirebaseAuthSdkGateway implements FirebaseAuthGateway {
  FirebaseAuthSdkGateway(this._auth);

  final FirebaseAuth _auth;

  @override
  Stream<AppUser?> authStateChanges() =>
      _auth.authStateChanges().map((user) => user?.toAppUser());

  @override
  AppUser? get currentUser => _auth.currentUser?.toAppUser();

  @override
  Future<AppUser> signInWithGoogleIdToken(String idToken) async {
    final credential = GoogleAuthProvider.credential(idToken: idToken);
    final result = await _auth.signInWithCredential(credential);
    final user = result.user;
    if (user == null) throw StateError('login sem usuário');
    return user.toAppUser();
  }

  @override
  Future<void> signOut() => _auth.signOut();
}

extension on User {
  AppUser toAppUser() => AppUser(
    uid: uid,
    displayName: displayName,
    email: email,
    photoUrl: photoURL,
  );
}
