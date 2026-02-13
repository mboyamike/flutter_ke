import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/providers/auth/auth_notifier_provider.dart';
import 'package:mobile/providers/supabase/supabase_client_provider.dart';
import 'package:mobile/router/app_router.dart';
import 'package:mobile/ui/theme/theme.dart';

Future<void> main() async {
  await dotenv.load();

  runApp(ProviderScope(child: const MyApp()));
}

final _appRouter = AppRouter();

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(supabaseClientProvider);
    ref.watch(authProvider);

    return MaterialApp.router(
      routerConfig: _appRouter.config(),
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      title: 'Flutter Kenya',
    );
  }
}
