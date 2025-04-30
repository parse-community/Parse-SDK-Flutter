class UrlReplace{
  String? scheme;
  String? userInfo;
  String? host;
  int? port;
  String? path;
  Iterable<String>? pathSegments;
  String? query;
  Map<String, dynamic>? queryParameters;
  String? fragment;

  UrlReplace({
    this.scheme,
    this.userInfo,
    this.host,
    this.port,
    this.path,
    this.pathSegments,
    this.query,
    this.queryParameters,
    this.fragment,
  });

}