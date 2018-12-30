import 'package:http/http.dart';
import 'package:meta/meta.dart';
import 'package:parse_server_sdk/network/parse_http_client.dart';
import 'package:parse_server_sdk/objects/parse_base.dart';
import 'package:parse_server_sdk/objects/parse_response.dart';

class ParseObject extends ParseBaseObject {
  final String className;
  String path;
  bool debug;

  ParseObject(this.className, {this.debug: false}) : super(ParseHTTPClient()) {
    path = "/classes/$className";
  }

  get(String id) async {
    var result = await parseGetObjectById(id, path);
    return _handleResult(result);
  }

  getAll() async {
    var result = await parseGetAll(path);
    return _handleResult(result);
  }

  create([Map<String, dynamic> objectData]) async {
    var result = await parseCreate(path, objectData);
    return _handleResult(result);
  }

  save() async {
    var result = await parseSave(path);
    return _handleResult(result);
  }

  @protected
  query(String query) async {
    var result = await parseQuery(path, query);
    return _handleResult(result);
  }

  _handleResult(Response response) {
    ParseResponse parseResponse = ParseResponse.handleResponse(this, response);

    if (getDebugStatus() || debug) {

      var responseString = " \n";

      responseString +=
          "----"
          "\n${getAppName()} API Response:" +
          "\nStatus Code: ${parseResponse.statusCode}";

      if (parseResponse.success && parseResponse.result != null) {
        responseString += "\nPayload: ${parseResponse.result.toString()}";
      } else if (!parseResponse.success) {
        responseString += "\nException: ${parseResponse.exception.message}";
      }

      responseString += "\n----";
      print(responseString);
    }

    return ParseResponse.handleResponse(this, response);
  }
}
