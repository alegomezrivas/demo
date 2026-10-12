import 'package:demo/core/utils/logging/log_redactor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LogRedactor.redact', () {
    test('masks bearer tokens', () {
      final out = LogRedactor.redact('Authorization: Bearer abc.def-123');

      expect(out, isNot(contains('abc.def')));
      expect(out, contains(LogRedactor.mask));
    });

    test('masks sensitive key-value pairs in JSON and query strings', () {
      final json = LogRedactor.redact('{"password":"hunter2","name":"Ana"}');
      final query = LogRedactor.redact('refreshToken=xyz&page=2');

      expect(json, isNot(contains('hunter2')));
      expect(json, contains('Ana'));
      expect(query, isNot(contains('xyz')));
      expect(query, contains('page=2'));
    });

    test('leaves harmless text untouched', () {
      expect(LogRedactor.redact('GET /tasks 200'), 'GET /tasks 200');
    });
  });
}
