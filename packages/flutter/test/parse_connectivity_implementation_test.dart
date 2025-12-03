import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:connectivity_plus_platform_interface/connectivity_plus_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

/// Mock implementation of ConnectivityPlatform for testing
class MockConnectivityPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements ConnectivityPlatform {
  List<ConnectivityResult> _connectivity = [ConnectivityResult.none];
  final StreamController<List<ConnectivityResult>> _controller =
      StreamController<List<ConnectivityResult>>.broadcast();

  void setConnectivity(List<ConnectivityResult> connectivity) {
    _connectivity = connectivity;
    _controller.add(connectivity);
  }

  @override
  Future<List<ConnectivityResult>> checkConnectivity() async {
    return _connectivity;
  }

  @override
  Stream<List<ConnectivityResult>> get onConnectivityChanged =>
      _controller.stream;

  void dispose() {
    _controller.close();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Parse.checkConnectivity() implementation', () {
    late MockConnectivityPlatform mockPlatform;

    setUp(() {
      mockPlatform = MockConnectivityPlatform();
      ConnectivityPlatform.instance = mockPlatform;
    });

    tearDown(() {
      mockPlatform.dispose();
    });

    test('wifi connection returns ParseConnectivityResult.wifi', () async {
      mockPlatform.setConnectivity([ConnectivityResult.wifi]);

      final result = await Parse().checkConnectivity();

      expect(result, ParseConnectivityResult.wifi);
    });

    test('ethernet connection returns ParseConnectivityResult.ethernet',
        () async {
      mockPlatform.setConnectivity([ConnectivityResult.ethernet]);

      final result = await Parse().checkConnectivity();

      expect(result, ParseConnectivityResult.ethernet);
    });

    test('mobile connection returns ParseConnectivityResult.mobile', () async {
      mockPlatform.setConnectivity([ConnectivityResult.mobile]);

      final result = await Parse().checkConnectivity();

      expect(result, ParseConnectivityResult.mobile);
    });

    test('no connection returns ParseConnectivityResult.none', () async {
      mockPlatform.setConnectivity([ConnectivityResult.none]);

      final result = await Parse().checkConnectivity();

      expect(result, ParseConnectivityResult.none);
    });

    test('wifi takes priority over ethernet', () async {
      mockPlatform
          .setConnectivity([ConnectivityResult.wifi, ConnectivityResult.ethernet]);

      final result = await Parse().checkConnectivity();

      expect(result, ParseConnectivityResult.wifi);
    });

    test('ethernet takes priority over mobile (issue #1042 fix)', () async {
      mockPlatform.setConnectivity(
          [ConnectivityResult.ethernet, ConnectivityResult.mobile]);

      final result = await Parse().checkConnectivity();

      expect(result, ParseConnectivityResult.ethernet);
    });

    test('unsupported connection types fall back to none', () async {
      mockPlatform.setConnectivity([ConnectivityResult.bluetooth]);

      final result = await Parse().checkConnectivity();

      expect(result, ParseConnectivityResult.none);
    });
  });

  group('Parse.connectivityStream implementation', () {
    late MockConnectivityPlatform mockPlatform;

    setUp(() {
      mockPlatform = MockConnectivityPlatform();
      ConnectivityPlatform.instance = mockPlatform;
    });

    tearDown(() {
      mockPlatform.dispose();
    });

    test('wifi event emits ParseConnectivityResult.wifi', () async {
      final completer = Completer<ParseConnectivityResult>();
      final subscription = Parse().connectivityStream.listen((result) {
        if (!completer.isCompleted) {
          completer.complete(result);
        }
      });

      mockPlatform.setConnectivity([ConnectivityResult.wifi]);

      final result = await completer.future;
      expect(result, ParseConnectivityResult.wifi);

      await subscription.cancel();
    });

    test('ethernet event emits ParseConnectivityResult.ethernet', () async {
      final completer = Completer<ParseConnectivityResult>();
      final subscription = Parse().connectivityStream.listen((result) {
        if (!completer.isCompleted) {
          completer.complete(result);
        }
      });

      mockPlatform.setConnectivity([ConnectivityResult.ethernet]);

      final result = await completer.future;
      expect(result, ParseConnectivityResult.ethernet);

      await subscription.cancel();
    });

    test('mobile event emits ParseConnectivityResult.mobile', () async {
      final completer = Completer<ParseConnectivityResult>();
      final subscription = Parse().connectivityStream.listen((result) {
        if (!completer.isCompleted) {
          completer.complete(result);
        }
      });

      mockPlatform.setConnectivity([ConnectivityResult.mobile]);

      final result = await completer.future;
      expect(result, ParseConnectivityResult.mobile);

      await subscription.cancel();
    });

    test('none event emits ParseConnectivityResult.none', () async {
      final completer = Completer<ParseConnectivityResult>();
      final subscription = Parse().connectivityStream.listen((result) {
        if (!completer.isCompleted) {
          completer.complete(result);
        }
      });

      mockPlatform.setConnectivity([ConnectivityResult.none]);

      final result = await completer.future;
      expect(result, ParseConnectivityResult.none);

      await subscription.cancel();
    });

    test('stream respects priority: ethernet over mobile', () async {
      final completer = Completer<ParseConnectivityResult>();
      final subscription = Parse().connectivityStream.listen((result) {
        if (!completer.isCompleted) {
          completer.complete(result);
        }
      });

      mockPlatform.setConnectivity(
          [ConnectivityResult.ethernet, ConnectivityResult.mobile]);

      final result = await completer.future;
      expect(result, ParseConnectivityResult.ethernet);

      await subscription.cancel();
    });
  });
}
