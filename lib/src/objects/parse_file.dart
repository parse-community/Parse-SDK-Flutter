part of flutter_parse_sdk;

class ParseFile extends ParseObject {

  File _file;
  String _fileName;
  String _fileUrl;

  @override
  String _path;

  String get name => _fileName;

  String get url => _fileUrl;

  File get file => _file;

  set url(String url) => _fileUrl = url;

  set name(String name) => _fileName = name;

  bool get saved => url != null;

  @override
  toJson({bool forApiRQ: false}) => <String, String>{'__type': keyFile, 'name': _fileName, 'url': _fileUrl};

  @override
  String toString() => json.encode(toString());

  /// Creates a new file
  ///
  /// {https://docs.parseplatform.org/rest/guide/#files/}
  ParseFile(this._file, {String name, String url, bool debug, ParseHTTPClient client}) : super (keyFile){
    client == null ? _client = ParseHTTPClient() : _client = client;
    _debug = isDebugEnabled(objectLevelDebug: debug);
    if(_file != null) {
      this._fileName = path.basename(_file.path);
      this._path = 'files/$_fileName';
    }
    else {
      this._fileName = name;
      this._fileUrl = url;
    }
  }

  Future<ParseFile> loadStorage() async {
    Directory tempPath = await getTemporaryDirectory();

    if(_fileName == null) {
      _file = null;
      return this;
    }

    File possibleFile = new File("${tempPath.path}/$_fileName");
    bool exists = await possibleFile.exists();

    if(exists) {
      _file = possibleFile;
    }
    else {
      _file = null;
    }

    return this;
  }

  Future<ParseFile> download() async {
    if(_fileUrl == null) {
      return this;
    }
    
    Directory tempPath = await getTemporaryDirectory();
    this._file = new File("${tempPath.path}/$_fileName");
    await _file.create();

    var response = await _client.get(_fileUrl);
    _file.writeAsBytes(response.bodyBytes);

    return this;
  }

  /// Uploads a file to Parse Server
  upload() async {
    if (saved) {
      return this;
    }

    final ext = path.extension(_file.path).replaceAll('.', '');
    final headers = <String, String>{
      HttpHeaders.contentTypeHeader: getContentType(ext)
    };

    var uri = _client.data.serverUrl + "$_path";
    final body = await _file.readAsBytes();
    final response = await _client.post(uri, headers: headers, body: body);
    return super.handleResponse<ParseFile>(response, ParseApiRQ.upload);
  }
}
