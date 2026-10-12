import 'package:demo/app/router/app_routes.dart';
import 'package:demo/core/error/failures.dart';
import 'package:demo/core/services/session_service.dart';
import 'package:demo/features/auth/domain/entities/user.dart';
import 'package:demo/features/home/presentation/viewmodels/home_view_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mockito/mockito.dart';

import '../../../../helpers/mocks.dart';
import '../../../auth/helpers/auth_mocks.dart';

void main() {
  late MockNavigationService navigation;
  late MockGetCurrentUserUseCase getCurrentUser;
  late MockLogoutUseCase logout;
  late SessionService session;
  late HomeViewModel viewModel;
  const user = User(id: '1', name: 'Ana', email: 'ana@test.com');

  setUp(() {
    navigation = MockNavigationService();
    getCurrentUser = MockGetCurrentUserUseCase();
    logout = MockLogoutUseCase();
    session = SessionService(isAuthenticated: true);
    viewModel = HomeViewModel(
      navigation: navigation,
      getCurrentUser: getCurrentUser,
      logout: logout,
      session: session,
    );
  });

  group('HomeViewModel', () {
    test('starts idle without a user', () {
      expect(viewModel.isBusy, isFalse);
      expect(viewModel.hasError, isFalse);
      expect(viewModel.user, isNull);
    });

    test('init loads the signed-in user and notifies listeners', () async {
      when(getCurrentUser(any)).thenAnswer((_) async => right(user));
      var notified = 0;
      viewModel.addListener(() => notified++);

      await viewModel.init();

      expect(viewModel.user, user);
      expect(notified, 1);
    });

    test('init keeps the user null when loading fails', () async {
      when(getCurrentUser(any))
          .thenAnswer((_) async => left(const CacheFailure()));

      await viewModel.init();

      expect(viewModel.user, isNull);
    });

    test('openAbout pushes the about route', () async {
      await viewModel.openAbout();

      verify(navigation.push<void>(AppRoutes.about)).called(1);
    });

    test('logout clears the session and returns to login', () async {
      when(logout(any)).thenAnswer((_) async => right(unit));

      await viewModel.logout();

      verify(logout(any)).called(1);
      expect(session.isAuthenticated, isFalse);
      verify(navigation.go(AppRoutes.login)).called(1);
    });
  });
}
