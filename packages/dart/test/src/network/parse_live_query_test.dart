import 'dart:async';
import 'dart:convert';

import 'package:parse_server_sdk/parse_server_sdk.dart';
import 'package:test/test.dart';

import '../../test_utils.dart';

void main() {
  setUpAll(() async {
    // Create a fake server
    final channel = spawnHybridCode(r'''
      import 'dart:io';
      import 'package:stream_channel/stream_channel.dart';

      hybridMain(StreamChannel channel) async {
        var server = await HttpServer.bind('localhost', 0);
        server.transform(WebSocketTransformer()).listen((webSocket) {
          webSocket.listen((request) {
            webSocket.add(request);
          });
        });
        channel.sink.add(server.port);
      }
    ''');

    // Get port server
    int port = await channel.stream.first as int;
    await initializeParse(liveQueryUrl: 'http://localhost:$port');
  });

  test('should exist installationId in connect LiveQuery', () async {
    // arrange
    QueryBuilder<ParseObject> query = QueryBuilder<ParseObject>(
      ParseObject('Test'),
    );

    // Set installationId
    ParseInstallation parseInstallation = ParseInstallation();
    parseInstallation.set(keyInstallationId, "1234");
    final String objectJson = json.encode(parseInstallation.toJson(full: true));
    await ParseCoreData().getStore().setString(
      keyParseStoreInstallation,
      objectJson,
    );

    // Initialize LiveQuery
    final LiveQuery liveQuery = LiveQuery();
    liveQuery.client.chanelStream = StreamController<String>();

    // act
    await liveQuery.client.reconnect();
    await liveQuery.client.subscribe(query);

    // assert
    liveQuery.client.chanelStream?.stream.listen((event) {
      if (event.contains('connect')) {
        expect(true, event.contains('1234'));
      }
    });

    // 10 millisecond hold for stream
    await Future.delayed(Duration(milliseconds: 10));
  });
}
