import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/user.dart';
import '../repositories/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

final authStateProvider = StreamProvider<AppUser?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges();
});

final authControllerProvider = Provider((ref) => AuthController(ref));

class AuthController {
  final Ref _ref;

  AuthController(this._ref);

  Future<void> signUp(String email, String password) async {
    await _ref.read(authRepositoryProvider).signUp(email, password);
  }

  Future<void> signIn(String email, String password) async {
    await _ref.read(authRepositoryProvider).signIn(email, password);
  }

  Future<void> signOut() async {
    await _ref.read(authRepositoryProvider).signOut();
  }

  Future<void> forgotPassword(String email) async {
    await _ref.read(authRepositoryProvider).forgotPassword(email);
  }
}
