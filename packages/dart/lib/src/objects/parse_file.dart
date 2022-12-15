part of flutter_parse_sdk;

class ParseFile extends ParseFileBase {
  /// Creates a new file
  ///
  /// {https://docs.parseplatform.org/rest/guide/#files/}
  ParseFile(this.file,
      {String? name,
        String? url,
        bool? debug,
        ParseClient? client,
        bool? autoSendSessionId})
      : super(
    name: file != null ? path.basename(file.path) : name!,
    url: url,
    debug: debug,
    client: client,
    autoSendSessionId: autoSendSessionId,
  );

  File? file;
  CancelToken? _cancelToken;
  ProgressCallback? _uploadProgressCallback;
  ProgressCallback? _downloadProgressCallback;

  Future<ParseFile> loadStorage() async {
    final File possibleFile = File('${ParseCoreData().fileDirectory}/$name');
    // ignore: avoid_slow_async_io
    final bool exists = await possibleFile.exists();

    if (exists) {
      file = possibleFile;
    } else {
      file = null;
    }

    return this;
  }

  @override
  Future<ParseFile> download({ProgressCallback? progressCallback}) async {
    if (url == null) {
      return this;
    }

    file = File('${ParseCoreData().fileDirectory}/$name');
    await file!.create();

    if (_downloadProgressCallback != null) {
      progressCallback = _downloadProgressCallback;
    }

    _cancelToken = CancelToken();

    final ParseNetworkByteResponse response = await _client.getBytes(
      url!,
      onReceiveProgress: progressCallback,
      cancelToken: _cancelToken,
    );
    await file!.writeAsBytes(response.bytes!);

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
      return handleResponse<ParseFile>(
          this,
          ParseNetworkResponse(data: json.encode(response), statusCode: 201),
          ParseApiRQ.upload,
          _debug,
          parseClassName);
    }

    if (_uploadProgressCallback != null) {
      progressCallback = _uploadProgressCallback;
    }

    _cancelToken = CancelToken();

    final Map<String, String> headers = <String, String>{
      HttpHeaders.contentTypeHeader:
      mime(file!.path) ?? 'application/octet-stream',
      HttpHeaders.contentLengthHeader: '${file!.lengthSync()}',
    };

    try {
      final String uri = ParseCoreData().serverUrl + _path;
      final ParseNetworkResponse response = await _client.postBytes(
        uri,
        options: ParseNetworkOptions(headers: headers),
        data: file!.openRead(),
        onSendProgress: progressCallback,
        cancelToken: _cancelToken,
      );
      if (response.statusCode == 201) {
        final Map<String, dynamic> map = json.decode(response.data);
        url = map['url'].toString();
        name = map['name'].toString();
      }

      return handleResponse<ParseFile>(
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

  /// Add Progress Callback for file upload
  @override
  void addUploadProgressCallback(ProgressCallback progressCallback) {
    _uploadProgressCallback = progressCallback;
  }

  /// Add Progress Callback for file download
  @override
  void addDownloadProgressCallback(ProgressCallback progressCallback) {
    _downloadProgressCallback = progressCallback;
  }
}
