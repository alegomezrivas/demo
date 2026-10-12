import 'package:demo/core/network/mock/mock_route.dart';
import 'package:demo/core/network/mock/mock_scenario.dart';
import 'package:flutter_test/flutter_test.dart';

MockResponse ok(MockRequest _) => const MockResponse();

void main() {
  group('MockRoute.match', () {
    test('matches an exact path and method', () {
      final route = MockRoute(method: 'get', pattern: '/tasks', handler: ok);

      expect(route.match('GET', '/tasks'), isEmpty);
      expect(route.match('get', '/tasks/'), isEmpty);
    });

    test('captures :name segments', () {
      final route = MockRoute(
        method: 'GET',
        pattern: '/tasks/:id/notes/:note',
        handler: ok,
      );

      expect(route.match('GET', '/tasks/42/notes/a%20b'), {
        'id': '42',
        'note': 'a b',
      });
    });

    test('does not match another method, path or segment count', () {
      final route = MockRoute(
        method: 'GET',
        pattern: '/tasks/:id',
        handler: ok,
      );

      expect(route.match('POST', '/tasks/1'), isNull);
      expect(route.match('GET', '/other/1'), isNull);
      expect(route.match('GET', '/tasks'), isNull);
      expect(route.match('GET', '/tasks/1/extra'), isNull);
    });
  });

  group('MockScenario.parse', () {
    test('parses every known header value', () {
      expect(MockScenario.parse('server_error'), MockScenario.serverError);
      expect(MockScenario.parse('offline'), MockScenario.offline);
      expect(MockScenario.parse('unauthorized'), MockScenario.unauthorized);
      expect(
        MockScenario.parse('unauthorized_once'),
        MockScenario.unauthorizedOnce,
      );
    });

    test('falls back to none for unknown or missing values', () {
      expect(MockScenario.parse('weird'), MockScenario.none);
      expect(MockScenario.parse(null), MockScenario.none);
    });
  });
}
