import 'dart:io';

import 'package:dio/dio.dart' as dio;
import 'package:parse_server_sdk/parse_server_sdk.dart';

import 'http_client_adapter.dart';

class ParseDioClient extends ParseClient {
  _ParseDioClient _client;

  ParseDioClient(
      {bool sendSessionId = false, SecurityContext securityContext}) {
    _client = _ParseDioClient(
      sendSessionId: sendSessionId,
      securityContext: securityContext,
    );
  }

  @override
  Future<ParseNetworkResponse<T>> get<T>(
    String path, {
    Map<String, dynamic> queryParameters,
    ParseNetworkOptions options,
    ProgressCallback onReceiveProgress,
  }) async {
    try {
      final dio.Response<T> dioResponse = await _client.get<T>(
        path,
        queryParameters: queryParameters,
        options: _Options(
            responseType: _toDioResponseType(options.responseType),
            headers: options.headers),
      );
      return ParseNetworkResponse<T>(data: dioResponse.data);
    } on dio.DioError catch (error) {
      return _handleDioError<T>(error);
    }
  }

  dio.ResponseType _toDioResponseType(ParseNetworkResponseType responseType) {
    switch (responseType) {
      case ParseNetworkResponseType.json:
        return dio.ResponseType.json;
      case ParseNetworkResponseType.stream:
        return dio.ResponseType.stream;
      case ParseNetworkResponseType.plain:
        return dio.ResponseType.plain;
      case ParseNetworkResponseType.bytes:
        return dio.ResponseType.bytes;
    }
    return null;
  }

  @override
  Future<ParseNetworkResponse<T>> delete<T>(
    String path, {
    Map<String, dynamic> queryParameters,
    ParseNetworkOptions options,
  }) async {
    try {
      final dio.Response<T> dioResponse = await _client.delete<T>(
        path,
        queryParameters: queryParameters,
        options: _Options(
            responseType: _toDioResponseType(options.responseType),
            headers: options.headers),
      );
      return ParseNetworkResponse<T>(data: dioResponse.data);
    } on dio.DioError catch (error) {
      return _handleDioError<T>(error);
    }
  }

  @override
  Future<ParseNetworkResponse<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic> queryParameters,
    ParseNetworkOptions options,
    ProgressCallback onReceiveProgress,
    ProgressCallback onSendProgress,
  }) async {
    try {
      final dio.Response<T> dioResponse = await _client.post<T>(
        path,
        queryParameters: queryParameters,
        options: _Options(
            responseType: _toDioResponseType(options.responseType),
            headers: options.headers),
        data: data,
        onReceiveProgress: onReceiveProgress,
        onSendProgress: onSendProgress,
      );
      return ParseNetworkResponse<T>(data: dioResponse.data);
    } on dio.DioError catch (error) {
      return _handleDioError<T>(error);
    }
  }

  @override
  Future<ParseNetworkResponse<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic> queryParameters,
    ParseNetworkOptions options,
    ProgressCallback onReceiveProgress,
  }) async {
    try {
      final dio.Response<T> dioResponse = await _client.put<T>(
        path,
        queryParameters: queryParameters,
        options: _Options(
            responseType: _toDioResponseType(options.responseType),
            headers: options.headers),
        data: data,
        onReceiveProgress: onReceiveProgress,
      );
      return ParseNetworkResponse<T>(data: dioResponse.data);
    } on dio.DioError catch (error) {
      return _handleDioError<T>(error);
    }
  }

  ParseNetworkResponse<T> _handleDioError<T>(dio.DioError error) {
    return ParseNetworkResponse<T>(data: error.response?.data);
  }
}

/// Creates a custom version of HTTP Client that has Parse Data Preset
class _ParseDioClient with dio.DioMixin implements dio.Dio {
  _ParseDioClient({bool sendSessionId = false, SecurityContext securityContext})
      : _sendSessionId = sendSessionId {
    options = dio.BaseOptions();
    httpClientAdapter = createHttpClientAdapter(securityContext);
  }

  final bool _sendSessionId;
  final String _userAgent = '$keyLibraryName $keySdkVersion';
  ParseCoreData data = ParseCoreData();
  Map<String, String> additionalHeaders;

  /// Overrides the call method for HTTP Client and adds custom headers
  @override
  Future<dio.Response<T>> request<T>(
    String path, {
    dynamic data,
    Map<String, dynamic> queryParameters,
    dio.CancelToken cancelToken,
    dio.Options options,
    ProgressCallback onSendProgress,
    ProgressCallback onReceiveProgress,
  }) {
    options ??= dio.Options();
    if (!identical(0, 0.0)) {
      options.headers[keyHeaderUserAgent] = _userAgent;
    }
    options.headers[keyHeaderApplicationId] = this.data.applicationId;
    if ((_sendSessionId == true) &&
        (this.data.sessionId != null) &&
        (options.headers[keyHeaderSessionToken] == null))
      options.headers[keyHeaderSessionToken] = this.data.sessionId;

    if (this.data.clientKey != null)
      options.headers[keyHeaderClientKey] = this.data.clientKey;
    if (this.data.masterKey != null)
      options.headers[keyHeaderMasterKey] = this.data.masterKey;

    /// If developer wants to add custom headers, extend this class and add headers needed.
    if (additionalHeaders != null && additionalHeaders.isNotEmpty) {
      additionalHeaders
          .forEach((String key, String value) => options.headers[key] = value);
    }

    if (this.data.debug) {
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
    curlCmd += ' -X ' + options.method;
    bool compressed = false;
    options.headers.forEach((String name, dynamic value) {
      if (name?.toLowerCase() == 'accept-encoding' &&
          value?.toString()?.toLowerCase() == 'gzip') {
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
    String method,
    int sendTimeout,
    int receiveTimeout,
    Map<String, dynamic> extra,
    Map<String, dynamic> headers,
    dio.ResponseType responseType,
    String contentType,
    dio.ValidateStatus validateStatus,
    bool receiveDataWhenStatusError,
    bool followRedirects,
    int maxRedirects,
    dio.RequestEncoder requestEncoder,
    dio.ResponseDecoder responseDecoder,
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
