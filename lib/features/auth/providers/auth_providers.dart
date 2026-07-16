import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/providers/supabase_providers.dart';
import '../data/auth_repository.dart';
import '../view_models/login_view_model.dart';
import '../view_models/register_view_model.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return AuthRepository(client);
});

final loginViewModelProvider =
    StateNotifierProvider<LoginViewModel, LoginState>((ref) {
  return LoginViewModel(
    signInWithPassword: ({
      required email,
      required password,
    }) {
      final repository = ref.read(authRepositoryProvider);

      return repository.signInWithPassword(
        email: email,
        password: password,
      );
    },
  );
});

final registerViewModelProvider =
    StateNotifierProvider<RegisterViewModel, RegisterState>((ref) {
  return RegisterViewModel(
    signUp: ({
      required email,
      required password,
    }) {
      final repository = ref.read(authRepositoryProvider);

      return repository.signUp(
        email: email,
        password: password,
      );
    },
  );
});
