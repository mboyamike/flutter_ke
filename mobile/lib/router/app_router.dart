import 'package:auto_route/auto_route.dart';
import 'package:mobile/router/app_router.gr.dart';
import 'package:mobile/ui/authentication/pages/sign_in_page.dart';
import 'package:mobile/ui/authentication/pages/sign_up_page.dart';
import 'package:mobile/ui/home/pages/home_page.dart';
import 'package:mobile/ui/splash/pages/splash_page.dart';

@AutoRouterConfig()
class AppRouter extends RootStackRouter {
  @override
  List<AutoRoute> get routes => [
    AutoRoute(page: SplashRoute.page, path: SplashPage.path),
    AutoRoute(page: SignInRoute.page, path: SignInPage.path),
    AutoRoute(page: SignUpRoute.page, path: SignUpPage.path),
    AutoRoute(page: HomeRoute.page, path: HomePage.path),
  ];
}
