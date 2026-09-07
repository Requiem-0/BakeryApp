/// Reusable form input validators for the app.
class Validators {
  Validators._();

  /// Regex matching valid Nepal mobile numbers:
  /// - Optional +977 or 977 country code prefix (with optional space/dash)
  /// - Followed by 10 digits starting with 98, 97, or 96 (NTC, Ncell, SmartCell)
  static final RegExp nepalPhoneRegex = RegExp(r'^(?:\+?977[- ]?)?(9[678]\d{8})$');

  /// Normalizes a phone string by removing whitespace, hyphens, and leading +977 / 977 country code,
  /// returning a clean 10-digit phone string if valid, or the trimmed raw string.
  static String normalizePhone(String raw) {
    final cleaned = raw.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    final match = nepalPhoneRegex.firstMatch(cleaned);
    if (match != null && match.group(1) != null) {
      return match.group(1)!;
    }
    return cleaned;
  }

  /// Validates a Nepal phone number.
  /// Returns null if valid, or an error string if invalid.
  static String? validateNepalPhone(String? value, {bool isRequired = true}) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      if (isRequired) {
        return 'Please enter your phone number';
      }
      return null;
    }

    final cleaned = trimmed.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (!nepalPhoneRegex.hasMatch(cleaned)) {
      return 'Enter a 10-digit number starting with 98, 97, or 96';
    }

    return null;
  }

  /// Validates an email address.
  static String? validateEmail(String? value, {bool isRequired = true}) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      if (isRequired) {
        return 'Please enter your email address';
      }
      return null;
    }
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(trimmed)) {
      return 'Please enter a valid email address';
    }
    return null;
  }
}
