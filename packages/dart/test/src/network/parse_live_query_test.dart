import 'dart:async';
import 'dart:convert';

import 'package:parse_server_sdk/parse_server_sdk.dart';
import 'package:test/test.dart';

import '../../test_utils.dart';

/// Mock connectivity provider for testing different connectivity states
class MockConnectivityProvider implements ParseConnectivityProvider {
  final StreamController<ParseConnectivityResult> _controller =
      StreamController<ParseConnectivityResult>.broadcast();
  ParseConnectivityResult _currentState = ParseConnectivityResult.wifi;

  @override
  Future<ParseConnectivityResult> checkConnectivity() async {
    return _currentState;
  }

  @override
  Stream<ParseConnectivityResult> get connectivityStream => _controller.stream;

  void setConnectivity(ParseConnectivityResult state) {
    _currentState = state;
    _controller.add(state);
  }

  void dispose() {
    _controller.close();
  }
}

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

  group('Connectivity handling', () {
    late MockConnectivityProvider mockConnectivity;

    setUp(() {
      mockConnectivity = MockConnectivityProvider();
    });

    tearDown(() {
      mockConnectivity.dispose();
    });

    test('should handle wifi connectivity', () async {
      // arrange
      mockConnectivity.setConnectivity(ParseConnectivityResult.wifi);

      await Parse().initialize(
        'appId',
        serverUrl,
        debug: true,
        fileDirectory: 'someDirectory',
        appName: 'appName',
        appPackageName: 'somePackageName',
        appVersion: 'someAppVersion',
        connectivityProvider: mockConnectivity,
      );

      // act
      final result = await mockConnectivity.checkConnectivity();

      // assert
      expect(result, ParseConnectivityResult.wifi);
    });

    test('should handle ethernet connectivity', () async {
      // arrange
      mockConnectivity.setConnectivity(ParseConnectivityResult.ethernet);

      await Parse().initialize(
        'appId',
        serverUrl,
        debug: true,
        fileDirectory: 'someDirectory',
        appName: 'appName',
        appPackageName: 'somePackageName',
        appVersion: 'someAppVersion',
        connectivityProvider: mockConnectivity,
      );

      // act
      final result = await mockConnectivity.checkConnectivity();

      // assert
      expect(result, ParseConnectivityResult.ethernet);
    });

    test('should handle mobile connectivity', () async {
      // arrange
      mockConnectivity.setConnectivity(ParseConnectivityResult.mobile);

      await Parse().initialize(
        'appId',
        serverUrl,
        debug: true,
        fileDirectory: 'someDirectory',
        appName: 'appName',
        appPackageName: 'somePackageName',
        appVersion: 'someAppVersion',
        connectivityProvider: mockConnectivity,
      );

      // act
      final result = await mockConnectivity.checkConnectivity();

      // assert
      expect(result, ParseConnectivityResult.mobile);
    });

    test('should handle no connectivity', () async {
      // arrange
      mockConnectivity.setConnectivity(ParseConnectivityResult.none);

      await Parse().initialize(
        'appId',
        serverUrl,
        debug: true,
        fileDirectory: 'someDirectory',
        appName: 'appName',
        appPackageName: 'somePackageName',
        appVersion: 'someAppVersion',
        connectivityProvider: mockConnectivity,
      );

      // act
      final result = await mockConnectivity.checkConnectivity();

      // assert
      expect(result, ParseConnectivityResult.none);
    });

    test('should emit connectivity changes through stream', () async {
      // arrange
      mockConnectivity.setConnectivity(ParseConnectivityResult.wifi);

      await Parse().initialize(
        'appId',
        serverUrl,
        debug: true,
        fileDirectory: 'someDirectory',
        appName: 'appName',
        appPackageName: 'somePackageName',
        appVersion: 'someAppVersion',
        connectivityProvider: mockConnectivity,
      );

      final List<ParseConnectivityResult> emittedStates = [];
      final subscription = mockConnectivity.connectivityStream.listen((state) {
        emittedStates.add(state);
      });

      // act
      mockConnectivity.setConnectivity(ParseConnectivityResult.ethernet);
      await Future.delayed(Duration(milliseconds: 10));
      mockConnectivity.setConnectivity(ParseConnectivityResult.mobile);
      await Future.delayed(Duration(milliseconds: 10));
      mockConnectivity.setConnectivity(ParseConnectivityResult.none);
      await Future.delayed(Duration(milliseconds: 10));

      // assert
      expect(emittedStates.length, 3);
      expect(emittedStates[0], ParseConnectivityResult.ethernet);
      expect(emittedStates[1], ParseConnectivityResult.mobile);
      expect(emittedStates[2], ParseConnectivityResult.none);

      await subscription.cancel();
    });
  });
}
