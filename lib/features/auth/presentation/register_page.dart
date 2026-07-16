import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_providers.dart';

class RegisterPage extends ConsumerWidget {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(registerViewModelProvider);
    final viewModel = ref.read(registerViewModelProvider.notifier);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('建立帳號')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 76,
                    height: 76,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      Icons.motorcycle_outlined,
                      size: 42,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    '加入 My Garage',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '建立帳號後即可同步管理你的車輛、保養與加油紀錄',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 32),
                  TextField(
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.email],
                    enabled: !state.isLoading && !state.isRegistered,
                    onChanged: viewModel.updateEmail,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      hintText: '請輸入 Email',
                      prefixIcon: Icon(Icons.mail_outline),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    obscureText: !state.isPasswordVisible,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.newPassword],
                    enabled: !state.isLoading && !state.isRegistered,
                    onChanged: viewModel.updatePassword,
                    decoration: InputDecoration(
                      labelText: '密碼',
                      hintText: '至少 6 碼',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        tooltip: state.isPasswordVisible ? '隱藏密碼' : '顯示密碼',
                        onPressed: state.isLoading
                            ? null
                            : viewModel.togglePasswordVisibility,
                        icon: Icon(
                          state.isPasswordVisible
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    obscureText: !state.isConfirmPasswordVisible,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.newPassword],
                    enabled: !state.isLoading && !state.isRegistered,
                    onChanged: viewModel.updateConfirmPassword,
                    onSubmitted: (_) => viewModel.signUp(),
                    decoration: InputDecoration(
                      labelText: '確認密碼',
                      hintText: '請再次輸入密碼',
                      prefixIcon: const Icon(Icons.lock_reset_outlined),
                      suffixIcon: IconButton(
                        tooltip:
                            state.isConfirmPasswordVisible ? '隱藏密碼' : '顯示密碼',
                        onPressed: state.isLoading
                            ? null
                            : viewModel.toggleConfirmPasswordVisibility,
                        icon: Icon(
                          state.isConfirmPasswordVisible
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                      ),
                    ),
                  ),
                  if (state.errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      state.errorMessage!,
                      style: TextStyle(color: colorScheme.error),
                    ),
                  ],
                  if (state.message != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      state.message!,
                      style: TextStyle(color: colorScheme.primary),
                    ),
                  ],
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: state.canSubmit ? viewModel.signUp : null,
                    child: state.isLoading
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('建立帳號'),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: state.isLoading
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: Text(state.isRegistered ? '回到登入' : '已有帳號？登入'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
