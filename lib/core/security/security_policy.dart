/// Reaction to a compromised device (root / jailbreak / debugger attached).
enum SecurityPolicy {
  /// Show a warning but let the user continue.
  warn,

  /// Refuse to run the app.
  block;

  /// Parses [value] (case-insensitive); unknown values fall back to [warn].
  static SecurityPolicy parse(String value) {
    final normalized = value.trim().toLowerCase();
    return SecurityPolicy.values.firstWhere(
      (policy) => policy.name == normalized,
      orElse: () => SecurityPolicy.warn,
    );
  }
}
