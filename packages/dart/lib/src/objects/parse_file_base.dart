part of flutter_parse_sdk;

abstract class ParseFileBase extends ParseObject {
  /// Creates a new file
  ///
  /// {https://docs.parseplatform.org/rest/guide/#files/}
  ParseFileBase(
      {@required String name,
      String url,
      bool debug,
      ParseHTTPClient client,
      bool autoSendSessionId})
      : super(keyFileClassname,
            debug: debug,
            autoSendSessionId: autoSendSessionId,
            client: client) {
    _path = '/files/$name';
    this.name = name;
    this.url = url;
  }

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

  /// Uploads a file to Parse Server
  @override
  Future<ParseResponse> save() async {
    return upload();
  }

  /// Uploads a file to Parse Server
  Future<ParseResponse> upload({ProgressCallback progressCallback});

  Future<ParseFileBase> download({ProgressCallback progressCallback});
}
