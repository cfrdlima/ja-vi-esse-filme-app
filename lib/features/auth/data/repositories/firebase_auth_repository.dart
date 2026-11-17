import '../../domain/entities/auth_state.dart';
import '../../domain/entities/sign_in_outcome.dart';
import '../../domain/repositories/auth_repository.dart';
import '../gateways/auth_gateways.dart';

final class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({required this._firebase, required this._google});

  final FirebaseAuthGateway _firebase;
  final GoogleAccountGateway _google;

  @override
  Stream<AuthState> get authStateChanges => _firebase.authStateChanges().map(
    (user) => user == null ? const SignedOut() : SignedIn(user),
  );

  @override
  Future<SignInOutcome> signIn() async {
    final idToken = await _google.authenticate();
    final user = await _firebase.signInWithGoogleIdToken(idToken!);
    return SignInCompleted(user);
  }

  @override
  Future<void> signOut() => throw UnimplementedError();

  @override
  Future<void> deleteAccount() => throw UnimplementedError();
}
