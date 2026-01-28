import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/router/app_router.dart';
import 'package:mobile/ui/theme/theme.dart';

void main() {
  runApp(ProviderScope(child: const MyApp()));
}

final _appRouter = AppRouter();

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: _appRouter.config(),
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      title: 'Flutter Kenya',
    );
  }
}
