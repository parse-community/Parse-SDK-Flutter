part of flutter_parse_sdk;

class ParseWebFile extends ParseFileBase {
  ParseWebFile(this.file,
      {required String name,
      String? url,
      bool? debug,
      ParseClient? client,
      bool? autoSendSessionId})
      : super(
          name: name,
          url: url,
          debug: debug,
          client: client,
          autoSendSessionId: autoSendSessionId,
        );

  Uint8List? file;

  @override
  Future<ParseWebFile> download({ProgressCallback? progressCallback}) async {
    if (url == null) {
      return this;
    }

    final ParseNetworkByteResponse response = await _client.getBytes(
      url!,
      onReceiveProgress: progressCallback,
    );
    file = response.bytes as Uint8List?;

    return this;
  }

  @override
  Future<ParseResponse> upload({ProgressCallback? progressCallback}) async {
    if (saved) {
      //Creates a Fake Response to return the correct result
      final Map<String, String> response = <String, String>{
        'url': url!,
        'name': name
      };
      return handleResponse<ParseWebFile>(
          this,
          ParseNetworkResponse(data: json.encode(response), statusCode: 201),
          ParseApiRQ.upload,
          _debug,
          parseClassName);
    }

    final Map<String, String> headers = <String, String>{
      HttpHeaders.contentTypeHeader:
          mime(url ?? name) ?? 'application/octet-stream',
    };
    try {
      final String uri = ParseCoreData().serverUrl + '$_path';
      final ParseNetworkResponse response = await _client.postBytes(
        uri,
        options: ParseNetworkOptions(headers: headers),
        data: Stream<List<int>>.fromIterable(<List<int>>[file!]),
        onSendProgress: progressCallback,
      );
      if (response.statusCode == 201) {
        final Map<String, dynamic> map = json.decode(response.data);
        url = map['url'].toString();
        name = map['name'].toString();
      }
      return handleResponse<ParseWebFile>(
          this, response, ParseApiRQ.upload, _debug, parseClassName);
    } on Exception catch (e) {
      return handleException(e, ParseApiRQ.upload, _debug, parseClassName);
    }
  }
}
