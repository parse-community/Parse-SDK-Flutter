import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:parse_server_sdk/parse_server_sdk.dart';

class ParseHTTPClient extends ParseClient {
  _ParseHTTPClient _client;

  ParseHTTPClient(
      {bool sendSessionId = false, SecurityContext securityContext}) {
    _client = _ParseHTTPClient(
      sendSessionId: sendSessionId,
      securityContext: securityContext,
    );
  }

  @override
  Future<ParseNetworkResponse> get(
    String path, {
    ParseNetworkOptions options,
    ProgressCallback onReceiveProgress,
  }) async {
    final http.Response response = await _client.get(
      path,
      headers: options?.headers,
    );
    return ParseNetworkResponse(
        data: response.body, statusCode: response.statusCode);
  }

  @override
  Future<ParseNetworkByteResponse> getBytes(
    String path, {
    ParseNetworkOptions options,
    ProgressCallback onReceiveProgress,
  }) async {
    final http.Response response = await _client.get(
      path,
      headers: options?.headers,
    );
    return ParseNetworkByteResponse(
        bytes: response.bodyBytes, statusCode: response.statusCode);
  }

  @override
  Future<ParseNetworkResponse> put(
    String path, {
    String data,
    ParseNetworkOptions options,
  }) async {
    final http.Response response = await _client.put(
      path,
      body: data,
      headers: options?.headers,
    );
    return ParseNetworkResponse(
        data: response.body, statusCode: response.statusCode);
  }

  @override
  Future<ParseNetworkResponse> post(
    String path, {
    String data,
    ParseNetworkOptions options,
  }) async {
    final http.Response response = await _client.post(
      path,
      body: data,
      headers: options?.headers,
    );
    return ParseNetworkResponse(
        data: response.body, statusCode: response.statusCode);
  }

  @override
  Future<ParseNetworkResponse> postBytes(
    String path, {
    Stream<List<int>> data,
    ParseNetworkOptions options,
    ProgressCallback onSendProgress,
  }) async {
    final http.Response response = await _client.post(
      path,
      //Convert the stream to a list
      body: await data.fold<List<int>>(<int>[], (List<int> previous, List<int> element) => previous..addAll(element)),
      headers: options?.headers,
    );
    return ParseNetworkResponse(
        data: response.body, statusCode: response.statusCode);
  }

  @override
  Future<ParseNetworkResponse> delete(String path,
      {ParseNetworkOptions options}) async {
    final http.Response response = await _client.delete(
      path,
      headers: options?.headers,
    );
    return ParseNetworkResponse(
        data: response.body, statusCode: response.statusCode);
  }
}

/// Creates a custom version of HTTP Client that has Parse Data Preset
class _ParseHTTPClient extends http.BaseClient {
  _ParseHTTPClient(
      {bool sendSessionId = false, SecurityContext securityContext})
      : _sendSessionId = sendSessionId,
        _client = securityContext != null
            ? IOClient(HttpClient(context: securityContext))
            : http.Client();

  final http.Client _client;
  final bool _sendSessionId;
  final String _userAgent = '$keyLibraryName $keySdkVersion';
  ParseCoreData data = ParseCoreData();
  Map<String, String> additionalHeaders;

  /// Overrides the call method for HTTP Client and adds custom headers
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    if (!identical(0, 0.0)) {
      request.headers[keyHeaderUserAgent] = _userAgent;
    }
    request.headers[keyHeaderApplicationId] = data.applicationId;
    if ((_sendSessionId == true) &&
        (data.sessionId != null) &&
        (request.headers[keyHeaderSessionToken] == null))
      request.headers[keyHeaderSessionToken] = data.sessionId;

    if (data.clientKey != null)
      request.headers[keyHeaderClientKey] = data.clientKey;
    if (data.masterKey != null)
      request.headers[keyHeaderMasterKey] = data.masterKey;

    /// If developer wants to add custom headers, extend this class and add headers needed.
    if (additionalHeaders != null && additionalHeaders.isNotEmpty) {
      additionalHeaders
          .forEach((String key, String value) => request.headers[key] = value);
    }

    if (data.debug) {
      _logCUrl(request);
    }

    return _client.send(request);
  }

  void _logCUrl(http.Request request) {
    String curlCmd = 'curl';
    curlCmd += ' -X ' + request.method;
    bool compressed = false;
    request.headers.forEach((String name, String value) {
      if (name?.toLowerCase() == 'accept-encoding' &&
          value?.toLowerCase() == 'gzip') {
        compressed = true;
      }
      curlCmd += ' -H \'$name: $value\'';
    });
    if (request.method == 'POST' || request.method == 'PUT') {
      if (request is http.Request) {
        final String body = latin1.decode(request.bodyBytes);
        curlCmd += ' -d \'$body\'';
      }
    }

    curlCmd += (compressed ? ' --compressed ' : ' ') + request.url.toString();
    curlCmd += '\n\n ${Uri.decodeFull(request.url.toString())}';
    print('╭-- Parse Request');
    print(curlCmd);
    print('╰--');
  }
}
