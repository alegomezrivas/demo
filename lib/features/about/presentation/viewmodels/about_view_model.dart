import 'package:demo/core/services/navigation_service.dart';
import 'package:stacked/stacked.dart';

/// ViewModel of the "about" screen.
class AboutViewModel extends BaseViewModel {
  /// Creates the ViewModel with its navigation dependency.
  AboutViewModel(this._navigation);

  final NavigationService _navigation;

  /// Returns to the previous screen.
  void goBack() => _navigation.pop<void>();
}
