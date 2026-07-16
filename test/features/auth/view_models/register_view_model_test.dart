import 'package:flutter_test/flutter_test.dart';
import 'package:my_garage/features/auth/view_models/register_view_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('RegisterViewModel', () {
    test('shows existing account message when signUp returns empty identities',
        () async {
      final viewModel = RegisterViewModel(
        signUp: ({
          required email,
          required password,
        }) async {
          return AuthResponse(
            user: _user(identities: const []),
          );
        },
      );

      viewModel
        ..updateEmail('existing@example.com')
        ..updatePassword('password123')
        ..updateConfirmPassword('password123');

      await viewModel.signUp();

      expect(viewModel.state.isRegistered, isFalse);
      expect(viewModel.state.errorMessage, contains('可能已註冊'));
      expect(viewModel.state.message, isNull);
      expect(viewModel.state.password, isEmpty);
      expect(viewModel.state.confirmPassword, isEmpty);
    });

    test('shows verification message when signUp creates a new user', () async {
      final viewModel = RegisterViewModel(
        signUp: ({
          required email,
          required password,
        }) async {
          return AuthResponse(
            user: _user(
              identities: const [
                UserIdentity(
                  id: 'identity-id',
                  userId: 'user-id',
                  identityData: {'email': 'new@example.com'},
                  identityId: 'identity-id',
                  provider: 'email',
                  createdAt: '2026-07-16T00:00:00Z',
                  lastSignInAt: null,
                ),
              ],
            ),
          );
        },
      );

      viewModel
        ..updateEmail('new@example.com')
        ..updatePassword('password123')
        ..updateConfirmPassword('password123');

      await viewModel.signUp();

      expect(viewModel.state.isRegistered, isTrue);
      expect(viewModel.state.message, contains('請至信箱'));
      expect(viewModel.state.errorMessage, isNull);
    });
  });
}

User _user({List<UserIdentity>? identities}) {
  return User(
    id: 'user-id',
    appMetadata: const {},
    userMetadata: const {},
    aud: 'authenticated',
    email: 'user@example.com',
    createdAt: '2026-07-16T00:00:00Z',
    identities: identities,
  );
}
