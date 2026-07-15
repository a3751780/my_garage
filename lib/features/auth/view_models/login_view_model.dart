import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginState {
  const LoginState({
    this.email = '',
    this.password = '',
    this.isLoading = false,
    this.isPasswordVisible = false,
    this.errorMessage,
  });

  final String email;
  final String password;
  final bool isLoading;
  final bool isPasswordVisible;
  final String? errorMessage;

  bool get canSubmit =>
      email.trim().isNotEmpty && password.isNotEmpty && !isLoading;

  LoginState copyWith({
    String? email,
    String? password,
    bool? isLoading,
    bool? isPasswordVisible,
    String? errorMessage,
    bool clearError = false,
  }) {
    return LoginState(
      email: email ?? this.email,
      password: password ?? this.password,
      isLoading: isLoading ?? this.isLoading,
      isPasswordVisible: isPasswordVisible ?? this.isPasswordVisible,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

typedef SignInWithPassword = Future<AuthResponse> Function({
  required String email,
  required String password,
});

class LoginViewModel extends StateNotifier<LoginState> {
  LoginViewModel({
    required SignInWithPassword signInWithPassword,
  })  : _signInWithPassword = signInWithPassword,
        super(const LoginState());

  final SignInWithPassword _signInWithPassword;

  void updateEmail(String value) {
    state = state.copyWith(email: value, clearError: true);
  }

  void updatePassword(String value) {
    state = state.copyWith(password: value, clearError: true);
  }

  void togglePasswordVisibility() {
    state = state.copyWith(isPasswordVisible: !state.isPasswordVisible);
  }

  Future<void> signIn() async {
    if (!state.canSubmit) {
      state = state.copyWith(errorMessage: '請輸入帳號與密碼');
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await _signInWithPassword(
        email: state.email.trim(),
        password: state.password,
      );
      state = state.copyWith(isLoading: false, password: '', clearError: true);
    } on AuthException catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: error.message,
      );
    } on StateError catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: error.message,
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: '登入失敗，請稍後再試',
      );
    }
  }
}
