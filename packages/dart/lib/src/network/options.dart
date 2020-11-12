part of flutter_parse_sdk;

class ParseNetworkOptions {
  ParseNetworkOptions({this.headers});

  final Map<String, dynamic> headers;
  // final ParseNetworkResponseType responseType;
}

enum ParseNetworkResponseType { json, stream, plain, bytes }
