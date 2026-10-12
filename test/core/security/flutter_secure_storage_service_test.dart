import 'package:demo/core/error/exceptions.dart';
import 'package:demo/core/security/flutter_secure_storage_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import '../../helpers/mocks.dart';

void main() {
  late MockFlutterSecureStorage backend;
  late FlutterSecureStorageService service;

  setUp(() {
    backend = MockFlutterSecureStorage();
    service = FlutterSecureStorageService(backend);
  });

  group('FlutterSecureStorageService', () {
    test('delegates read, write and delete to the backend', () async {
      when(backend.read(key: 'k')).thenAnswer((_) async => 'v');

      expect(await service.read('k'), 'v');
      await service.write('k', 'v2');
      await service.delete('k');

      verify(backend.write(key: 'k', value: 'v2')).called(1);
      verify(backend.delete(key: 'k')).called(1);
    });

    test('deleteAll clears the backend', () async {
      await service.deleteAll();

      verify(backend.deleteAll()).called(1);
    });

    test('hides platform errors behind a CacheException', () async {
      when(
        backend.read(key: 'k'),
      ).thenThrow(PlatformException(code: 'keystore', message: 'secret'));

      await expectLater(
        service.read('k'),
        throwsA(
          isA<CacheException>().having(
            (e) => e.code,
            'code',
            'secure_storage_error',
          ),
        ),
      );
    });
  });
}
