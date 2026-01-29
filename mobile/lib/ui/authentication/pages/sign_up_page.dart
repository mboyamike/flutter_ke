import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile/services/validator_service/validator_service.dart';

@RoutePage()
class SignUpPage extends StatelessWidget {
  const SignUpPage({super.key});

  static const path = '/auth/sign_up';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Flutter Kenya')),
      body: Container(
        padding: const EdgeInsets.all(16.0),
        alignment: Alignment.center,
        child: const SignUpForm(),
      ),
    );
  }
}

class SignUpForm extends HookConsumerWidget {
  const SignUpForm({super.key});

  Future<void> _submit(BuildContext context, WidgetRef ref) async {
    if (Form.maybeOf(context)?.validate() ?? false) {
      TextInput.finishAutofillContext();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;

    ValueNotifier<bool> obscurePassword = useState(true);
    ValueNotifier<bool> obscureConfirmPassword = useState(true);

    final emailController = useTextEditingController();
    final passwordController = useTextEditingController();
    final confirmPasswordController = useTextEditingController();

    final minPasswordLength = 8;

    return Form(
      child: Semantics(
        label: 'Sign up form',
        child: Builder(
          builder: (context) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Semantics(
                  header: true,
                  child: Text('Sign Up', style: textTheme.titleLarge),
                ),
                const SizedBox(height: 32),
                AutofillGroup(
                  child: Column(
                    children: [
                      TextFormField(
                        controller: emailController,
                        key: const ValueKey('sign_up_email'),
                        keyboardType: TextInputType.emailAddress,
                        autofocus: true,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.email],
                        textCapitalization: TextCapitalization.none,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Email is required';
                          }
                          return ValidatorService.emailFormatValidator(
                            v.trim(),
                          );
                        },
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          hintText: 'example@gmail.com',
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: passwordController,
                        key: const ValueKey('sign_up_password'),
                        keyboardType: TextInputType.visiblePassword,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.newPassword],
                        obscureText: obscurePassword.value,
                        enableSuggestions: false,
                        autocorrect: false,
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'Password is required';
                          }
                          if (v.length < minPasswordLength) {
                            return 'Password must be at least $minPasswordLength characters';
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          labelText: 'Password',
                          hintText: '********',
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscurePassword.value
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                            onPressed: () =>
                                obscurePassword.value = !obscurePassword.value,

                            tooltip: obscurePassword.value
                                ? 'Show password'
                                : 'Hide password',
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: confirmPasswordController,
                        key: const ValueKey('sign_up_confirm_password'),
                        keyboardType: TextInputType.visiblePassword,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.newPassword],
                        obscureText: obscureConfirmPassword.value,
                        enableSuggestions: false,
                        autocorrect: false,
                        onFieldSubmitted: (_) => _submit(context, ref),
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'Confirm your password';
                          }
                          if (v != passwordController.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          labelText: 'Confirm Password',
                          hintText: '********',
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscureConfirmPassword.value
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                            onPressed: () => obscureConfirmPassword.value =
                                !obscureConfirmPassword.value,

                            tooltip: obscureConfirmPassword.value
                                ? 'Show password'
                                : 'Hide password',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    onPressed: () => _submit(context, ref),
                    child: const Text('Sign up'),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
