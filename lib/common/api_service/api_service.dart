import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:untitled/common/api_service/api_config.dart';
import 'package:untitled/common/managers/logger.dart';

class CancelToken {
  bool _isCancelled = false;

  bool get isCancelled => _isCancelled;

  void cancel() {
    _isCancelled = true;
  }
}

class ApiService {
  static final shared = ApiService();

  Map<String, String> get header => buildApiHeaders();

  Future<void> call({
    required String url,
    Map<String, dynamic>? param,
    CancelToken? cancelToken,
    int retryCount = 5,
    required Function(Map<String, dynamic> response) completion,
    Function()? onError,
  }) async {
    final client = http.Client();

    Map<String, String> params = {};
    param?.removeWhere(
      (key, value) => value == null,
    );

    param?.forEach((key, value) {
      if (value is List) {
        for (int i = 0; i < value.length; i++) {
          params['$key[$i]'] = jsonEncode(value[i]);
        }
      } else {
        params[key] = "$value";
      }
    });

    Loggers.info("URL: $url");
    // Loggers.info("Parameters: ${params.isEmpty ? "Empty" : JsonEncoder.withIndent('  ').convert(params)}");

    try {
      final response = await client
          .post(
            Uri.parse(url),
            headers: header,
            body: params,
          )
          .timeout(const Duration(seconds: 15));

      if (cancelToken?.isCancelled ?? false) {
        throw Exception('Request was cancelled');
      }

      if (_shouldRetryStatus(response.statusCode) && retryCount > 0) {
        final delay = _retryDelayFor(response.headers['retry-after'], retryCount);
        Loggers.warning("HTTP ${response.statusCode}, retrying in ${delay.inMilliseconds}ms... ($retryCount left)");
        await Future.delayed(delay);
        return call(
          url: url,
          param: param,
          cancelToken: cancelToken,
          retryCount: retryCount - 1,
          completion: completion,
          onError: onError,
        );
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decodedResponse = jsonDecode(response.body) as Map<String, dynamic>;
        completion(decodedResponse);
        return;
      }

      throw Exception(_buildHttpErrorMessage(response.statusCode, response.reasonPhrase, response.headers['retry-after']));
    } on SocketException catch (e) {
      if (retryCount > 0) {
        Loggers.warning("Network issue, retrying... ($retryCount left)");
        await Future.delayed(Duration(milliseconds: 500 * (6 - retryCount)));
        return call(
          url: url,
          param: param,
          cancelToken: cancelToken,
          retryCount: retryCount - 1,
          completion: completion,
          onError: onError,
        );
      }
      Loggers.error("Network error after all retries: $e");
      onError?.call();
      rethrow;
    } on TimeoutException catch (e) {
      if (retryCount > 0) {
        Loggers.warning("Timeout, retrying... ($retryCount left)");
        await Future.delayed(Duration(milliseconds: 500 * (6 - retryCount)));
        return call(
          url: url,
          param: param,
          cancelToken: cancelToken,
          retryCount: retryCount - 1,
          completion: completion,
          onError: onError,
        );
      }
      Loggers.error("Timeout after all retries: $e");
      onError?.call();
      rethrow;
    } on http.ClientException catch (e) {
      if (retryCount > 0) {
        Loggers.warning("Client issue, retrying... ($retryCount left)");
        await Future.delayed(Duration(milliseconds: 500 * (6 - retryCount)));
        return call(
          url: url,
          param: param,
          cancelToken: cancelToken,
          retryCount: retryCount - 1,
          completion: completion,
          onError: onError,
        );
      }
      Loggers.error("Client error after all retries: $e");
      onError?.call();
      rethrow;
    } catch (e) {
      Loggers.error("Network error after all retries: $e");
      onError?.call();
      rethrow;
    } finally {
      client.close();
    }
  }

  Future<void> multiPartCallApi({
    required String url,
    Map<String, dynamic>? param,
    required Map<String, List<XFile?>> filesMap,
    Function(double percentage)? onProgress,
    CancelToken? cancelToken,
    int retryCount = 5,
    required Function(Map<String, dynamic> response) completion,
    Function()? onError,
  }) async {
    final client = http.Client();

    Map<String, String> params = {};
    param?.removeWhere(
      (key, value) => value == null,
    );
    param?.forEach((key, value) {
      if (value is List) {
        for (int i = 0; i < value.length; i++) {
          params['$key[$i]'] = jsonEncode(value[i]);
        }
      } else {
        params[key] = "$value";
      }
    });

    final uploadSizeError = validateUploadContentLength(
      url: url,
      fileSizes: _multipartFileSizes(filesMap),
    );
    if (uploadSizeError != null) {
      Loggers.warning(uploadSizeError);
      completion({
        'status': false,
        'message': uploadSizeError,
      });
      return;
    }

    final request = MultipartRequest(
      'POST',
      Uri.parse(url),
      onProgress: (bytes, totalBytes) {
        if (onProgress != null) {
          onProgress(bytes / totalBytes);
        }
      },
    );

    request.fields.addAll(params);
    request.headers.addAll(header);

    filesMap.forEach((keyName, files) {
      for (var xFile in files) {
        if (xFile != null && xFile.path.isNotEmpty) {
          final file = File(xFile.path);
          final multipartFile = http.MultipartFile(
            keyName,
            file.readAsBytes().asStream(),
            file.lengthSync(),
            filename: xFile.name,
          );
          request.files.add(multipartFile);
        }
      }
    });

    try {
      final responseStream = await client.send(request).timeout(const Duration(minutes: 2));

      if (cancelToken?.isCancelled ?? false) {
        throw Exception('Request was cancelled');
      }

      final responseStr = await responseStream.stream.bytesToString();

      if (_shouldRetryStatus(responseStream.statusCode) && retryCount > 0) {
        final delay = _retryDelayFor(responseStream.headers['retry-after'], retryCount);
        Loggers.warning("HTTP ${responseStream.statusCode}, retrying upload in ${delay.inMilliseconds}ms... ($retryCount left)");
        await Future.delayed(delay);
        return multiPartCallApi(
          url: url,
          param: param,
          filesMap: filesMap,
          onProgress: onProgress,
          cancelToken: cancelToken,
          retryCount: retryCount - 1,
          completion: completion,
          onError: onError,
        );
      }

      if (responseStream.statusCode >= 200 && responseStream.statusCode < 300) {
        final decodedResponse = jsonDecode(responseStr) as Map<String, dynamic>;
        completion(decodedResponse);
        return;
      }

      throw Exception(_buildHttpErrorMessage(responseStream.statusCode, responseStream.reasonPhrase, responseStream.headers['retry-after']));
    } on SocketException catch (e) {
      if (retryCount > 0) {
        Loggers.warning("Network issue, retrying upload... ($retryCount left)");
        await Future.delayed(Duration(milliseconds: 500 * (6 - retryCount)));
        return multiPartCallApi(
          url: url,
          param: param,
          filesMap: filesMap,
          onProgress: onProgress,
          cancelToken: cancelToken,
          retryCount: retryCount - 1,
          completion: completion,
          onError: onError,
        );
      }
      Loggers.error("Upload error after all retries: $e");
      onError?.call();
    } on TimeoutException catch (e) {
      if (retryCount > 0) {
        Loggers.warning("Timeout, retrying upload... ($retryCount left)");
        await Future.delayed(Duration(milliseconds: 500 * (6 - retryCount)));
        return multiPartCallApi(
          url: url,
          param: param,
          filesMap: filesMap,
          onProgress: onProgress,
          cancelToken: cancelToken,
          retryCount: retryCount - 1,
          completion: completion,
          onError: onError,
        );
      }
      Loggers.error("Upload timeout after all retries: $e");
      onError?.call();
    } on http.ClientException catch (e) {
      if (retryCount > 0) {
        Loggers.warning("Client issue, retrying upload... ($retryCount left)");
        await Future.delayed(Duration(milliseconds: 500 * (6 - retryCount)));
        return multiPartCallApi(
          url: url,
          param: param,
          filesMap: filesMap,
          onProgress: onProgress,
          cancelToken: cancelToken,
          retryCount: retryCount - 1,
          completion: completion,
          onError: onError,
        );
      }
      Loggers.error("Upload client error after all retries: $e");
      onError?.call();
    } catch (e) {
      Loggers.error("Upload error: $e");
      onError?.call();
    } finally {
      client.close();
    }
  }

  Iterable<int> _multipartFileSizes(Map<String, List<XFile?>> filesMap) sync* {
    for (final files in filesMap.values) {
      for (final xFile in files) {
        if (xFile != null && xFile.path.isNotEmpty) {
          final file = File(xFile.path);
          if (file.existsSync()) {
            yield file.lengthSync();
          }
        }
      }
    }
  }

  bool _shouldRetryStatus(int statusCode) {
    return statusCode == 429 || statusCode >= 500;
  }

  Duration _retryDelayFor(String? retryAfterHeader, int retryCount) {
    final retryAfter = parseRetryAfterHeader(retryAfterHeader);
    if (retryAfter != null) {
      return retryAfter;
    }
    return Duration(milliseconds: 500 * (6 - retryCount));
  }

  String _buildHttpErrorMessage(
    int statusCode,
    String? reasonPhrase,
    String? retryAfterHeader,
  ) {
    if (statusCode == 401) {
      return "Unauthorized. Please sign in again.";
    }
    if (statusCode == 403) {
      return "Forbidden.";
    }
    if (statusCode == 404) {
      return "Resource not found.";
    }
    if (statusCode == 413) {
      return "File too large. Please compress it or choose a smaller file.";
    }
    if (statusCode == 429) {
      final retryAfter = parseRetryAfterHeader(retryAfterHeader);
      if (retryAfter != null) {
        return "Rate limit exceeded. Retry in ${retryAfter.inSeconds} second(s).";
      }
      return "Rate limit exceeded. Please try again later.";
    }
    if (statusCode >= 500) {
      return "Server error ($statusCode). Please try again.";
    }
    return "HTTP Error: $statusCode${reasonPhrase != null ? ' - $reasonPhrase' : ''}";
  }

  Future<String?> downloadFile(String url, String fileName) async {
    try {
      var response =
          await http.get(Uri.parse(url)).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        Directory? directory = await (Platform.isAndroid
            ? getExternalStorageDirectory()
            : getApplicationDocumentsDirectory());
        String filePath = '${directory!.path}/$fileName';
        File file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);
        return filePath;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }
}

class MultipartRequest extends http.MultipartRequest {
  MultipartRequest(
    super.method,
    super.url, {
    this.onProgress,
  });

  final void Function(int bytes, int totalBytes)? onProgress;

  @override
  http.ByteStream finalize() {
    final byteStream = super.finalize();
    final total = contentLength;
    int bytes = 0;

    final transformer = StreamTransformer<List<int>, List<int>>.fromHandlers(
      handleData: (data, sink) {
        bytes += data.length;
        if (onProgress != null) {
          onProgress!(bytes, total);
        }
        sink.add(data);
      },
    );

    return http.ByteStream(byteStream.transform(transformer));
  }
}
