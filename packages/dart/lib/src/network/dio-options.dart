part of flutter_parse_sdk;

class Options extends dio.Options {
  Options({
    String method,
    int sendTimeout,
    int receiveTimeout,
    Map<String, dynamic> extra,
    Map<String, dynamic> headers,
    ResponseType responseType,
    String contentType,
    ValidateStatus validateStatus,
    bool receiveDataWhenStatusError,
    bool followRedirects,
    int maxRedirects,
    RequestEncoder requestEncoder,
    ResponseDecoder responseDecoder,
  }) : super(
          method: method,
          sendTimeout: sendTimeout,
          receiveTimeout: receiveTimeout,
          extra: extra,
          headers: headers,
          responseType: responseType,
          contentType: contentType ??
              (headers ?? <String, dynamic>{})[Headers.contentTypeHeader],
          validateStatus: validateStatus,
          receiveDataWhenStatusError: receiveDataWhenStatusError,
          followRedirects: followRedirects,
          maxRedirects: maxRedirects,
          requestEncoder: requestEncoder,
          responseDecoder: responseDecoder,
        );
}
