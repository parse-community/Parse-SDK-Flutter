library flutter_parse_sdk;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart';
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

part 'src/network/parse_livequery.dart';

part 'src/network/parse_query.dart';

part 'src/objects/parse_base.dart';

part 'src/objects/parse_clonable.dart';

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
  final ParseHTTPClient client = new ParseHTTPClient();
  bool _hasBeenInitialised = false;

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
  Parse initialize(String appId, String serverUrl,
      {bool debug: false,
      String appName: "",
      String liveQueryUrl,
      String masterKey,
      String sessionId}) {
    ParseCoreData.init(appId, serverUrl,
        debug: debug,
        appName: appName,
        liveQueryUrl: liveQueryUrl,
        masterKey: masterKey,
        sessionId: sessionId);

    ParseCoreData().initStorage();

    _hasBeenInitialised = true;

    return Parse();
  }

  bool hasParseBeenInitialised() => _hasBeenInitialised;

  Future<ParseResponse> healthCheck() async {
    ParseResponse parseResponse;

    try {
      var response = await ParseHTTPClient()
          .get("${ParseCoreData().serverUrl}$keyEndPointHealth");
      parseResponse =
          ParseResponse.handleResponse(this, response, returnAsResult: true);
    } on Exception catch (e) {
      parseResponse = ParseResponse.handleException(e);
    }

    if (ParseCoreData().debug) {
      logger(ParseCoreData().appName, keyClassMain,
          ParseApiRQ.healthCheck.toString(), parseResponse);
    }

    return parseResponse;
  }
}
