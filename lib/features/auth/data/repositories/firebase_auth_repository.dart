import '../../domain/entities/auth_state.dart';
import '../../domain/entities/sign_in_outcome.dart';
import '../../domain/repositories/auth_repository.dart';
import '../gateways/auth_gateways.dart';

final class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({
    required FirebaseAuthGateway firebase,
    required GoogleAccountGateway google,
  }) : _firebase = firebase,
       _google = google;

  final FirebaseAuthGateway _firebase;
  final GoogleAccountGateway _google;

  @override
  Stream<AuthState> get authStateChanges => _firebase.authStateChanges().map(
    (user) => user == null ? const SignedOut() : SignedIn(user),
  );

  @override
  Future<SignInOutcome> signIn() => throw UnimplementedError();

  @override
  Future<void> signOut() => throw UnimplementedError();

  @override
  Future<void> deleteAccount() => throw UnimplementedError();
}
