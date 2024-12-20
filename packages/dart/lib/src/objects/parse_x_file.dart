part of '../../parse_server_sdk.dart';

class ParseXFile extends ParseFileBase {
  /// Creates a new file base XFile
  ///
  /// {https://docs.parseplatform.org/rest/guide/#files/}
  ParseXFile(this.file,
      {String? name,
      super.url,
      super.debug,
      super.client,
      super.autoSendSessionId})
      : super(
          name: name ?? path.basename(file?.path ?? ''),
        );

  XFile? file;
  CancelToken? _cancelToken;
  ProgressCallback? _progressCallback;

  Future<ParseXFile> loadStorage() async {
    // Web not need load storage.
    if (parseIsWeb) {
      return this;
    }

    final XFile possibleFile = XFile('${ParseCoreData().fileDirectory}/$name');
    // ignore: avoid_slow_async_io
    final bool exists = await File(possibleFile.path).exists();

    if (exists) {
      file = possibleFile;
    } else {
      file = null;
    }

    return this;
  }

  @override
  Future<ParseXFile> download({ProgressCallback? progressCallback}) async {
    if (url == null) {
      return this;
    }

    progressCallback ??= _progressCallback;

    _cancelToken = CancelToken();

    if (parseIsWeb) {
      final ParseNetworkByteResponse response = await _client.getBytes(
        url!,
        onReceiveProgress: progressCallback,
        cancelToken: _cancelToken,
      );

      if (response.bytes != null) {
        file = XFile.fromData(response.bytes as Uint8List);
      }
    } else {
      file = XFile('${ParseCoreData().fileDirectory}/$name');
      await File(file!.path).create();

      final ParseNetworkByteResponse response = await _client.getBytes(
        url!,
        onReceiveProgress: progressCallback,
        cancelToken: _cancelToken,
      );
      await File(file!.path).writeAsBytes(response.bytes!);
    }

    return this;
  }

  /// Uploads a file to Parse Server
  @override
  Future<ParseResponse> upload({ProgressCallback? progressCallback}) async {
    if (saved) {
      //Creates a Fake Response to return the correct result
      final Map<String, String> response = <String, String>{
        'url': url!,
        'name': name
      };
      return handleResponse<ParseXFile>(
          this,
          ParseNetworkResponse(data: json.encode(response), statusCode: 201),
          ParseApiRQ.upload,
          _debug,
          parseClassName);
    }

    progressCallback ??= _progressCallback;

    _cancelToken = CancelToken();
    Map<String, String> headers;
    if (parseIsWeb) {
      headers = <String, String>{
        HttpHeaders.contentTypeHeader: file?.mimeType ??
            lookupMimeType(url ?? file?.name ?? name,
                headerBytes: await file?.readAsBytes()) ??
            'application/octet-stream',
      };
    } else {
      headers = <String, String>{
        HttpHeaders.contentTypeHeader: file?.mimeType ??
            lookupMimeType(file!.path) ??
            'application/octet-stream',
        HttpHeaders.contentLengthHeader: '${await file!.length()}',
      };
    }

    try {
      final String uri = ParseCoreData().serverUrl + _path;

      Stream<List<int>>? data;
      if (parseIsWeb) {
        data = Stream<List<int>>.fromIterable(
            <List<int>>[await file!.readAsBytes()]);
      } else {
        data = file!.openRead();
      }

      final ParseNetworkResponse response = await _client.postBytes(
        uri,
        options: ParseNetworkOptions(headers: headers),
        data: data,
        onSendProgress: progressCallback,
        cancelToken: _cancelToken,
      );
      if (response.statusCode == 201) {
        final Map<String, dynamic> map = json.decode(response.data);
        url = map['url'].toString();
        name = map['name'].toString();
      }
      return handleResponse<ParseXFile>(
          this, response, ParseApiRQ.upload, _debug, parseClassName);
    } on Exception catch (e) {
      return handleException(e, ParseApiRQ.upload, _debug, parseClassName);
    }
  }

  /// Cancels the current request (upload or download of file).
  @override
  void cancel([dynamic reason]) {
    _cancelToken?.cancel(reason);
    _cancelToken = null;
  }

  /// Add Progress Callback
  @override
  void progressCallback(ProgressCallback progressCallback) {
    _progressCallback = progressCallback;
  }
}
