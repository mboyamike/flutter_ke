import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile/repositories/auth_repository/auth_repository.dart';
import 'package:mobile/router/app_router.dart';
import 'package:mobile/ui/authentication/pages/sign_up_page.dart';
import 'package:mobile/ui/home/pages/home_page.dart';
import 'package:mobile/ui/splash/pages/splash_page.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockUser extends Mock implements User {}

void main() {
  late MockAuthRepository mockAuthRepository;
  late AppRouter router;

  Future<void> pumpSplashPage(
    WidgetTester tester, {
    bool keepLoading = false,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          if (keepLoading)
            authRepositoryProvider.overrideWith((ref) async {
              await Future<void>.delayed(const Duration(seconds: 30));
              return mockAuthRepository;
            })
          else
            authRepositoryProvider.overrideWith((ref) async => mockAuthRepository),
        ],
        child: MaterialApp.router(routerConfig: router.config()),
      ),
    );
  }

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    router = AppRouter();
    when(() => mockAuthRepository.userStream()).thenAnswer((_) => Stream.empty());
  });

  testWidgets('renders splash content', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWith((ref) async {
            final completer = Completer<void>();
            await completer.future;
            return mockAuthRepository;
          }),
        ],
        child: const MaterialApp(home: SplashPage()),
      ),
    );

    expect(find.text('Flutter KE'), findsOneWidget);
  });

  testWidgets('navigates to home page when user is present', (tester) async {
    when(() => mockAuthRepository.currentUser()).thenReturn(MockUser());

    await pumpSplashPage(tester);
    await tester.pumpAndSettle();

    expect(find.byType(HomePage), findsOneWidget);
  });

  testWidgets('navigates to sign up page when user is absent', (tester) async {
    when(() => mockAuthRepository.currentUser()).thenReturn(null);

    await pumpSplashPage(tester);
    await tester.pumpAndSettle();

    expect(find.byType(SignUpPage), findsOneWidget);
  });
}