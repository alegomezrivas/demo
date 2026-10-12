/// Navigation abstraction used by ViewModels so routing can be mocked in tests.
abstract interface class NavigationService {
  /// Replaces the navigation stack with [location].
  void go(String location, {Object? extra});

  /// Pushes [location] on top of the stack and completes with its result.
  Future<T?> push<T extends Object?>(String location, {Object? extra});

  /// Replaces the current route with [location].
  void replace(String location, {Object? extra});

  /// Pops the current route, optionally returning [result].
  void pop<T extends Object?>([T? result]);

  /// Whether there is a route to pop.
  bool get canPop;
}
