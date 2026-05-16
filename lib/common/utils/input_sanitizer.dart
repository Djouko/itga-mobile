/// Utility class for sanitizing user inputs across the app.
/// Prevents XSS, injection attacks, and ensures clean data is sent to the backend.
class InputSanitizer {
  InputSanitizer._();

  /// Strips HTML tags to prevent XSS in rendered text.
  static String stripHtml(String input) {
    return input.replaceAll(RegExp(r'<[^>]*>'), '');
  }

  /// Removes null bytes and control characters (except newline/tab).
  static String removeControlChars(String input) {
    return input.replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]'), '');
  }

  /// Trims whitespace and collapses multiple spaces into one.
  static String normalizeWhitespace(String input) {
    return input.trim().replaceAll(RegExp(r' {2,}'), ' ');
  }

  /// Full sanitization pipeline for general text inputs (posts, comments, messages).
  static String sanitizeText(String input) {
    if (input.isEmpty) return input;
    var result = stripHtml(input);
    result = removeControlChars(result);
    result = normalizeWhitespace(result);
    return result;
  }

  /// Sanitize a username — only allow alphanumeric, underscores, and periods.
  static String sanitizeUsername(String input) {
    return input.replaceAll(RegExp(r'[^a-zA-Z0-9_.]'), '').toLowerCase();
  }

  /// Sanitize a search query — strip dangerous chars but keep spaces and basic punctuation.
  static String sanitizeSearch(String input) {
    if (input.isEmpty) return input;
    var result = stripHtml(input);
    result = removeControlChars(result);
    result = result.trim();
    // Limit length to prevent abuse
    if (result.length > 200) {
      result = result.substring(0, 200);
    }
    return result;
  }

  /// Validate and sanitize a URL — basic check to prevent javascript: and data: URIs.
  static String? sanitizeUrl(String? input) {
    if (input == null || input.isEmpty) return null;
    final trimmed = input.trim();
    final lower = trimmed.toLowerCase();
    if (lower.startsWith('javascript:') || lower.startsWith('data:') || lower.startsWith('vbscript:')) {
      return null;
    }
    return trimmed;
  }

  /// Limit input length to prevent extremely long strings from being sent.
  static String limitLength(String input, {int maxLength = 5000}) {
    if (input.length <= maxLength) return input;
    return input.substring(0, maxLength);
  }
}
