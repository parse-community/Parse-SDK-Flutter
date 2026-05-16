part of '../../parse_server_sdk.dart';

class ParseNetworkOptions {
  ParseNetworkOptions({this.headers, this.sendInstallationId});

  final Map<String, String>? headers;

  /// When `false`, the client suppresses the `X-Parse-Installation-Id`
  /// header for this request. `null` (the default) lets the client attach
  /// the header — matching iOS PFURLSessionCommandRunner behaviour.
  final bool? sendInstallationId;
  // final ParseNetworkResponseType responseType;
}

enum ParseNetworkResponseType { json, stream, plain, bytes }
