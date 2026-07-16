import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RegisterState {
  const RegisterState({
    this.email = '',
    this.password = '',
    this.confirmPassword = '',
    this.isLoading = false,
    this.isPasswordVisible = false,
    this.isConfirmPasswordVisible = false,
    this.isRegistered = false,
    this.message,
    this.errorMessage,
  });

  final String email;
  final String password;
  final String confirmPassword;
  final bool isLoading;
  final bool isPasswordVisible;
  final bool isConfirmPasswordVisible;
  final bool isRegistered;
  final String? message;
  final String? errorMessage;

  bool get canSubmit {
    return email.trim().isNotEmpty &&
        password.isNotEmpty &&
        confirmPassword.isNotEmpty &&
        !isLoading;
  }

  RegisterState copyWith({
    String? email,
    String? password,
    String? confirmPassword,
    bool? isLoading,
    bool? isPasswordVisible,
    bool? isConfirmPasswordVisible,
    bool? isRegistered,
    String? message,
    String? errorMessage,
    bool clearMessage = false,
    bool clearError = false,
  }) {
    return RegisterState(
      email: email ?? this.email,
      password: password ?? this.password,
      confirmPassword: confirmPassword ?? this.confirmPassword,
      isLoading: isLoading ?? this.isLoading,
      isPasswordVisible: isPasswordVisible ?? this.isPasswordVisible,
      isConfirmPasswordVisible:
          isConfirmPasswordVisible ?? this.isConfirmPasswordVisible,
      isRegistered: isRegistered ?? this.isRegistered,
      message: clearMessage ? null : message ?? this.message,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

typedef SignUpWithPassword = Future<AuthResponse> Function({
  required String email,
  required String password,
});

class RegisterViewModel extends StateNotifier<RegisterState> {
  RegisterViewModel({
    required SignUpWithPassword signUp,
  })  : _signUp = signUp,
        super(const RegisterState());

  final SignUpWithPassword _signUp;

  void updateEmail(String value) {
    state = state.copyWith(
      email: value,
      isRegistered: false,
      clearError: true,
      clearMessage: true,
    );
  }

  void updatePassword(String value) {
    state = state.copyWith(
      password: value,
      isRegistered: false,
      clearError: true,
      clearMessage: true,
    );
  }

  void updateConfirmPassword(String value) {
    state = state.copyWith(
      confirmPassword: value,
      isRegistered: false,
      clearError: true,
      clearMessage: true,
    );
  }

  void togglePasswordVisibility() {
    state = state.copyWith(isPasswordVisible: !state.isPasswordVisible);
  }

  void toggleConfirmPasswordVisibility() {
    state = state.copyWith(
      isConfirmPasswordVisible: !state.isConfirmPasswordVisible,
    );
  }

  Future<void> signUp() async {
    if (!state.canSubmit) {
      state = state.copyWith(errorMessage: '請輸入 Email、密碼與確認密碼');
      return;
    }

    if (state.password.length < 6) {
      state = state.copyWith(errorMessage: '密碼至少需要 6 碼');
      return;
    }

    if (state.password != state.confirmPassword) {
      state = state.copyWith(errorMessage: '兩次輸入的密碼不一致');
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final response = await _signUp(
        email: state.email.trim(),
        password: state.password,
      );
      final hasSession = response.session != null;
      final identities = response.user?.identities;
      final isLikelyExistingAccount =
          !hasSession && identities != null && identities.isEmpty;

      if (isLikelyExistingAccount) {
        state = state.copyWith(
          password: '',
          confirmPassword: '',
          isLoading: false,
          isRegistered: false,
          errorMessage: '這個 Email 可能已註冊，請直接登入；如果忘記密碼，可再使用重設密碼流程。',
          clearMessage: true,
        );
        return;
      }

      state = state.copyWith(
        password: '',
        confirmPassword: '',
        isLoading: false,
        isRegistered: true,
        message: hasSession ? '註冊成功' : '註冊成功，請至信箱完成驗證後再登入',
        clearError: true,
      );
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
        errorMessage: '註冊失敗，請稍後再試',
      );
    }
  }
}
