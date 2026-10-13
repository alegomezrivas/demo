import 'package:demo/core/utils/validators/validation_keys.dart';
import 'package:demo/l10n/app_localizations.dart';
import 'package:reactive_forms/reactive_forms.dart';

/// Localized validation messages shared by every form.
abstract final class ValidationMessages {
  /// Builds the `validationMessages` map for `ReactiveTextField` and friends.
  static Map<String, ValidationMessageFunction> of(AppLocalizations l10n) {
    return {
      ValidationKeys.required: (_) => l10n.validationRequired,
      ValidationKeys.email: (_) => l10n.validationEmail,
      ValidationKeys.strongPassword: (_) => l10n.validationStrongPassword,
      ValidationKeys.minLength: (error) =>
          l10n.validationMinLength(_requiredLength(error)),
      ValidationKeys.maxLength: (error) =>
          l10n.validationMaxLength(_requiredLength(error)),
      ValidationKeys.mustMatch: (_) => l10n.validationMustMatch,
    };
  }

  static int _requiredLength(Object error) {
    if (error is Map<String, dynamic>) {
      final length = error['requiredLength'];
      if (length is int) return length;
    }
    return 0;
  }
}
