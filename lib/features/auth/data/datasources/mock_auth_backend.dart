import 'package:demo/core/network/mock/mock_route.dart';
import 'package:demo/core/network/network_constants.dart';
import 'package:demo/features/auth/data/datasources/auth_endpoints.dart';

/// In-memory fake of the authentication API for the mock Dio backend.
///
/// It is a development fixture: accounts live only in memory and passwords are
/// compared as plain text, which is acceptable because it never ships to
/// release builds (see `MockApiInterceptor`).
class MockAuthBackend {
  /// Creates the backend with a seeded demo account.
  MockAuthBackend() {
    _accounts[demoEmail] = const _Account(
      id: 'user-0',
      name: 'Demo User',
      email: demoEmail,
      password: demoPassword,
    );
  }

  /// E-mail of the seeded demo account.
  static const String demoEmail = 'demo@starkshowcase.dev';

  /// Password of the seeded demo account (fixture, not a real secret).
  static const String demoPassword = 'Demo1234!';

  final Map<String, _Account> _accounts = {};
  final Map<String, String> _refreshOwners = {};
  int _counter = 0;

  /// Routes to pass to the mock interceptor.
  List<MockRoute> get routes => [
    MockRoute(method: 'POST', pattern: AuthEndpoints.login, handler: _login),
    MockRoute(
      method: 'POST',
      pattern: AuthEndpoints.register,
      handler: _register,
    ),
    MockRoute(
      method: 'POST',
      pattern: NetworkConstants.refreshPath,
      handler: _refresh,
    ),
  ];

  MockResponse _login(MockRequest request) {
    final body = _body(request);
    final account = _accounts[_text(body, 'email').toLowerCase()];
    if (account == null || account.password != _text(body, 'password')) {
      return const MockResponse(
        statusCode: 401,
        data: {'code': 'invalid_credentials'},
      );
    }
    return MockResponse(data: _session(account));
  }

  MockResponse _register(MockRequest request) {
    final body = _body(request);
    final name = _text(body, 'name');
    final email = _text(body, 'email').toLowerCase();
    final password = _text(body, 'password');
    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      return const MockResponse(
        statusCode: 422,
        data: {'code': 'validation_error'},
      );
    }
    if (_accounts.containsKey(email)) {
      return const MockResponse(statusCode: 409, data: {'code': 'email_taken'});
    }
    final phone = _text(body, 'phone');
    final account = _Account(
      id: 'user-${_accounts.length}',
      name: name,
      email: email,
      password: password,
      phone: phone.isEmpty ? null : phone,
    );
    _accounts[email] = account;
    return MockResponse(statusCode: 201, data: _session(account));
  }

  MockResponse _refresh(MockRequest request) {
    final email = _refreshOwners.remove(_text(_body(request), 'refreshToken'));
    final account = email == null ? null : _accounts[email];
    if (account == null) {
      return const MockResponse(
        statusCode: 401,
        data: {'code': 'invalid_refresh_token'},
      );
    }
    final session = _session(account);
    return MockResponse(
      data: {
        'accessToken': session['accessToken'],
        'refreshToken': session['refreshToken'],
      },
    );
  }

  /// Issues a new token pair (rotating refresh tokens) for [account].
  Map<String, Object?> _session(_Account account) {
    _counter++;
    final refresh = 'mock-refresh-$_counter';
    _refreshOwners[refresh] = account.email;
    return {
      'user': {
        'id': account.id,
        'name': account.name,
        'email': account.email,
        'phone': account.phone,
      },
      'accessToken': 'mock-access-$_counter',
      'refreshToken': refresh,
    };
  }

  Map<String, dynamic> _body(MockRequest request) {
    final data = request.data;
    return data is Map<String, dynamic> ? data : const {};
  }

  String _text(Map<String, dynamic> body, String key) {
    final value = body[key];
    return value is String ? value.trim() : '';
  }
}

class _Account {
  const _Account({
    required this.id,
    required this.name,
    required this.email,
    required this.password,
    this.phone,
  });

  final String id;
  final String name;
  final String email;
  final String password;
  final String? phone;
}
