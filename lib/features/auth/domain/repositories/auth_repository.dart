import 'package:supabase_flutter/supabase_flutter.dart';

abstract class AuthRepository {
  /// Stream to listen for auth state changes (login, logout)
  Stream<AuthState> get authStateChanges;
  
  /// Gets the currently logged in user, if any
  User? get currentUser;
  
  /// Signs in a user with email and password
  Future<void> signInWithEmailAndPassword({
    required String email, 
    required String password
  });
  
  /// Registers a user with email and password
  Future<void> signUpWithEmailAndPassword({
    required String email, 
    required String password,
    required String fullName,
  });
  
  /// Signs out the current user
  Future<void> signOut();
}
