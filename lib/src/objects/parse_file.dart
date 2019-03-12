part of flutter_parse_sdk;

class ParseFile extends ParseObject {
  File file;
  String name;
  String url;

  @override
  String _path;

  bool get saved => url != null;

  @override
  toJson({bool full: false, bool forApiRQ: false}) =>
      <String, String>{'__type': keyFile, 'name': name, 'url': url};

  @override
  String toString() => json.encode(toString());

  /// Creates a new file
  ///
  /// {https://docs.parseplatform.org/rest/guide/#files/}
  ParseFile(this.file,
      {String name,
      String url,
      bool debug,
      ParseHTTPClient client,
      bool autoSendSessionId})
      : super(keyFile) {
    _debug = isDebugEnabled(objectLevelDebug: debug);
    _client = client ??
        ParseHTTPClient(
            autoSendSessionId:
                autoSendSessionId ?? ParseCoreData().autoSendSessionId,
            securityContext: ParseCoreData().securityContext);

    if (file != null) {
      this.name = path.basename(file.path);
      this._path = '/files/$name';
    } else {
      this.name = name;
      this.url = url;
    }
  }

  Future<ParseFile> loadStorage() async {
    Directory tempPath = await getTemporaryDirectory();

    if (name == null) {
      file = null;
      return this;
    }

    File possibleFile = new File("${tempPath.path}/$name");
    bool exists = await possibleFile.exists();

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

    Directory tempPath = await getTemporaryDirectory();
    this.file = new File("${tempPath.path}/$name");
    await file.create();

    var response = await _client.get(url);
    file.writeAsBytes(response.bodyBytes);

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
      final response = {"url": this.url, "name": this.name};
      return handleResponse(this, Response(json.encode(response), 201),
          ParseApiRQ.upload, _debug, className);
    }

    final ext = path.extension(file.path).replaceAll('.', '');
    final headers = <String, String>{
      HttpHeaders.contentTypeHeader: getContentType(ext)
    };
    try {
      var uri = _client.data.serverUrl + "$_path";
      final body = await file.readAsBytes();
      final response = await _client.post(uri, headers: headers, body: body);
      if (response.statusCode == 201) {
        final map = json.decode(response.body);
        this.url = map["url"].toString();
        this.name = map["name"].toString();
      }
      return handleResponse(
          this, response, ParseApiRQ.upload, _debug, className);
    } on Exception catch (e) {
      return handleException(e, ParseApiRQ.upload, _debug, className);
    }
  }
}
