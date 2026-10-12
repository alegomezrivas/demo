import 'dart:async';

import 'package:demo/app/router/app_routes.dart';
import 'package:demo/core/services/navigation_service.dart';
import 'package:demo/core/services/session_service.dart';
import 'package:demo/core/usecases/use_case.dart';
import 'package:demo/features/auth/domain/entities/user.dart';
import 'package:demo/features/auth/domain/usecases/get_current_user_use_case.dart';
import 'package:demo/features/auth/domain/usecases/logout_use_case.dart';
import 'package:stacked/stacked.dart';

/// ViewModel of the landing screen.
class HomeViewModel extends BaseViewModel {
  /// Creates the ViewModel with its dependencies.
  HomeViewModel({
    required this._navigation,
    required this._getCurrentUser,
    required this._logout,
    required this._session,
  });

  final NavigationService _navigation;
  final GetCurrentUserUseCase _getCurrentUser;
  final LogoutUseCase _logout;
  final SessionService _session;

  User? _user;

  /// The signed-in user, once loaded.
  User? get user => _user;

  /// Loads the signed-in user.
  Future<void> init() async {
    final result = await _getCurrentUser(const NoParams());
    _user = result.fold((_) => null, (user) => user);
    notifyListeners();
  }

  /// Opens the "about" screen.
  Future<void> openAbout() => _navigation.push<void>(AppRoutes.about);

  /// Ends the session and returns to the sign-in screen.
  Future<void> logout() async {
    await _logout(const NoParams());
    _session.markSignedOut();
    _navigation.go(AppRoutes.login);
  }
}
