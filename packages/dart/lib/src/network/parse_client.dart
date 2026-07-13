part of '../../parse_server_sdk.dart';

typedef ParseClientCreator =
    ParseClient Function({
      required bool sendSessionId,
      SecurityContext? securityContext,
    });

abstract class ParseClient {
  Future<ParseNetworkResponse> get(
    String path, {
    ParseNetworkOptions? options,
    ProgressCallback? onReceiveProgress,
  });

  Future<ParseNetworkResponse> put(
    String path, {
    String? data,
    ParseNetworkOptions? options,
  });

  Future<ParseNetworkResponse> post(
    String path, {
    String? data,
    ParseNetworkOptions? options,
  });

  Future<ParseNetworkResponse> postBytes(
    String path, {
    Stream<List<int>>? data,
    ParseNetworkOptions? options,
    ProgressCallback? onSendProgress,
    dynamic cancelToken,
  });

  Future<ParseNetworkResponse> delete(
    String path, {
    ParseNetworkOptions? options,
  });

  Future<ParseNetworkByteResponse> getBytes(
    String path, {
    ParseNetworkOptions? options,
    ProgressCallback? onReceiveProgress,
    dynamic cancelToken,
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

  @Deprecated("Use ParseCoreData() instead.")
  ParseCoreData get data => ParseCoreData();

  /// Returns `options.headers` with `X-Parse-Installation-Id` attached unless
  /// the caller opted out via `ParseNetworkOptions.sendInstallationId = false`
  /// or the header is already set. Installation lookup failures fall through
  /// silently — a network call should not fail because the install ID could
  /// not be read.
  @protected
  Future<Map<String, String>?> buildHeaders(
    ParseNetworkOptions? options,
  ) async {
    if (options?.sendInstallationId == false) return options?.headers;
    if (options?.headers?[keyHeaderInstallationId] != null) {
      return options?.headers;
    }
    String? installationId;
    try {
      installationId =
          (await ParseInstallation.currentInstallation()).installationId;
    } catch (_) {
      return options?.headers;
    }
    if (installationId == null) return options?.headers;
    return <String, String>{
      ...?options?.headers,
      keyHeaderInstallationId: installationId,
    };
  }
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
  ParseNetworkResponse({required this.data, this.statusCode = -1});

  final String data;
  final int statusCode;
}

class ParseNetworkByteResponse extends ParseNetworkResponse {
  ParseNetworkByteResponse({
    this.bytes,
    super.data = 'byte response',
    super.statusCode,
  });

  final List<int>? bytes;
}
