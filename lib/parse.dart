library flutter_parse_sdk;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart';
import 'package:intl/intl.dart';
import 'package:meta/meta.dart';
import 'package:web_socket_channel/io.dart';

part 'src/base/parse_constants.dart';
part 'src/data/parse_data.dart';
part 'src/data/parse_data_objects.dart';
part 'src/data/parse_data_server.dart';
part 'src/data/parse_data_user.dart';
part 'src/enums/parse_enum_function_call.dart';
part 'src/enums/parse_enum_object_call.dart';
part 'src/enums/parse_enum_user_call.dart';
part 'src/network/parse_http_client.dart';
part 'src/network/parse_livequery.dart';
part 'src/network/parse_query.dart';
part 'src/objects/parse_base.dart';
part 'src/objects/parse_exception.dart';
part 'src/objects/parse_function.dart';
part 'src/objects/parse_object.dart';
part 'src/objects/parse_response.dart';
part 'src/objects/parse_user.dart';

part 'src/utils/parse_utils_date.dart';
part 'src/utils/parse_utils_objects.dart';

class Parse {
  ParseDataServer data;
  final ParseHTTPClient client = new ParseHTTPClient();

  Parse initialize(appId, serverUrl, {debug, appName, liveQueryUrl, masterKey, sessionId}) {
    ParseDataServer.init(appId,
        serverUrl,
        debug: debug,
        appName: appName,
        liveQueryUrl: liveQueryUrl,
        masterKey: masterKey,
        sessionId: sessionId);

    return newInstance(ParseDataServer());
  }

  Parse newInstance(ParseDataServer data) {
    var parse = Parse();
    parse.data = data;
    parse.client.data = data;
    return parse;
  }
}
