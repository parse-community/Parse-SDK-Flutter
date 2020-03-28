library flutter_parse_sdk;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:devicelocale/devicelocale.dart';
import 'package:http/http.dart';
import 'package:http/io_client.dart';
import 'package:meta/meta.dart';
import 'package:package_info/package_info.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:sembast/sembast.dart';
import 'package:sembast/sembast_io.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:xxtea/xxtea.dart';

export 'src/network/parse_live_query.dart'
if (dart.library.js) 'src/network/parse_live_query_web.dart';
export 'src/utils/parse_live_list.dart';

part 'package:parse_server_sdk/src/objects/response/parse_error_response.dart';

part 'package:parse_server_sdk/src/objects/response/parse_exception_response.dart';

part 'package:parse_server_sdk/src/objects/response/parse_response_builder.dart';

part 'package:parse_server_sdk/src/objects/response/parse_response_utils.dart';

part 'package:parse_server_sdk/src/objects/response/parse_success_no_results.dart';

part 'package:parse_server_sdk/src/data/core_store.dart';

part 'package:parse_server_sdk/src/storage/core_store_sem_impl.dart';

part 'package:parse_server_sdk/src/storage/core_store_sp_impl.dart';

part 'package:parse_server_sdk/src/storage/xxtea_codec.dart';

part 'src/base/parse_constants.dart';

part 'src/data/parse_core_data.dart';

part 'src/enums/parse_enum_api_rq.dart';

part 'src/network/parse_http_client.dart';

part 'src/network/parse_query.dart';

part 'src/objects/parse_acl.dart';

part 'src/objects/parse_base.dart';

part 'src/objects/parse_cloneable.dart';

part 'src/objects/parse_config.dart';

part 'src/objects/parse_error.dart';

part 'src/objects/parse_file.dart';

part 'src/objects/parse_function.dart';

part 'src/objects/parse_geo_point.dart';

part 'src/objects/parse_installation.dart';

part 'src/objects/parse_object.dart';

part 'src/objects/parse_relation.dart';

part 'src/objects/parse_response.dart';

part 'src/objects/parse_session.dart';

part 'src/objects/parse_user.dart';

part 'src/utils/parse_date_format.dart';

part 'src/utils/parse_decoder.dart';

part 'src/utils/parse_encoder.dart';

part 'src/utils/parse_file_extensions.dart';

part 'src/utils/parse_logger.dart';

part 'src/utils/parse_utils.dart';

part 'src/utils/parse_login_helpers.dart';

part 'src/objects/parse_merge.dart';

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
  Future<Parse> initialize(String appId, String serverUrl,
      {bool debug = false,
      String appName = '',
      String liveQueryUrl,
      String clientKey,
      String masterKey,
      String sessionId,
      bool autoSendSessionId,
        SecurityContext securityContext,
        CoreStore coreStore}) async {
    final String url = removeTrailingSlash(serverUrl);

    await ParseCoreData.init(appId, url,
        debug: debug,
        appName: appName,
        liveQueryUrl: liveQueryUrl,
        masterKey: masterKey,
        clientKey: clientKey,
        sessionId: sessionId,
        autoSendSessionId: autoSendSessionId,
        securityContext: securityContext,
        store: coreStore);

    _hasBeenInitialized = true;

    return this;
  }

  bool hasParseBeenInitialized() => _hasBeenInitialized;

  Future<ParseResponse> healthCheck(
      {bool debug, ParseHTTPClient client, bool sendSessionIdByDefault}) async {
    ParseResponse parseResponse;

    final bool _debug = isDebugEnabled(objectLevelDebug: debug);

    final ParseHTTPClient _client = client ??
        ParseHTTPClient(
            sendSessionId:
            sendSessionIdByDefault ?? ParseCoreData().autoSendSessionId,
            securityContext: ParseCoreData().securityContext);

    const String className = 'parseBase';
    const ParseApiRQ type = ParseApiRQ.healthCheck;

    try {
      final Response response =
          await _client.get('${ParseCoreData().serverUrl}$keyEndPointHealth');
      parseResponse =
          handleResponse<Parse>(null, response, type, _debug, className);
    } on Exception catch (e) {
      parseResponse = handleException(e, type, _debug, className);
    }

    return parseResponse;
  }
}
