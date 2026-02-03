import 'package:mobile/providers/supabase/supabase_client_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_repository.g.dart';

class AuthRepository {
  AuthRepository({required this.client});

  final GoTrueClient client;

  Stream<AuthState> userStream() => client.onAuthStateChange;
  User? currentUser() => client.currentUser;

  Future<Session?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final response = await client.signInWithPassword(
        email: email,
        password: password,
      );
      return response.session;
    } on AuthException catch (e) {
      throw AuthRepositoryException(e.message);
    } catch (e) {
      throw AuthRepositoryException('An unexpected error occurred');
    }
  }

  Future<Session?> signUpWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final response = await client.signUp(email: email, password: password);
      return response.session;
    } on AuthException catch (e) {
      throw AuthRepositoryException(e.message);
    } catch (e) {
      throw AuthRepositoryException('An unexpected error occurred');
    }
  }

  Future<void> signOut() async {
    try {
      await client.signOut();
    } on AuthException catch (e) {
      throw AuthRepositoryException(e.message);
    } catch (e) {
      throw AuthRepositoryException('An unexpected error occurred');
    }
  }
}

class AuthRepositoryException implements Exception {
  final String message;

  AuthRepositoryException(this.message);

  @override
  String toString() => message;
}

@riverpod
Future<AuthRepository> authRepository(Ref ref) async {
  final supabaseClient = await ref.watch(supabaseClientProvider.future);
  return AuthRepository(client: supabaseClient.auth);
}
