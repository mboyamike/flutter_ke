import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile/repositories/auth_repository/auth_repository.dart';
import 'package:mobile/router/app_router.dart';
import 'package:mobile/router/app_router.gr.dart';
import 'package:mobile/ui/home/pages/home_page.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository mockAuthRepository;
  late AppRouter router;

  Future<void> pumpSignInPage(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWith((ref) async => mockAuthRepository),
        ],
        child: MaterialApp.router(routerConfig: router.config()),
      ),
    );

    await tester.pumpAndSettle();

    router.push(const SignInRoute());

    await tester.pumpAndSettle();
  }

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    router = AppRouter();

    when(() => mockAuthRepository.currentUser()).thenReturn(null);
    when(() => mockAuthRepository.userStream()).thenAnswer((_) => Stream.empty());
    when(
      () => mockAuthRepository.signInWithEmailAndPassword(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) async => null);
  });

  testWidgets('renders sign in form fields and CTA', (tester) async {
    await pumpSignInPage(tester);

    expect(find.text('Sign In'), findsOneWidget);
    expect(find.byKey(const ValueKey('sign_in_email')), findsOneWidget);
    expect(find.byKey(const ValueKey('sign_in_password')), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Sign in'), findsOneWidget);
  });

  testWidgets('shows validation errors when fields are empty', (tester) async {
    await pumpSignInPage(tester);

    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle();

    expect(find.text('Email is required'), findsOneWidget);
    expect(find.text('Password is required'), findsOneWidget);
    verifyNever(
      () => mockAuthRepository.signInWithEmailAndPassword(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    );
  });

  testWidgets('shows invalid email message', (tester) async {
    await pumpSignInPage(tester);

    await tester.enterText(find.byKey(const ValueKey('sign_in_email')), 'invalid');
    await tester.enterText(
      find.byKey(const ValueKey('sign_in_password')),
      'password123',
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle();

    expect(find.text('Please enter a valid email address'), findsOneWidget);
    verifyNever(
      () => mockAuthRepository.signInWithEmailAndPassword(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    );
  });

  testWidgets('shows minimum password length message', (tester) async {
    await pumpSignInPage(tester);

    await tester.enterText(
      find.byKey(const ValueKey('sign_in_email')),
      'tester@example.com',
    );
    await tester.enterText(find.byKey(const ValueKey('sign_in_password')), 'short');

    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle();

    expect(
      find.text('Password must be at least 8 characters'),
      findsOneWidget,
    );
    verifyNever(
      () => mockAuthRepository.signInWithEmailAndPassword(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    );
  });

  testWidgets('submits with valid values and navigates to home', (tester) async {
    await pumpSignInPage(tester);

    await tester.enterText(
      find.byKey(const ValueKey('sign_in_email')),
      'tester@example.com',
    );
    await tester.enterText(
      find.byKey(const ValueKey('sign_in_password')),
      'password123',
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle();

    verify(
      () => mockAuthRepository.signInWithEmailAndPassword(
        email: 'tester@example.com',
        password: 'password123',
      ),
    ).called(1);
    expect(find.byWidgetPredicate((widget) => widget is HomePage), findsOneWidget);
  });

  testWidgets('shows snackbar when sign in fails', (tester) async {
    when(
      () => mockAuthRepository.signInWithEmailAndPassword(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenThrow(Exception('boom'));

    await pumpSignInPage(tester);

    await tester.enterText(
      find.byKey(const ValueKey('sign_in_email')),
      'tester@example.com',
    );
    await tester.enterText(
      find.byKey(const ValueKey('sign_in_password')),
      'password123',
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle();

    expect(find.text('An error occurred during signing in'), findsOneWidget);
  });

}