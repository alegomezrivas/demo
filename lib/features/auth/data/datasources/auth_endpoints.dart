/// Paths of the authentication API.
abstract final class AuthEndpoints {
  /// `POST` credentials, returns user + tokens.
  static const String login = '/auth/login';

  /// `POST` the verification token and profile, returns user + tokens.
  static const String register = '/auth/register';

  /// `POST` the refresh token to revoke the server-side session.
  static const String logout = '/auth/logout';

  /// `POST` an e-mail to receive a confirmation code.
  static const String signUpEmail = '/auth/signup/email';

  /// `POST` an e-mail to receive the code again.
  static const String signUpResend = '/auth/signup/code/resend';

  /// `POST` e-mail + code, returns the verification token.
  static const String signUpVerify = '/auth/signup/verify';

  /// `GET ?username=` tells whether a username is free.
  static const String usernameAvailable = '/auth/username-available';

  /// `PUT` raw JPEG bytes (and `GET` them back) for the signed-in user.
  static const String avatar = '/users/me/avatar';
}
