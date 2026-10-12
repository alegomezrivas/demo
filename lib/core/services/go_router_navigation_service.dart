import 'package:demo/core/services/navigation_service.dart';
import 'package:go_router/go_router.dart';

/// [NavigationService] implementation backed by [GoRouter].
class GoRouterNavigationService implements NavigationService {
  /// Creates the service around an existing GoRouter.
  const GoRouterNavigationService(this._router);

  final GoRouter _router;

  @override
  void go(String location, {Object? extra}) =>
      _router.go(location, extra: extra);

  @override
  Future<T?> push<T extends Object?>(String location, {Object? extra}) =>
      _router.push<T>(location, extra: extra);

  @override
  void replace(String location, {Object? extra}) =>
      _router.replace<Object?>(location, extra: extra);

  @override
  void pop<T extends Object?>([T? result]) => _router.pop(result);

  @override
  bool get canPop => _router.canPop();
}
