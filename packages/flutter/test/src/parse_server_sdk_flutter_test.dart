@TestOn('dart-vm')
@Timeout.factor(2)

import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'storage/core_store_directory_io_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Parse parse;
  late FakeConnectivity fakeConnectivity;

  setUp(() {
    fakeConnectivity = FakeConnectivity();
    parse = Parse(fakeConnectivity);

    PackageInfo.setMockInitialValues(
      appName: 'appName',
      packageName: 'packageName',
      version: '1.0',
      buildNumber: '1',
      buildSignature: 'buildSignature',
    );
    SharedPreferences.setMockInitialValues({});
    PathProviderPlatform.instance = FakePathProviderPlatform();
  });

  group('Connectivity static checks', () {
    test('Check when connectivity is None', () async {
      fakeConnectivity.addConnectivityStatus(ConnectivityResult.none);

      // sut
      final result = await parse.checkConnectivity();

      expect(result, ParseConnectivityResult.none);
    });

    test('Check when connectivity is Wifi', () async {
      fakeConnectivity.addConnectivityStatus(ConnectivityResult.wifi);

      // sut
      final result = await parse.checkConnectivity();

      expect(result, ParseConnectivityResult.wifi);
    });

    test('Check when connectivity is Mobile', () async {
      fakeConnectivity.addConnectivityStatus(ConnectivityResult.mobile);

      // sut
      final result = await parse.checkConnectivity();

      expect(result, ParseConnectivityResult.mobile);
    });

    test('Check when connectivity is Mobile and VPN', () async {
      fakeConnectivity.addConnectivityStatus(ConnectivityResult.vpn);
      fakeConnectivity.addConnectivityStatus(ConnectivityResult.mobile);

      // sut
      final result = await parse.checkConnectivity();

      expect(result, ParseConnectivityResult.mobile);
    });

    test('Check when connectivity is Wifi + Mobile that Wifi is preferred',
        () async {
      fakeConnectivity.addConnectivityStatus(ConnectivityResult.mobile);
      fakeConnectivity.addConnectivityStatus(ConnectivityResult.wifi);

      // sut
      final result = await parse.checkConnectivity();

      expect(result, ParseConnectivityResult.wifi);
    });

    test(
        'Check when connectivity is Other that we preserve old behavior that Wifi is assumed',
        () async {
      fakeConnectivity.addConnectivityStatus(ConnectivityResult.other);

      // sut
      final result = await parse.checkConnectivity();

      expect(result, ParseConnectivityResult.wifi);
    });
  });

  group('Connectivity stream tests', () {
    test('Update stream when connectivity changes to None', () async {
      final completer = Completer<ParseConnectivityResult>();
      fakeConnectivity.addConnectivityStatus(ConnectivityResult.mobile);
      parse.connectivityStream.listen((event) {
        if (event == ParseConnectivityResult.none) {
          completer.complete(event);
        }
      });

      // sut - trigger event
      fakeConnectivity.updateConnectivityStatus(ConnectivityResult.none);
      final result = await completer.future;

      // assert
      expect(result, ParseConnectivityResult.none);
    }, timeout: const Timeout(Duration(seconds: 1)));
  });

  test('Update stream when connectivity changes to Wifi', () async {
    final completer = Completer<ParseConnectivityResult>();
    fakeConnectivity.addConnectivityStatus(ConnectivityResult.none);
    parse.connectivityStream.listen((event) {
      print('event: $event');
      if (event == ParseConnectivityResult.wifi) {
        completer.complete(event);
      }
    });

    // sut - trigger event
    fakeConnectivity.updateConnectivityStatus(ConnectivityResult.wifi);
    final result = await completer.future;

    // assert
    expect(result, ParseConnectivityResult.wifi);
  }, timeout: const Timeout(Duration(seconds: 1)));

  test(
      'Update stream when connectivity even though connectivity stayed the same',
      () async {
    final completer = Completer<ParseConnectivityResult>();
    fakeConnectivity.addConnectivityStatus(ConnectivityResult.mobile);
    parse.connectivityStream.listen((event) {
      print('event: $event');
      if (event == ParseConnectivityResult.mobile) {
        completer.complete(event);
      }
    });

    // sut - trigger event where mobile user joins VPN
    fakeConnectivity.addConnectivityStatus(ConnectivityResult.vpn);
    final result = await completer.future;

    // assert that event was triggered but connectivity still says mobile
    expect(result, ParseConnectivityResult.mobile);
  }, timeout: const Timeout(Duration(seconds: 1)));
}

Connectivity get fakeConnectivity {
  return FakeConnectivity();
}

class FakeConnectivity extends Fake implements Connectivity {
  final List<ConnectivityResult> _results = List.empty(growable: true);
  final StreamController<List<ConnectivityResult>> _streamController =
      StreamController.broadcast();

  void updateConnectivityStatus(ConnectivityResult result) {
    _results.clear();
    addConnectivityStatus(result);
  }

  addConnectivityStatus(ConnectivityResult result) {
    _results.add(result);
    _streamController.sink.add(_results);
  }

  @override
  Future<List<ConnectivityResult>> checkConnectivity() async {
    return _results;
  }

  @override
  Stream<List<ConnectivityResult>> get onConnectivityChanged {
    return _streamController.stream;
  }
}
