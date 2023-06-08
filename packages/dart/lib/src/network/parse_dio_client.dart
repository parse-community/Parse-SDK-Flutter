import 'package:dio/dio.dart' as dio;
import 'package:parse_server_sdk/parse_server_sdk.dart';

import 'dio_adapter_io.dart' if (dart.library.js) 'dio_adapter_js.dart';

class ParseDioClient extends ParseClient {
  // securityContext is SecurityContext
  ParseDioClient({bool sendSessionId = false, dynamic securityContext}) {
    _client = _ParseDioClient(
      sendSessionId: sendSessionId,
      securityContext: securityContext,
    );
  }

  late _ParseDioClient _client;

  @override
  Future<ParseNetworkResponse> get(
    String path, {
    ParseNetworkOptions? options,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      final dio.Response<String> dioResponse = await _client.get<String>(
        path,
        options: _Options(headers: options?.headers),
      );

      return ParseNetworkResponse(
        data: dioResponse.data!,
        statusCode: dioResponse.statusCode!,
      );
    } on dio.DioException catch (error) {
      return ParseNetworkResponse(
        data: error.response?.data ?? _fallbackErrorData,
        statusCode: error.response?.statusCode ?? ParseError.otherCause,
      );
    }
  }

  @override
  Future<ParseNetworkByteResponse> getBytes(
    String path, {
    ParseNetworkOptions? options,
    ProgressCallback? onReceiveProgress,
    dynamic cancelToken,
  }) async {
    try {
      final dio.Response<List<int>> dioResponse = await _client.get<List<int>>(
        path,
        cancelToken: cancelToken,
        onReceiveProgress: onReceiveProgress,
        options: _Options(
            headers: options?.headers, responseType: dio.ResponseType.bytes),
      );
      return ParseNetworkByteResponse(
        bytes: dioResponse.data,
        statusCode: dioResponse.statusCode!,
      );
    } on dio.DioException catch (error) {
      if (error.response != null) {
        return ParseNetworkByteResponse(
          data: error.response?.data ?? _fallbackErrorData,
          statusCode: error.response?.statusCode ?? ParseError.otherCause,
        );
      } else {
        return _getOtherCaseErrorForParseNetworkResponse(
            error.error.toString());
      }
    }
  }

  @override
  Future<ParseNetworkResponse> put(String path,
      {String? data, ParseNetworkOptions? options}) async {
    try {
      final dio.Response<String> dioResponse = await _client.put<String>(
        path,
        data: data,
        options: _Options(headers: options?.headers),
      );

      return ParseNetworkResponse(
        data: dioResponse.data!,
        statusCode: dioResponse.statusCode!,
      );
    } on dio.DioException catch (error) {
      return ParseNetworkResponse(
        data: error.response?.data ?? _fallbackErrorData,
        statusCode: error.response?.statusCode ?? ParseError.otherCause,
      );
    }
  }

  @override
  Future<ParseNetworkResponse> post(String path,
      {String? data, ParseNetworkOptions? options}) async {
    try {
      final dio.Response<String> dioResponse = await _client.post<String>(
        path,
        data: data,
        options: _Options(headers: options?.headers),
      );

      return ParseNetworkResponse(
        data: dioResponse.data!,
        statusCode: dioResponse.statusCode!,
      );
    } on dio.DioException catch (error) {
      return ParseNetworkResponse(
        data: error.response?.data ?? _fallbackErrorData,
        statusCode: error.response?.statusCode ?? ParseError.otherCause,
      );
    }
  }

  @override
  Future<ParseNetworkResponse> postBytes(String path,
      {Stream<List<int>>? data,
      ParseNetworkOptions? options,
      ProgressCallback? onSendProgress,
      dynamic cancelToken}) async {
    try {
      final dio.Response<String> dioResponse = await _client.post<String>(
        path,
        data: data,
        cancelToken: cancelToken,
        options: _Options(headers: options?.headers),
        onSendProgress: onSendProgress,
      );

      return ParseNetworkResponse(
        data: dioResponse.data!,
        statusCode: dioResponse.statusCode!,
      );
    } on dio.DioException catch (error) {
      if (error.response != null) {
        return ParseNetworkResponse(
          data: error.response?.data ?? _fallbackErrorData,
          statusCode: error.response?.statusCode ?? ParseError.otherCause,
        );
      } else {
        return _getOtherCaseErrorForParseNetworkResponse(
            error.error.toString());
      }
    }
  }

  _getOtherCaseErrorForParseNetworkResponse(String error) {
    return ParseNetworkResponse(
        data: "{\"code\":${ParseError.otherCause},\"error\":\"$error\"}",
        statusCode: ParseError.otherCause);
  }

  @override
  Future<ParseNetworkResponse> delete(String path,
      {ParseNetworkOptions? options}) async {
    try {
      final dio.Response<String> dioResponse = await _client.delete<String>(
        path,
        options: _Options(headers: options?.headers),
      );

      return ParseNetworkResponse(
        data: dioResponse.data!,
        statusCode: dioResponse.statusCode!,
      );
    } on dio.DioException catch (error) {
      return ParseNetworkResponse(
        data: error.response?.data ?? _fallbackErrorData,
        statusCode: error.response?.statusCode ?? ParseError.otherCause,
      );
    }
  }

  String get _fallbackErrorData => '{"$keyError":"NetworkError"}';
}

/// Creates a custom version of HTTP Client that has Parse Data Preset
class _ParseDioClient with dio.DioMixin implements dio.Dio {
  _ParseDioClient({bool sendSessionId = false, dynamic securityContext})
      : _sendSessionId = sendSessionId {
    options = dio.BaseOptions();
    httpClientAdapter = createHttpClientAdapter(securityContext);
  }

  final bool _sendSessionId;
  final String _userAgent = '$keyLibraryName $keySdkVersion';
  ParseCoreData parseCoreData = ParseCoreData();
  Map<String, String>? additionalHeaders;

  /// Overrides the call method for HTTP Client and adds custom headers
  @override
  Future<dio.Response<T>> request<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    dio.CancelToken? cancelToken,
    dio.Options? options,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) {
    options ??= dio.Options();
    options.headers ??= <String, dynamic>{};
    if (!identical(0, 0.0)) {
      options.headers![keyHeaderUserAgent] = _userAgent;
    }
    options.headers![keyHeaderApplicationId] = parseCoreData.applicationId;
    if (_sendSessionId &&
        parseCoreData.sessionId != null &&
        options.headers![keyHeaderSessionToken] == null) {
      options.headers![keyHeaderSessionToken] = parseCoreData.sessionId;
    }

    if (parseCoreData.clientKey != null) {
      options.headers![keyHeaderClientKey] = parseCoreData.clientKey;
    }
    if (parseCoreData.masterKey != null) {
      options.headers![keyHeaderMasterKey] = parseCoreData.masterKey;
    }

    /// If developer wants to add custom headers, extend this class and add headers needed.
    if (additionalHeaders != null && additionalHeaders!.isNotEmpty) {
      additionalHeaders!.forEach(
          (String key, String value) => options!.headers![key] = value);
    }

    if (parseCoreData.debug) {
      _logCUrl(options, data, path);
    }

    return super.request(
      path,
      data: data,
      queryParameters: queryParameters,
      cancelToken: cancelToken,
      options: options,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );
  }

  void _logCUrl(dio.Options options, dynamic data, String url) {
    String curlCmd = 'curl';
    curlCmd += ' -X ${options.method!}';
    bool compressed = false;
    options.headers!.forEach((String name, dynamic value) {
      if (name.toLowerCase() == 'accept-encoding' &&
          value?.toString().toLowerCase() == 'gzip') {
        compressed = true;
      }
      curlCmd += ' -H \'$name: $value\'';
    });

    //TODO: log request
    // if (options.method == 'POST' || options.method == 'PUT') {
    //   if (request is Request) {
    //     final String body = latin1.decode(request.bodyBytes);
    //     curlCmd += ' -d \'$body\'';
    //   }
    // }

    curlCmd += (compressed ? ' --compressed ' : ' ') + url;
    curlCmd += '\n\n ${Uri.decodeFull(url)}';
    print('╭-- Parse Request');
    print(curlCmd);
    print('╰--');
  }
}

class _Options extends dio.Options {
  _Options({
    String? method,
    Duration? sendTimeout,
    Duration? receiveTimeout,
    Map<String, dynamic>? extra,
    Map<String, dynamic>? headers,
    dio.ResponseType? responseType,
    String? contentType,
    dio.ValidateStatus? validateStatus,
    bool? receiveDataWhenStatusError,
    bool? followRedirects,
    int? maxRedirects,
    dio.RequestEncoder? requestEncoder,
    dio.ResponseDecoder? responseDecoder,
  }) : super(
          method: method,
          sendTimeout: sendTimeout,
          receiveTimeout: receiveTimeout,
          extra: extra,
          headers: headers,
          responseType: responseType,
          contentType: contentType ??
              (headers ?? <String, dynamic>{})[dio.Headers.contentTypeHeader],
          validateStatus: validateStatus,
          receiveDataWhenStatusError: receiveDataWhenStatusError,
          followRedirects: followRedirects,
          maxRedirects: maxRedirects,
          requestEncoder: requestEncoder,
          responseDecoder: responseDecoder,
        );
}
