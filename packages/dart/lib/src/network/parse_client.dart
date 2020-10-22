part of flutter_parse_sdk;

typedef ParseClientCreator = ParseClient Function(
    {bool sendSessionId, SecurityContext securityContext});

abstract class ParseClient {
  Future<ParseNetworkResponse<T>> get<T>(
    String path, {
    Map<String, dynamic> queryParameters,
    ParseNetworkOptions options,
    ProgressCallback onReceiveProgress,
  });

  Future<ParseNetworkResponse<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic> queryParameters,
    ParseNetworkOptions options,
    ProgressCallback onReceiveProgress,
  });

  Future<ParseNetworkResponse<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic> queryParameters,
    ParseNetworkOptions options,
    ProgressCallback onReceiveProgress,
    ProgressCallback onSendProgress,
  });

  Future<ParseNetworkResponse<T>> delete<T>(
    String path, {
    Map<String, dynamic> queryParameters,
    ParseNetworkOptions options,
  });

  @deprecated
  ParseCoreData get data => ParseCoreData();
}

/// Callback to listen the progress for sending/receiving data.
///
/// [count] is the length of the bytes have been sent/received.
///
/// [total] is the content length of the response/request body.
/// 1.When receiving data:
///   [total] is the request body length.
/// 2.When receiving data:
///   [total] will be -1 if the size of the response body is not known in advance,
///   for example: response data is compressed with gzip or no content-length header.
typedef ProgressCallback = void Function(int count, int total);

class ParseNetworkResponse<T> {
  final T data;
  final int statusCode;
  ParseNetworkResponse({
    this.data,
    this.statusCode,
  });
}
