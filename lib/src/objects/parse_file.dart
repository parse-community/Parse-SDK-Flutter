part of flutter_parse_sdk;

class ParseFile extends ParseObject {
  /// Creates a new file
  ///
  /// {https://docs.parseplatform.org/rest/guide/#files/}
  ParseFile(this.file,
      {String name,
      String url,
      bool debug,
      ParseHTTPClient client,
        bool autoSendSessionId})
      : super('ParseFile', debug: debug, autoSendSessionId: autoSendSessionId) {
    _debug = isDebugEnabled(objectLevelDebug: debug);
    _client = client ??
        ParseHTTPClient(
            sendSessionId:
                autoSendSessionId ?? ParseCoreData().autoSendSessionId,
            securityContext: ParseCoreData().securityContext);

    if (file != null) {
      name = path.basename(file.path);
      _path = '/files/$name';
    } else {
      name = name;
      url = url;
    }
  }

  File file;

  String get name => super.get<String>(keyVarName);
  set name(String name) => set<String>(keyVarName, name);

  String get url => super.get<String>(keyVarURL);
  set url(String url) => set<String>(keyVarURL, url);

  bool get saved => url != null;

  @override
  Map<String, dynamic> toJson({bool full = false, bool forApiRQ = false}) =>
      <String, String>{'__type': keyFile, 'name': name, 'url': url};

  @override
  String toString() => json.encode(toJson(full: true));

  Future<ParseFile> loadStorage() async {
    final Directory tempPath = await getTemporaryDirectory();

    if (name == null) {
      file = null;
      return this;
    }

    final File possibleFile = File('${tempPath.path}/$name');
    // ignore: avoid_slow_async_io
    final bool exists = await possibleFile.exists();

    if (exists) {
      file = possibleFile;
    } else {
      file = null;
    }

    return this;
  }

  Future<ParseFile> download() async {
    if (url == null) {
      return this;
    }

    final Directory tempPath = await getTemporaryDirectory();
    file = File('${tempPath.path}/$name');
    await file.create();
    final Response response = await _client.get(url);
    await file.writeAsBytes(response.bodyBytes);

    return this;
  }

  /// Uploads a file to Parse Server
  @override
  Future<ParseResponse> save() async {
    return upload();
  }

  /// Uploads a file to Parse Server
  Future<ParseResponse> upload() async {
    if (saved) {
      //Creates a Fake Response to return the correct result
      final Map<String, String> response = <String, String>{
        'url': url,
        'name': name
      };
      return handleResponse<ParseFile>(
          this,
          Response(json.encode(response), 201),
          ParseApiRQ.upload,
          _debug,
          parseClassName);
    }

    final String ext = path.extension(file.path).replaceAll('.', '');
    final Map<String, String> headers = <String, String>{
      HttpHeaders.contentTypeHeader: getContentType(ext)
    };
    try {
      final String uri = _client.data.serverUrl + '$_path';
      final List<int> body = await file.readAsBytes();
      final Response response =
          await _client.post(uri, headers: headers, body: body);
      if (response.statusCode == 201) {
        final Map<String, dynamic> map = json.decode(response.body);
        url = map['url'].toString();
        name = map['name'].toString();
      }
      return handleResponse<ParseFile>(
          this, response, ParseApiRQ.upload, _debug, parseClassName);
    } on Exception catch (e) {
      return handleException(e, ParseApiRQ.upload, _debug, parseClassName);
    }
  }
}
