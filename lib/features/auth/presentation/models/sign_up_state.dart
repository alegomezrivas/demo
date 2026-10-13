import 'package:demo/core/error/failures.dart';
import 'package:demo/features/auth/domain/entities/user.dart';
import 'package:demo/features/auth/presentation/models/username_status.dart';
import 'package:meta/meta.dart';

/// Everything the sign-up steps share, except the text being typed (which
/// lives in the step forms). Immutable: the ViewModel swaps it on each change.
@immutable
class SignUpState {
  /// Creates the state; the defaults describe a flow that has not started.
  const SignUpState({
    this.email = '',
    this.verificationToken,
    this.user,
    this.usernameStatus = UsernameStatus.idle,
    this.failure,
  });

  /// E-mail whose code was sent (normalized as typed, trimmed).
  final String email;

  /// Proof of the confirmed e-mail; null until the code is accepted.
  final String? verificationToken;

  /// The created account; null until the terms are accepted.
  final User? user;

  /// Outcome of the latest username check.
  final UsernameStatus usernameStatus;

  /// Last failure of the current step, if any.
  final Failure? failure;

  /// Whether the e-mail was confirmed.
  bool get isEmailVerified => verificationToken != null;

  /// Whether the account already exists.
  bool get hasAccount => user != null;

  /// Copy with the given fields replaced.
  ///
  /// Nullable fields have a `clear…` flag because `null` means "keep".
  SignUpState copyWith({
    String? email,
    String? verificationToken,
    User? user,
    UsernameStatus? usernameStatus,
    Failure? failure,
    bool clearVerificationToken = false,
    bool clearFailure = false,
  }) {
    return SignUpState(
      email: email ?? this.email,
      verificationToken: clearVerificationToken
          ? null
          : (verificationToken ?? this.verificationToken),
      user: user ?? this.user,
      usernameStatus: usernameStatus ?? this.usernameStatus,
      failure: clearFailure ? null : (failure ?? this.failure),
    );
  }
}
