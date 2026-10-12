import 'package:demo/core/services/session_service.dart';
import 'package:demo/core/usecases/use_case.dart';
import 'package:demo/features/auth/domain/usecases/get_current_user_use_case.dart';

/// Restores a stored session before the first screen is shown.
Future<void> restoreSession({
  required GetCurrentUserUseCase getCurrentUser,
  required SessionService session,
}) async {
  final result = await getCurrentUser(const NoParams());
  result.fold(
    (_) => session.markSignedOut(),
    (user) => user == null ? session.markSignedOut() : session.markSignedIn(),
  );
}
