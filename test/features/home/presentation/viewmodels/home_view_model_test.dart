import 'package:demo/app/router/app_routes.dart';
import 'package:demo/features/home/presentation/viewmodels/home_view_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import '../../../../helpers/mocks.dart';

void main() {
  late MockNavigationService navigation;
  late HomeViewModel viewModel;

  setUp(() {
    navigation = MockNavigationService();
    viewModel = HomeViewModel(navigation);
  });

  group('HomeViewModel', () {
    test('openAbout pushes the about route', () async {
      await viewModel.openAbout();

      verify(navigation.push<void>(AppRoutes.about)).called(1);
      verifyNoMoreInteractions(navigation);
    });

    test('starts idle without errors', () {
      expect(viewModel.isBusy, isFalse);
      expect(viewModel.hasError, isFalse);
    });
  });
}
