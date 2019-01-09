library flutter_parse_sdk;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart';
import 'package:meta/meta.dart';
import 'package:web_socket_channel/io.dart';

part 'src/base/parse_constants.dart';
part 'src/data/parse_core_data.dart';
part 'src/enums/parse_enum_function_call.dart';
part 'src/enums/parse_enum_object_call.dart';
part 'src/enums/parse_enum_user_call.dart';
part 'src/network/parse_http_client.dart';
part 'src/network/parse_livequery.dart';
part 'src/network/parse_query.dart';
part 'src/objects/parse_base.dart';
part 'src/objects/parse_exception.dart';
part 'src/objects/parse_function.dart';
part 'src/objects/parse_geo_point.dart';
part 'src/objects/parse_object.dart';
part 'src/objects/parse_response.dart';
part 'src/objects/parse_user.dart';
part 'src/utils/parse_utils_date.dart';
part 'src/utils/parse_utils_objects.dart';
part 'src/utils/parse_utils.dart';
part 'src/utils/parse_encoder.dart';

class Parse {
  ParseCoreData data;
  final ParseHTTPClient client = new ParseHTTPClient();

  /// To initialise Parse Server in your application
  ///
  /// This should be initialised in MyApp() creation
  ///
  /// ```
  /// Parse().initialize(
  //        "PARSE_APP_ID",
  //        "https://parse.myaddress.com/parse/,
  //        masterKey: "asd23rjh234r234r234r",
  //        debug: true,
  //        liveQuery: true);
  // ```
  Parse initialize(appId, serverUrl,
      {debug, appName, liveQueryUrl, masterKey, sessionId}) {
    ParseCoreData.init(appId, serverUrl,
        debug: debug,
        appName: appName,
        liveQueryUrl: liveQueryUrl,
        masterKey: masterKey,
        sessionId: sessionId);

    return _newInstance(ParseCoreData());
  }

  /// Creates a singleton instance of [ParseCoreData] that contains all the server information
  Parse _newInstance(ParseCoreData data) {
    var parse = Parse();
    parse.data = data;
    parse.client.data = data;
    data.initStorage();
    return parse;
  }
}
