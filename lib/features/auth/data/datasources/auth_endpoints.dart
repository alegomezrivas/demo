/// Paths of the authentication API.
abstract final class AuthEndpoints {
  /// `POST` credentials, returns user + tokens.
  static const String login = '/auth/login';

  /// `POST` new account, returns user + tokens.
  static const String register = '/auth/register';

  /// `POST` the refresh token to revoke the server-side session.
  static const String logout = '/auth/logout';
}
