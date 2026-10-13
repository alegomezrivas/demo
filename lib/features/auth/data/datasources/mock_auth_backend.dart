import 'dart:typed_data';

import 'package:demo/core/network/mock/mock_route.dart';
import 'package:demo/core/network/network_constants.dart';
import 'package:demo/features/auth/data/datasources/auth_endpoints.dart';
import 'package:demo/features/auth/domain/rules/auth_rules.dart';

/// In-memory fake of the authentication API for the mock Dio backend.
///
/// It is a development fixture: accounts live only in memory and passwords are
/// compared as plain text, which is acceptable because it never ships to
/// release builds (see `MockApiInterceptor`). It follows the same contract as
/// the real backend (`backend/docs/api-contract.md`): e-mail confirmation with
/// a code, usernames and profile pictures.
class MockAuthBackend {
  /// Creates the backend with a seeded demo account.
  MockAuthBackend() {
    _accounts[demoEmail] = const _Account(
      id: 'user-0',
      name: 'Demo User',
      email: demoEmail,
      username: demoUsername,
      password: demoPassword,
    );
  }

  /// E-mail of the seeded demo account.
  static const String demoEmail = 'demo@starkshowcase.dev';

  /// Username of the seeded demo account.
  static const String demoUsername = 'demo';

  /// Password of the seeded demo account (fixture, not a real secret).
  static const String demoPassword = 'Demo1234!';

  /// Code every e-mail accepts, like the real backend's demo code.
  static const String confirmationCode = '123456';

  /// Wrong guesses allowed before the code is discarded.
  static const int maxCodeAttempts = 5;

  final Map<String, _Account> _accounts = {};
  final Map<String, String> _refreshOwners = {};
  final Map<String, String> _accessOwners = {};
  final Map<String, int> _failedAttempts = {};
  final Map<String, String> _grants = {};
  final Map<String, Uint8List> _avatars = {};
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
      pattern: AuthEndpoints.signUpEmail,
      handler: _sendCode,
    ),
    MockRoute(
      method: 'POST',
      pattern: AuthEndpoints.signUpResend,
      handler: _sendCode,
    ),
    MockRoute(
      method: 'POST',
      pattern: AuthEndpoints.signUpVerify,
      handler: _verify,
    ),
    MockRoute(
      method: 'GET',
      pattern: AuthEndpoints.usernameAvailable,
      handler: _usernameAvailable,
    ),
    MockRoute(
      method: 'PUT',
      pattern: AuthEndpoints.avatar,
      handler: _putAvatar,
    ),
    MockRoute(
      method: 'POST',
      pattern: NetworkConstants.refreshPath,
      handler: _refresh,
    ),
    MockRoute(
      method: 'POST',
      pattern: AuthEndpoints.logout,
      handler: _logout,
    ),
  ];

  MockResponse _login(MockRequest request) {
    final body = _body(request);
    final account = _accounts[_text(body, 'email').toLowerCase()];
    if (account == null || account.password != _text(body, 'password')) {
      return _error(401, 'invalid_credentials');
    }
    return MockResponse(data: _session(account));
  }

  MockResponse _sendCode(MockRequest request) {
    final email = _text(_body(request), 'email').toLowerCase();
    if (!AuthRules.isValidEmail(email)) return _error(422, 'validation_error');
    if (_accounts.containsKey(email)) return _error(409, 'email_taken');
    _failedAttempts[email] = 0;
    return const MockResponse(statusCode: 204);
  }

  MockResponse _verify(MockRequest request) {
    final body = _body(request);
    final email = _text(body, 'email').toLowerCase();
    final code = _text(body, 'code');
    if (!AuthRules.isValidEmail(email) || !AuthRules.isValidCode(code)) {
      return _error(422, 'validation_error');
    }
    final failures = _failedAttempts[email];
    if (failures == null) return _error(422, 'invalid_code');
    if (code != confirmationCode) {
      _failedAttempts[email] = failures + 1;
      if (failures + 1 >= maxCodeAttempts) {
        _failedAttempts.remove(email);
        return _error(429, 'too_many_attempts');
      }
      return _error(422, 'invalid_code');
    }
    _failedAttempts.remove(email);
    _counter++;
    final token = 'mock-verification-$_counter';
    _grants[token] = email;
    return MockResponse(data: {'verificationToken': token});
  }

  MockResponse _usernameAvailable(MockRequest request) {
    final username = '${request.queryParameters['username'] ?? ''}'
        .trim()
        .toLowerCase();
    if (!AuthRules.isValidUsername(username)) {
      return _error(422, 'validation_error');
    }
    return MockResponse(data: {'available': !_isUsernameTaken(username)});
  }

  MockResponse _register(MockRequest request) {
    final body = _body(request);
    final name = _text(body, 'name');
    final username = _text(body, 'username').toLowerCase();
    final password = _text(body, 'password');
    final email = _grants[_text(body, 'verificationToken')];
    if (email == null) return _error(422, 'invalid_verification_token');
    if (name.isEmpty ||
        !AuthRules.isValidUsername(username) ||
        AuthRules.passwordProblems(password).isNotEmpty) {
      return _error(422, 'validation_error');
    }
    if (_accounts.containsKey(email)) return _error(409, 'email_taken');
    if (_isUsernameTaken(username)) return _error(409, 'username_taken');

    // Redeemed only after success, like the real backend.
    _grants.remove(_text(body, 'verificationToken'));
    final account = _Account(
      id: 'user-${_accounts.length}',
      name: name,
      email: email,
      username: username,
      password: password,
    );
    _accounts[email] = account;
    return MockResponse(statusCode: 201, data: _session(account));
  }

  MockResponse _putAvatar(MockRequest request) {
    final owner = _ownerOf(request);
    if (owner == null) return _error(401, 'unauthorized');
    final bytes = request.data;
    if (bytes is! List<int> || !_looksLikeJpeg(bytes)) {
      return _error(422, 'invalid_image');
    }
    _avatars[owner.id] = Uint8List.fromList(bytes);
    return const MockResponse(statusCode: 204);
  }

  MockResponse _refresh(MockRequest request) {
    final email = _refreshOwners.remove(_text(_body(request), 'refreshToken'));
    final account = email == null ? null : _accounts[email];
    if (account == null) return _error(401, 'invalid_refresh_token');
    final session = _session(account);
    return MockResponse(
      data: {
        'accessToken': session['accessToken'],
        'refreshToken': session['refreshToken'],
      },
    );
  }

  /// Revokes a refresh token. Like the real API it is idempotent: unknown or
  /// already revoked tokens still answer 204.
  MockResponse _logout(MockRequest request) {
    final token = _text(_body(request), 'refreshToken');
    if (token.isEmpty) return _error(422, 'validation_error');
    _refreshOwners.remove(token);
    return const MockResponse(statusCode: 204);
  }

  /// Issues a new token pair (rotating refresh tokens) for [account].
  Map<String, Object?> _session(_Account account) {
    _counter++;
    final refresh = 'mock-refresh-$_counter';
    final access = 'mock-access-$_counter';
    _refreshOwners[refresh] = account.email;
    _accessOwners[access] = account.email;
    return {
      'user': {
        'id': account.id,
        'name': account.name,
        'email': account.email,
        'username': account.username,
        'hasAvatar': _avatars.containsKey(account.id),
      },
      'accessToken': access,
      'refreshToken': refresh,
    };
  }

  _Account? _ownerOf(MockRequest request) {
    final header = request.headers['Authorization'];
    if (header is! String || !header.startsWith('Bearer ')) return null;
    final email = _accessOwners[header.substring('Bearer '.length)];
    return email == null ? null : _accounts[email];
  }

  bool _isUsernameTaken(String username) =>
      _accounts.values.any((account) => account.username == username);

  bool _looksLikeJpeg(List<int> bytes) =>
      bytes.length >= 5 &&
      bytes[0] == 0xFF &&
      bytes[1] == 0xD8 &&
      bytes[2] == 0xFF &&
      bytes[bytes.length - 2] == 0xFF &&
      bytes[bytes.length - 1] == 0xD9;

  MockResponse _error(int status, String code) =>
      MockResponse(statusCode: status, data: {'code': code});

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
    required this.username,
    required this.password,
  });

  final String id;
  final String name;
  final String email;
  final String username;
  final String password;
}
