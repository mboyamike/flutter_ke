import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile/repositories/auth_repository/auth_repository.dart';
import 'package:mobile/router/app_router.dart';
import 'package:mobile/router/app_router.gr.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository mockAuthRepository;
  late AppRouter router;

  Future<void> pumpSignUpPage(WidgetTester tester) async {
    
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWith((ref) async => mockAuthRepository),
        ],
        child: MaterialApp.router(routerConfig: router.config()),
      ),
    );
    
    await tester.pumpAndSettle();
    
    router.push(const SignUpRoute());
    
    await tester.pumpAndSettle();
    
  }

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    router = AppRouter();

    when(() => mockAuthRepository.currentUser()).thenReturn(null);
    when(() => mockAuthRepository.userStream()).thenAnswer((_) => Stream.empty());
    when(
      () => mockAuthRepository.signUpWithEmailAndPassword(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) async => null);
  });

  testWidgets('renders sign up form fields and CTA', (tester) async {
    
    await pumpSignUpPage(tester);
    

    expect(find.text('Sign Up'), findsOneWidget);
    expect(find.byKey(const ValueKey('sign_up_email')), findsOneWidget);
    expect(find.byKey(const ValueKey('sign_up_password')), findsOneWidget);
    expect(find.byKey(const ValueKey('sign_up_confirm_password')), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Sign up'), findsOneWidget);
  });

  testWidgets('shows validation errors when fields are empty', (tester) async {
    await pumpSignUpPage(tester);

    await tester.tap(find.widgetWithText(FilledButton, 'Sign up'));
    await tester.pumpAndSettle();

    expect(find.text('Email is required'), findsOneWidget);
    expect(find.text('Password is required'), findsOneWidget);
    expect(find.text('Confirm your password'), findsOneWidget);
    verifyNever(
      () => mockAuthRepository.signUpWithEmailAndPassword(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    );
  });

  testWidgets('shows invalid email message', (tester) async {
    await pumpSignUpPage(tester);

    await tester.enterText(find.byKey(const ValueKey('sign_up_email')), 'invalid');
    await tester.enterText(
      find.byKey(const ValueKey('sign_up_password')),
      'password123',
    );
    await tester.enterText(
      find.byKey(const ValueKey('sign_up_confirm_password')),
      'password123',
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Sign up'));
    await tester.pumpAndSettle();

    expect(find.text('Please enter a valid email address'), findsOneWidget);
    verifyNever(
      () => mockAuthRepository.signUpWithEmailAndPassword(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    );
  });

  testWidgets('shows mismatched passwords message', (tester) async {
    await pumpSignUpPage(tester);

    await tester.enterText(
      find.byKey(const ValueKey('sign_up_email')),
      'tester@example.com',
    );
    await tester.enterText(
      find.byKey(const ValueKey('sign_up_password')),
      'password123',
    );
    await tester.enterText(
      find.byKey(const ValueKey('sign_up_confirm_password')),
      'different-password',
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Sign up'));
    await tester.pumpAndSettle();

    expect(find.text('Passwords do not match'), findsOneWidget);
    verifyNever(
      () => mockAuthRepository.signUpWithEmailAndPassword(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    );
  });

  testWidgets('submits with valid values and navigates to home', (tester) async {
    await pumpSignUpPage(tester);

    await tester.enterText(
      find.byKey(const ValueKey('sign_up_email')),
      'tester@example.com',
    );
    await tester.enterText(
      find.byKey(const ValueKey('sign_up_password')),
      'password123',
    );
    await tester.enterText(
      find.byKey(const ValueKey('sign_up_confirm_password')),
      'password123',
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Sign up'));
    await tester.pumpAndSettle();

    verify(
      () => mockAuthRepository.signUpWithEmailAndPassword(
        email: 'tester@example.com',
        password: 'password123',
      ),
    ).called(1);
    expect(find.text('Flutter Ke'), findsOneWidget);
  });

  testWidgets('shows snackbar when sign up fails', (tester) async {
    when(
      () => mockAuthRepository.signUpWithEmailAndPassword(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenThrow(Exception('boom'));

    await pumpSignUpPage(tester);

    await tester.enterText(
      find.byKey(const ValueKey('sign_up_email')),
      'tester@example.com',
    );
    await tester.enterText(
      find.byKey(const ValueKey('sign_up_password')),
      'password123',
    );
    await tester.enterText(
      find.byKey(const ValueKey('sign_up_confirm_password')),
      'password123',
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Sign up'));
    await tester.pumpAndSettle();

    expect(find.text('An error occurred during signing up'), findsOneWidget);
  });
}