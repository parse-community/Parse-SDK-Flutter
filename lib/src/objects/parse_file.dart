part of flutter_parse_sdk;

class ParseFile extends ParseObject {
  File _file;
  String _fileName;
  String _fileUrl;

  @override
  String _path;

  String get name => _fileName;

  String get url => _fileUrl;

  bool get saved => url != null;

  @override
  toJson({bool forApiRQ: false}) =>
      <String, String>{'__type': keyFile, 'name': _fileName, 'url': _fileUrl};

  @override
  String toString() => json.encode(toString());

  /// Creates a new file
  ///
  /// {https://docs.parseplatform.org/rest/guide/#files/}
  ParseFile(this._file, {bool debug, ParseHTTPClient client}) : super(keyFile) {
    client == null ? _client = ParseHTTPClient() : _client = client;
    _debug = isDebugEnabled(objectLevelDebug: debug);

    this._fileName = path.basename(_file.path);
    this._path = 'files/$_fileName';
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
    return handleResponse<ParseFile>(this, response, ParseApiRQ.upload, _debug, className);
  }
}
