import 'package:mobile/repositories/auth_repository/auth_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'auth_notifier_provider.g.dart';

@riverpod
class AuthNotifier extends _$AuthNotifier {
  @override
  Stream<User?> build() async* {
    final authRepository = await ref.watch(authRepositoryProvider.future);
    yield authRepository.currentUser();

    yield* authRepository.userStream().map(
      (authState) => authState.session?.user,
    );
  }

  Future<void> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final authRepository = await ref.read(authRepositoryProvider.future);
    await authRepository.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signUpWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final authRepository = await ref.read(authRepositoryProvider.future);
    await authRepository.signUpWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    final authRepository = await ref.read(authRepositoryProvider.future);
    await authRepository.signOut();
  }
}
