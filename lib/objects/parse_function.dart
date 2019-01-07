import 'dart:convert';

import 'package:http/http.dart';
import 'package:parse_server_sdk/enums/parse_enum_function_call.dart';
import 'package:parse_server_sdk/network/parse_http_client.dart';
import 'package:parse_server_sdk/objects/parse_base.dart';
import 'package:parse_server_sdk/objects/parse_response.dart';

class ParseCloudFunction extends ParseBase {
  final String functionName;
  String _path;
  bool _debug;
  ParseHTTPClient _client;

  ParseCloudFunction(this.functionName, {bool debug, ParseHTTPClient client}) {

    client == null ? _client = ParseHTTPClient() : _client = client;

    if (_debug == null) {
      _client.data.debug != null ? _debug = _client.data.debug : false;
    } else {
      _debug = _debug;
    }

    _path = "/functions/$functionName";
    setObjectData(Map<String, dynamic>());
  }

  execute([Map<String, dynamic> objectData]) async {
    var uri = _client.data.serverUrl + "$_path";
    setObjectData(objectData);
    var result = await _client.post(uri, body: JsonEncoder().convert(getObjectData()));
    return _handleResult(result, ParseApiFunctionCallType.execute);
  }

  ParseResponse _handleResult(Response response, ParseApiFunctionCallType type) {
    ParseResponse parseResponse = ParseResponse.handleResponse(this, response);
    Map<String, dynamic> responseData = JsonDecoder().convert(response.body);

    if (_client.data.debug || _debug) {
      var responseString = ' \n';

      responseString += "----"
          "\n${_client.data.appName} API Response ($functionName : ${getEnumValue(type)}) :";

      if (parseResponse.success && parseResponse.result != null) {
        responseString += "\nStatus Code: ${parseResponse.statusCode}";
        responseString += "\nPayload: ${responseData.toString()}";
      } else if (!parseResponse.success) {
        responseString += "\nStatus Code: ${responseData['code'] == null ? parseResponse.statusCode : responseData['code']}";
        responseString += "\nException: ${responseData['error'] == null ? responseData.toString() : responseData['error']}";
      }

      responseString += "\n----\n";
      print(responseString);
    }

    return parseResponse;
  }
}
