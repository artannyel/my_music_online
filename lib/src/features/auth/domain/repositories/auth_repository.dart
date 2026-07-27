import '../models/user_model.dart';

abstract class AuthRepository {
  Stream<UserModel?> get authStateChanges;
  UserModel? get currentUser;

  Future<UserModel> signInWithEmailAndPassword({
    required String email,
    required String password,
  });

  Future<UserModel> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
  });

  Future<UserModel> signInWithGoogle();

  Future<void> signOut();
}
