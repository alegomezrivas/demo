import 'package:demo/core/services/data_change_notifier.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DataChangeNotifier', () {
    test('emits an event for every change to every listener', () async {
      final notifier = DataChangeNotifier();
      var first = 0;
      var second = 0;
      final subscriptions = [
        notifier.onChanged.listen((_) => first++),
        notifier.onChanged.listen((_) => second++),
      ];

      notifier
        ..notifyChanged()
        ..notifyChanged();
      await Future<void>.delayed(Duration.zero);

      expect(first, 2);
      expect(second, 2);
      for (final subscription in subscriptions) {
        await subscription.cancel();
      }
      await notifier.dispose();
    });

    test('ignores changes after dispose', () async {
      final notifier = DataChangeNotifier();
      await notifier.dispose();

      expect(notifier.notifyChanged, returnsNormally);
    });
  });
}
