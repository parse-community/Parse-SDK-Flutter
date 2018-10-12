import 'package:parse_server_sdk/network/parse_http_client.dart';

abstract class ParseBaseObject {
  final String _className;
  final ParseHTTPClient _client;
  String _path;
  Map<String, dynamic> _objectData;

  String get objectId => _objectData['objectId'];

  // ignore: unused_element
  void _handleResponse(Map<String, dynamic> response) {}

  ParseBaseObject(this._className, [this._client]);
}
