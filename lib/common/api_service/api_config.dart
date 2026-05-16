import 'package:untitled/common/managers/session_manager.dart';

const String apiClientKey = String.fromEnvironment(
  'ITGA_API_KEY',
  defaultValue: '',
);

const int uploadBytesPerMb = 1024 * 1024;

const Map<String, int> apiUploadLimitsMb = {
  'testupload': 10,
  'editProfile': 16,
  'uploadReel': 120,
  'profileVerification': 20,
  'addPost': 80,
  'createStory': 60,
  'uploadFile': 32,
  'createRoom': 12,
  'editRoom': 12,
  'Company/editProfile': 8,
  'Company/createPost': 80,
  'Application/applyToJob': 8,
};

Map<String, String> buildApiHeaders({
  Map<String, String>? extraHeaders,
  bool includeAuthorization = true,
}) {
  if (apiClientKey.trim().isEmpty) {
    throw StateError(
      'ITGA_API_KEY must be provided with --dart-define=ITGA_API_KEY=...',
    );
  }

  final headers = <String, String>{
    'Accept': 'application/json',
    'apikey': apiClientKey,
  };

  if (includeAuthorization) {
    final token = SessionManager.shared.getApiAuthToken();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
  }

  if (extraHeaders != null) {
    headers.addAll(extraHeaders);
  }

  return headers;
}

int? uploadLimitMbForUrl(String url) {
  final uri = Uri.tryParse(url);
  final path = (uri?.path ?? url).replaceAll(RegExp(r'^/+|/+$'), '');

  for (final entry in apiUploadLimitsMb.entries) {
    if (path == entry.key || path.endsWith('/${entry.key}')) {
      return entry.value;
    }
  }

  return null;
}

String? validateUploadContentLength({
  required String url,
  required Iterable<int> fileSizes,
}) {
  final limitMb = uploadLimitMbForUrl(url);
  if (limitMb == null) return null;

  final totalBytes = fileSizes.fold<int>(0, (total, size) => total + size);
  final limitBytes = limitMb * uploadBytesPerMb;

  if (totalBytes > limitBytes) {
    return 'File too large. Limit: $limitMb MB. Please compress it or choose a smaller file.';
  }

  return null;
}

Duration? parseRetryAfterHeader(String? retryAfterHeader) {
  if (retryAfterHeader == null) return null;
  final seconds = int.tryParse(retryAfterHeader.trim());
  if (seconds == null || seconds <= 0) return null;
  return Duration(seconds: seconds);
}
