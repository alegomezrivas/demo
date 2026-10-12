import 'package:demo/features/about/presentation/viewmodels/about_view_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import '../../../../helpers/mocks.dart';

void main() {
  late MockNavigationService navigation;
  late AboutViewModel viewModel;

  setUp(() {
    navigation = MockNavigationService();
    viewModel = AboutViewModel(navigation);
  });

  group('AboutViewModel', () {
    test('goBack pops the current route', () {
      viewModel.goBack();

      verify(navigation.pop<void>()).called(1);
      verifyNoMoreInteractions(navigation);
    });
  });
}
