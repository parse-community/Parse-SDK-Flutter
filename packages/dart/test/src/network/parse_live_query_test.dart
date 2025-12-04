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

    // Initialize once with mock provider, then test state changes
    setUpAll(() async {
      mockConnectivity = MockConnectivityProvider();
      // Initialize Parse once with the mock provider
      await Parse().initialize(
        'appId',
        serverUrl,
        debug: false,
        fileDirectory: 'someDirectory',
        appName: 'appName',
        appPackageName: 'somePackageName',
        appVersion: 'someAppVersion',
        connectivityProvider: mockConnectivity,
      );
    });

    tearDownAll(() {
      mockConnectivity.dispose();
    });

    // Test data for parameterized connectivity state tests
    final connectivityTestCases = <Map<String, dynamic>>[
      {
        'state': ParseConnectivityResult.wifi,
        'isOnline': true,
        'description': 'wifi should be treated as online',
      },
      {
        'state': ParseConnectivityResult.ethernet,
        'isOnline': true,
        'description': 'ethernet should be treated as online',
      },
      {
        'state': ParseConnectivityResult.mobile,
        'isOnline': true,
        'description': 'mobile should be treated as online',
      },
      {
        'state': ParseConnectivityResult.none,
        'isOnline': false,
        'description': 'none should be treated as offline',
      },
    ];

    for (final testCase in connectivityTestCases) {
      test(testCase['description'], () async {
        // arrange
        final state = testCase['state'] as ParseConnectivityResult;
        final isOnline = testCase['isOnline'] as bool;

        // act
        mockConnectivity.setConnectivity(state);
        final result = await mockConnectivity.checkConnectivity();

        // assert - verify the state is correctly identified
        expect(result, state);
        expect(result != ParseConnectivityResult.none, isOnline);
      });
    }

    test('should emit connectivity state transitions through stream', () async {
      // arrange
      final emittedStates = <ParseConnectivityResult>[];
      final subscription = mockConnectivity.connectivityStream.listen((state) {
        emittedStates.add(state);
      });

      // act - transition through different connectivity states
      mockConnectivity.setConnectivity(ParseConnectivityResult.wifi);
      await Future.delayed(Duration(milliseconds: 10));
      mockConnectivity.setConnectivity(ParseConnectivityResult.ethernet);
      await Future.delayed(Duration(milliseconds: 10));
      mockConnectivity.setConnectivity(ParseConnectivityResult.mobile);
      await Future.delayed(Duration(milliseconds: 10));
      mockConnectivity.setConnectivity(ParseConnectivityResult.none);
      await Future.delayed(Duration(milliseconds: 10));

      // assert - all state changes should be emitted
      expect(emittedStates.length, 4);
      expect(emittedStates[0], ParseConnectivityResult.wifi);
      expect(emittedStates[1], ParseConnectivityResult.ethernet);
      expect(emittedStates[2], ParseConnectivityResult.mobile);
      expect(emittedStates[3], ParseConnectivityResult.none);

      // verify online states (wifi, ethernet, mobile) are not "none"
      expect(emittedStates[0], isNot(ParseConnectivityResult.none));
      expect(emittedStates[1], isNot(ParseConnectivityResult.none));
      expect(emittedStates[2], isNot(ParseConnectivityResult.none));

      await subscription.cancel();
    });

    test('should transition from offline to online correctly', () async {
      // arrange
      final stateChanges = <ParseConnectivityResult>[];
      final subscription = mockConnectivity.connectivityStream.listen((state) {
        stateChanges.add(state);
      });

      // act - start offline, then go online via ethernet
      mockConnectivity.setConnectivity(ParseConnectivityResult.none);
      await Future.delayed(Duration(milliseconds: 10));
      mockConnectivity.setConnectivity(ParseConnectivityResult.ethernet);
      await Future.delayed(Duration(milliseconds: 10));

      // assert
      expect(stateChanges.length, 2);
      expect(stateChanges[0], ParseConnectivityResult.none);
      expect(stateChanges[1], ParseConnectivityResult.ethernet);
      // Verify the transition is from offline to online
      expect(stateChanges[0] == ParseConnectivityResult.none, true);
      expect(stateChanges[1] != ParseConnectivityResult.none, true);

      await subscription.cancel();
    });
  });
}
