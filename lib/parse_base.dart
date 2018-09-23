import 'package:parse_server_sdk/parse_http_client.dart';

abstract class ParseBaseObject {
  final String className;
  final ParseHTTPClient client;
  String path;
  Map<String, dynamic> objectData;

  String get objectId => objectData['objectId'];

  // ignore: unused_element
  void _handleResponse(Map<String, dynamic> response) {}

  ParseBaseObject(this.className, [this.client]);
}
