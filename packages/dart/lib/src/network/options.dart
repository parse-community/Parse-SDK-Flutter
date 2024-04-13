part of '../../parse_server_sdk.dart';

class ParseNetworkOptions {
  ParseNetworkOptions({this.headers});

  final Map<String, String>? headers;
  // final ParseNetworkResponseType responseType;
}

enum ParseNetworkResponseType { json, stream, plain, bytes }
