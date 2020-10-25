part of flutter_parse_sdk;

typedef ParseClientCreator = ParseClient Function(
    {bool sendSessionId, SecurityContext securityContext});

abstract class ParseClient {
  Future<ParseNetworkResponse> get(
    String path, {
    ParseNetworkOptions options,
    ProgressCallback onReceiveProgress,
  });

  Future<ParseNetworkResponse> put(
    String path, {
    String data,
    ParseNetworkOptions options,
  });

  Future<ParseNetworkResponse> post(
    String path, {
    String data,
    ParseNetworkOptions options,
  });

  Future<ParseNetworkResponse> postBytes(
    String path, {
    Stream<List<int>> data,
    ParseNetworkOptions options,
    ProgressCallback onSendProgress,
  });

  Future<ParseNetworkResponse> delete(
    String path, {
    ParseNetworkOptions options,
  });

  Future<ParseNetworkByteResponse> getBytes(
    String path, {
    ParseNetworkOptions options,
    ProgressCallback onReceiveProgress,
  });

  // Future<ParseNetworkByteResponse> putBytes(
  //   String path, {
  //   dynamic data,
  //   Map<String, dynamic> queryParameters,
  //   ParseNetworkOptions options,
  //   ProgressCallback onReceiveProgress,
  // });
  //
  // Future<ParseNetworkByteResponse> postBytes(
  //   String path, {
  //   String data,
  //   ParseNetworkOptions options,
  //   ProgressCallback onReceiveProgress,
  //   ProgressCallback onSendProgress,
  // });
  //
  // Future<ParseNetworkByteResponse> deleteBytes(
  //   String path, {
  //   Map<String, dynamic> queryParameters,
  //   ParseNetworkOptions options,
  // });

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

class ParseNetworkResponse {
  final String data;
  final int statusCode;

  ParseNetworkResponse({
    this.data,
    this.statusCode = -1,
  });
}

class ParseNetworkByteResponse extends ParseNetworkResponse {
  final List<int> bytes;

  ParseNetworkByteResponse({
    this.bytes,
    final String data = 'byte response',
    final int statusCode,
  }) : super(
          data: data,
          statusCode: statusCode,
        );
}
