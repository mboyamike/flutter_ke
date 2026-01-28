import 'package:auto_route/auto_route.dart';
import 'package:mobile/router/app_router.gr.dart';

@AutoRouterConfig()
class AppRouter extends RootStackRouter {
  @override
  List<AutoRoute> get routes => [
    AutoRoute(page: HomeRoute.page, path: '/'),
  ];
}
