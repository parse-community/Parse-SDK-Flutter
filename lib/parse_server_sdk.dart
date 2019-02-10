library flutter_parse_sdk;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart';
import 'package:http/io_client.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/io.dart';
import 'package:uuid/uuid.dart';
import 'package:path_provider/path_provider.dart';

part 'src/base/parse_constants.dart';

part 'src/data/parse_core_data.dart';

part 'src/enums/parse_enum_api_rq.dart';

part 'src/network/parse_http_client.dart';

part 'src/network/parse_live_query.dart';

part 'src/network/parse_query.dart';

part 'src/objects/parse_base.dart';

part 'src/objects/parse_cloneable.dart';

part 'src/objects/parse_config.dart';

part 'src/objects/parse_error.dart';

part 'src/objects/parse_file.dart';

part 'src/objects/parse_function.dart';

part 'src/objects/parse_geo_point.dart';

part 'src/objects/parse_object.dart';

part 'src/objects/parse_response.dart';

part 'src/objects/parse_user.dart';

part 'src/utils/parse_decoder.dart';

part 'src/utils/parse_encoder.dart';

part 'src/utils/parse_file_extensions.dart';

part 'src/utils/parse_logger.dart';

part 'src/utils/parse_utils.dart';

class Parse {
  ParseCoreData data;
  bool _hasBeenInitialized = false;

  /// To initialize Parse Server in your application
  ///
  /// This should be initialized in MyApp() creation
  ///
  /// ```
  /// Parse().initialize(
  //        "PARSE_APP_ID",
  //        "https://parse.myaddress.com/parse/,
  //        masterKey: "asd23rjh234r234r234r",
  //        debug: true,
  //        liveQuery: true);
  // ```
  Parse initialize(String appId, String serverUrl,
      {bool debug: false,
      String appName: "",
      String liveQueryUrl,
      String clientKey,
      String masterKey,
      String sessionId,
      SecurityContext securityContext}) {
    ParseCoreData.init(appId, serverUrl,
        debug: debug,
        appName: appName,
        liveQueryUrl: liveQueryUrl,
        masterKey: masterKey,
        clientKey: clientKey,
        sessionId: sessionId,
        securityContext: securityContext);

    _hasBeenInitialized = true;

    return Parse();
  }

  bool hasParseBeenInitialized() => _hasBeenInitialized;

  Future<ParseResponse> healthCheck(
      {bool debug, ParseHTTPClient client}) async {
    ParseResponse parseResponse;

    bool _debug = isDebugEnabled(objectLevelDebug: debug);
    ParseHTTPClient _client =
        client ?? ParseHTTPClient(ParseCoreData().securityContext);

    try {
      var response =
          await _client.get("${ParseCoreData().serverUrl}$keyEndPointHealth");
      parseResponse =
          ParseResponse.handleResponse(this, response, returnAsResult: true);
    } on Exception catch (e) {
      parseResponse = ParseResponse.handleException(e);
    }

    if (_debug) {
      logger(ParseCoreData().appName, keyClassMain,
          ParseApiRQ.healthCheck.toString(), parseResponse);
    }

    return parseResponse;
  }
}
