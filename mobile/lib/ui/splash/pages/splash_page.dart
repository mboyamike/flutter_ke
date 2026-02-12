import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/providers/auth/auth_notifier_provider.dart';
import 'package:mobile/router/app_router.gr.dart';

@RoutePage()
class SplashPage extends ConsumerWidget {
  const SplashPage({super.key});

  static const path = '/';

  void authListener(BuildContext context, AsyncValue currentValue) {
    switch (currentValue) {
        case AsyncLoading():
          return;
        // ignore: unused_local_variable
        case AsyncData(:final value?):
          context.replaceRoute(HomeRoute());
        default: 
          context.replaceRoute(SignUpRoute());
      }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(authProvider, (_, currentValue) {
      authListener(context, currentValue);
    });


    return const Scaffold(body: Center(child: Text('Flutter KE')));
  }
}
