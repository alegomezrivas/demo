import 'package:demo/core/utils/logging/app_logger.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late List<String> lines;

  setUp(() => lines = []);

  group('ConsoleAppLogger', () {
    test('prints messages at or above the minimum level', () {
      ConsoleAppLogger(minLevel: LogLevel.warning, sink: lines.add)
        ..debug('d')
        ..info('i')
        ..warning('w')
        ..error('e');

      expect(lines, ['[WARNING] w', '[ERROR] e']);
    });

    test('redacts secrets before printing', () {
      ConsoleAppLogger(sink: lines.add).info('token=abc123');

      expect(lines.single, isNot(contains('abc123')));
    });

    test('records only the runtime type of an error', () {
      ConsoleAppLogger(
        sink: lines.add,
      ).error('failed', error: StateError('pw'));

      expect(lines.single, contains('StateError'));
      expect(lines.single, isNot(contains('pw')));
    });

    test('prints nothing when disabled', () {
      ConsoleAppLogger(minLevel: LogLevel.none, sink: lines.add).error('x');

      expect(lines, isEmpty);
    });

    test('forMode reduces verbosity in release builds', () {
      ConsoleAppLogger.forMode(isRelease: true, sink: lines.add)
        ..info('i')
        ..error('e');
      ConsoleAppLogger.forMode(sink: lines.add).debug('d');

      expect(lines, ['[ERROR] e', '[DEBUG] d']);
    });
  });
}
