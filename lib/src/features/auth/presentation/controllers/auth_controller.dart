import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider que monitora a instância atual do Firebase User
final authStateChangesProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

/// Provider auxiliar que retorna o usuário logado atualmente (ou null para convidados)
final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authStateChangesProvider).value ?? FirebaseAuth.instance.currentUser;
});
