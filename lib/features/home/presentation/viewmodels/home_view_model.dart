import 'package:demo/app/router/app_routes.dart';
import 'package:demo/core/services/navigation_service.dart';
import 'package:stacked/stacked.dart';

/// ViewModel of the landing screen.
class HomeViewModel extends BaseViewModel {
  /// Creates the ViewModel with its navigation dependency.
  HomeViewModel(this._navigation);

  final NavigationService _navigation;

  /// Opens the "about" screen.
  Future<void> openAbout() => _navigation.push<void>(AppRoutes.about);
}
