import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final SupabaseClient _supabaseClient;

  AuthRepositoryImpl(this._supabaseClient);

  @override
  Stream<AuthState> get authStateChanges => _supabaseClient.auth.onAuthStateChange;

  @override
  User? get currentUser => _supabaseClient.auth.currentUser;

  @override
  Future<void> signInWithEmailAndPassword({
    required String email, 
    required String password
  }) async {
    try {
      await _supabaseClient.auth.signInWithPassword(
        email: email, 
        password: password
      );
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Ocurrió un error inesperado al iniciar sesión.');
    }
  }

  @override
  Future<void> signUpWithEmailAndPassword({
    required String email, 
    required String password,
    required String fullName,
  }) async {
    try {
      final response = await _supabaseClient.auth.signUp(
        email: email, 
        password: password,
      );

      final userId = response.user?.id;
      if (userId != null) {
        // Insert profile record with full_name right after sign-up
        await _supabaseClient.from('profiles').insert({
          'user_id': userId,
          'full_name': fullName.trim(),
          'coins': 0,
          'level': 1,
        });
      }
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Ocurrió un error al registrarse: ${e.toString()}');
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _supabaseClient.auth.signOut();
    } catch (e) {
      throw Exception('No se pudo cerrar la sesión.');
    }
  }
}
