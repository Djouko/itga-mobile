import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:untitled/common/api_service/api_config.dart';
import 'package:untitled/common/managers/logger.dart';
import 'package:untitled/models/status_message_model.dart';

import 'api_service.dart';

class NewApiService {
  static final shared = NewApiService();

  Map<String, String> get header => buildApiHeaders();

  Map<String, String> _redactedHeader() {
    return header.map((key, value) {
      final lower = key.toLowerCase();
      if (lower.contains('key') ||
          lower.contains('token') ||
          lower.contains('authorization')) {
        return MapEntry(key, value.isEmpty ? '' : '***');
      }
      return MapEntry(key, value);
    });
  }

  Future<T> call<T>({
    required String url,
    Map<String, dynamic>? param,
    CancelToken? cancelToken,
    T Function(Map<String, dynamic> json)? fromJson,
    int retryCount = 3,
  }) async {
    final client = http.Client();

    Map<String, dynamic> params = {};
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
    Loggers.info(
        "Headers: ${JsonEncoder.withIndent('  ').convert(_redactedHeader())}");
    Loggers.info(
        "Parameters: ${params.isEmpty ? "Empty" : JsonEncoder.withIndent('  ').convert(params)}");

    try {
      final response = await client
          .post(
            Uri.parse(url),
            headers: header,
            body: params,
          )
          .timeout(const Duration(seconds: 15));

      if (cancelToken?.isCancelled ?? false) {
        Loggers.warning("Request cancelled: $url");
        throw Exception('Request was cancelled');
      }

      if (_shouldRetryStatus(response.statusCode) && retryCount > 0) {
        final delay =
            _retryDelayFor(response.headers['retry-after'], retryCount);
        Loggers.warning(
          "HTTP ${response.statusCode}, retrying... (${retryCount} left, ${delay.inMilliseconds}ms)",
        );
        await Future.delayed(delay);
        return call(
          url: url,
          param: param,
          cancelToken: cancelToken,
          fromJson: fromJson,
          retryCount: retryCount - 1,
        );
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decodedResponse =
            jsonDecode(response.body) as Map<String, dynamic>;
        final prettyString =
            const JsonEncoder.withIndent('  ').convert(decodedResponse);
        Loggers.info(prettyString);

        final model = StatusMessageModel.fromJson(decodedResponse);
        if (model.status == false) {
          Loggers.error(model.message);
        }
        if (fromJson != null) {
          return fromJson(decodedResponse);
        }

        return decodedResponse as T;
      }

      final errorMessage = _buildHttpErrorMessage(
        response.statusCode,
        response.reasonPhrase,
        response.headers['retry-after'],
      );
      Loggers.error(errorMessage);
      throw Exception(errorMessage);
    } on HttpException {
      throw Exception('Could not connect to the server');
    } on FormatException catch (e) {
      Loggers.error("Invalid JSON format: ${e.source}");
      throw Exception("Invalid JSON format: ${e.message}");
    } on SocketException catch (e) {
      if (retryCount > 0) {
        Loggers.warning('Network issue, retrying... ($retryCount left)');
        await Future.delayed(Duration(milliseconds: 500 * (4 - retryCount)));
        return call(
          url: url,
          param: param,
          cancelToken: cancelToken,
          fromJson: fromJson,
          retryCount: retryCount - 1,
        );
      }
      Loggers.error("Network error after all retries: $e");
      rethrow;
    } on TimeoutException catch (_) {
      if (retryCount > 0) {
        Loggers.warning('Timeout, retrying... ($retryCount left)');
        await Future.delayed(Duration(milliseconds: 500 * (4 - retryCount)));
        return call(
          url: url,
          param: param,
          cancelToken: cancelToken,
          fromJson: fromJson,
          retryCount: retryCount - 1,
        );
      }
      throw Exception('Request timed out after retries');
    } on http.ClientException catch (e) {
      if (retryCount > 0) {
        Loggers.warning('Client issue, retrying... ($retryCount left)');
        await Future.delayed(Duration(milliseconds: 500 * (4 - retryCount)));
        return call(
          url: url,
          param: param,
          cancelToken: cancelToken,
          fromJson: fromJson,
          retryCount: retryCount - 1,
        );
      }
      Loggers.error("Client error after all retries: $e");
      rethrow;
    } on Exception catch (e) {
      Loggers.error("Unexpected error: $e");
      rethrow;
    } finally {
      client.close();
    }
  }

  Future<T> multiPartCallApi<T>({
    required String url,
    Map<String, dynamic>? param,
    required Map<String, List<XFile?>> filesMap,
    Function(double percentage)? onProgress,
    CancelToken? cancelToken,
    T Function(Map<String, dynamic> json)? fromJson,
    int retryCount = 3,
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
      final failedResponse = <String, dynamic>{
        'status': false,
        'message': uploadSizeError,
      };

      if (fromJson != null) {
        return fromJson(failedResponse);
      }

      return failedResponse as T;
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

    Loggers.info("URL: $url");
    Loggers.info(
        "Headers: ${JsonEncoder.withIndent('  ').convert(_redactedHeader())}");
    Loggers.info(
        "Parameters: ${params.isEmpty ? "Empty" : JsonEncoder.withIndent('  ').convert(params)}");

    try {
      final responseStream =
          await client.send(request).timeout(const Duration(minutes: 2));

      if (cancelToken?.isCancelled ?? false) {
        Loggers.warning("Request cancelled: $url");
        throw Exception('Request was cancelled');
      }

      final responseStr = await responseStream.stream.bytesToString();

      if (_shouldRetryStatus(responseStream.statusCode) && retryCount > 0) {
        final delay =
            _retryDelayFor(responseStream.headers['retry-after'], retryCount);
        Loggers.warning(
          "HTTP ${responseStream.statusCode}, retrying upload... (${retryCount} left, ${delay.inMilliseconds}ms)",
        );
        await Future.delayed(delay);
        return multiPartCallApi(
          url: url,
          param: param,
          filesMap: filesMap,
          onProgress: onProgress,
          cancelToken: cancelToken,
          fromJson: fromJson,
          retryCount: retryCount - 1,
        );
      }

      if (responseStream.statusCode >= 200 && responseStream.statusCode < 300) {
        final decodedResponse = jsonDecode(responseStr) as Map<String, dynamic>;
        final prettyString =
            const JsonEncoder.withIndent('  ').convert(decodedResponse);
        Loggers.info(prettyString);

        if (fromJson != null) {
          return fromJson(decodedResponse);
        }

        return decodedResponse as T;
      }

      final errorMessage = _buildHttpErrorMessage(
        responseStream.statusCode,
        responseStream.reasonPhrase,
        responseStream.headers['retry-after'],
      );
      Loggers.error(errorMessage);
      throw Exception(errorMessage);
    } on HttpException {
      throw Exception('Could not connect to the server');
    } on FormatException catch (e) {
      Loggers.error("Invalid JSON format: ${e.message}");
      throw Exception("Invalid JSON format: ${e.message}");
    } on SocketException catch (e) {
      if (retryCount > 0) {
        Loggers.warning('Network issue, retrying upload... ($retryCount left)');
        await Future.delayed(Duration(milliseconds: 500 * (4 - retryCount)));
        return multiPartCallApi(
          url: url,
          param: param,
          filesMap: filesMap,
          onProgress: onProgress,
          cancelToken: cancelToken,
          fromJson: fromJson,
          retryCount: retryCount - 1,
        );
      }
      Loggers.error("Upload network error after all retries: $e");
      rethrow;
    } on TimeoutException catch (_) {
      if (retryCount > 0) {
        Loggers.warning('Timeout, retrying upload... ($retryCount left)');
        await Future.delayed(Duration(milliseconds: 500 * (4 - retryCount)));
        return multiPartCallApi(
          url: url,
          param: param,
          filesMap: filesMap,
          onProgress: onProgress,
          cancelToken: cancelToken,
          fromJson: fromJson,
          retryCount: retryCount - 1,
        );
      }
      throw Exception('Request timed out after retries');
    } on http.ClientException catch (e) {
      if (retryCount > 0) {
        Loggers.warning('Client issue, retrying upload... ($retryCount left)');
        await Future.delayed(Duration(milliseconds: 500 * (4 - retryCount)));
        return multiPartCallApi(
          url: url,
          param: param,
          filesMap: filesMap,
          onProgress: onProgress,
          cancelToken: cancelToken,
          fromJson: fromJson,
          retryCount: retryCount - 1,
        );
      }
      Loggers.error("Upload client error after all retries: $e");
      rethrow;
    } on Exception catch (e) {
      Loggers.error("Unexpected error: $e");
      rethrow;
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
    return Duration(milliseconds: 500 * (4 - retryCount));
  }

  String _buildHttpErrorMessage(
    int statusCode,
    String? reasonPhrase,
    String? retryAfterHeader,
  ) {
    if (statusCode == 401) {
      return 'Unauthorized. Please sign in again.';
    }
    if (statusCode == 403) {
      return 'Forbidden.';
    }
    if (statusCode == 404) {
      return 'URL not found. Please check baseURL in const.dart file';
    }
    if (statusCode == 413) {
      return 'File too large. Please compress it or choose a smaller file.';
    }
    if (statusCode == 429) {
      final retryAfter = parseRetryAfterHeader(retryAfterHeader);
      if (retryAfter != null) {
        return 'Rate limit exceeded. Retry in ${retryAfter.inSeconds} second(s).';
      }
      return 'Rate limit exceeded. Please try again later.';
    }
    if (statusCode >= 500) {
      return 'Server error ($statusCode). Please try again.';
    }
    return 'HTTP Error: $statusCode${reasonPhrase != null ? ' - $reasonPhrase' : ''}';
  }
}
