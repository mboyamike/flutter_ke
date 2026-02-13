import 'dart:developer';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_riverpod/experimental/mutation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../providers/auth/auth_notifier_provider.dart';
import '../../../router/app_router.gr.dart';
import '../../../services/validator_service/validator_service.dart';

@RoutePage()
class SignInPage extends StatelessWidget {
  const SignInPage({super.key});

  static const path = '/auth/sign_in';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Flutter Kenya')),
      body: Container(
        padding: const EdgeInsets.all(16.0),
        alignment: Alignment.center,
        child: const SignInForm(),
      ),
    );
  }
}

final _signInMutation = Mutation();

class SignInForm extends HookConsumerWidget {
  const SignInForm({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    ValueNotifier<bool> obscurePassword = useState(true);

    final emailController = useTextEditingController();
    final passwordController = useTextEditingController();
    final formKey = useMemoized(GlobalKey<FormState>.new);

    final minPasswordLength = 8;

    Future<void> submit() async {
      if (formKey.currentState?.validate() ?? false) {
        final email = emailController.text.trim();
        final password = passwordController.text.trim();

        _signInMutation.run(ref, (tsx) async {
          TextInput.finishAutofillContext();
          final scaffoldMessenger = ScaffoldMessenger.of(context);
          final router = context.router;

          final authNotifier = tsx.get(authProvider.notifier);
          try {
            await authNotifier.signInWithEmailAndPassword(
              email: email,
              password: password,
            );

            router.replace(HomeRoute());
          } catch (e, stackTrace) {
            log(
              'Error signing in',
              error: e,
              stackTrace: stackTrace,
              level: 1000,
            );

            scaffoldMessenger.showSnackBar(
              const SnackBar(
                content: Text('An error occurred during signing in'),
              ),
            );
          }
        });
      }
    }

    final signInState = ref.watch(_signInMutation);

    return Form(
      key: formKey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            header: true,
            child: Text('Sign In', style: textTheme.titleLarge),
          ),
          const SizedBox(height: 32),
          AutofillGroup(
            child: Column(
              children: [
                TextFormField(
                  controller: emailController,
                  key: const ValueKey('sign_in_email'),
                  keyboardType: TextInputType.emailAddress,
                  autofocus: true,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.email],
                  textCapitalization: TextCapitalization.none,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Email is required';
                    }
                    return ValidatorService.emailFormatValidator(v.trim());
                  },
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    hintText: 'example@gmail.com',
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: passwordController,
                  key: const ValueKey('sign_in_password'),
                  keyboardType: TextInputType.visiblePassword,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.password],
                  obscureText: obscurePassword.value,
                  enableSuggestions: false,
                  autocorrect: false,
                  onFieldSubmitted: (_) => submit(),
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
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              onPressed: switch (signInState) {
                MutationPending() => null,
                _ => () => submit(),
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Sign in'),
                  if (signInState is MutationPending) ...[
                    const SizedBox(width: 8),
                    const SizedBox.square(dimension: 14, child: CircularProgressIndicator(strokeWidth: 2,)),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Align(
            alignment: Alignment.centerLeft,
            child: RichText(
              text: TextSpan(
                text: "Don't have an account? ",
                style: TextStyle(color: theme.colorScheme.onSurface),
                children: [
                  TextSpan(
                    text: 'Sign Up',
                    style: TextStyle(color: theme.colorScheme.primary),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () => context.replaceRoute(SignUpRoute()),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
