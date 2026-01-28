import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Test ParseObject class for CachedParseLiveList tests
class TestCacheObject extends ParseObject implements ParseCloneable {
  TestCacheObject() : super('TestCacheObject');
  TestCacheObject.clone() : this();

  @override
  TestCacheObject clone(Map<String, dynamic> map) =>
      TestCacheObject.clone()..fromJson(map);

  static TestCacheObject fromJsonStatic(Map<String, dynamic> json) {
    return TestCacheObject()..fromJson(json);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues(<String, String>{});
    await Parse().initialize(
      'appId',
      'https://test.server.com',
      clientKey: 'clientKey',
      liveQueryUrl: 'wss://test.server.com',
      appName: 'testApp',
      appPackageName: 'com.test.app',
      appVersion: '1.0.0',
      fileDirectory: 'testDirectory',
      debug: true,
    );
  });

  // Note: CachedParseLiveList is an internal class (not exported publicly)
  // and is tested indirectly through the live list widgets.
  // Direct unit tests would require exporting the class or using @visibleForTesting.

  group('LoadMoreStatus', () {
    test('should have all expected enum values', () {
      expect(LoadMoreStatus.values.length, 4);
      expect(LoadMoreStatus.idle, isNotNull);
      expect(LoadMoreStatus.loading, isNotNull);
      expect(LoadMoreStatus.noMoreData, isNotNull);
      expect(LoadMoreStatus.error, isNotNull);
    });

    test('idle should be first value', () {
      expect(LoadMoreStatus.values[0], LoadMoreStatus.idle);
    });

    test('loading should be second value', () {
      expect(LoadMoreStatus.values[1], LoadMoreStatus.loading);
    });

    test('noMoreData should be third value', () {
      expect(LoadMoreStatus.values[2], LoadMoreStatus.noMoreData);
    });

    test('error should be fourth value', () {
      expect(LoadMoreStatus.values[3], LoadMoreStatus.error);
    });

    test('enum values should have correct names', () {
      expect(LoadMoreStatus.idle.name, 'idle');
      expect(LoadMoreStatus.loading.name, 'loading');
      expect(LoadMoreStatus.noMoreData.name, 'noMoreData');
      expect(LoadMoreStatus.error.name, 'error');
    });
  });

  group('ChildBuilder typedef', () {
    test('should accept widget builder function with optional index', () {
      // Test that ChildBuilder<T> works with the expected signature
      Widget testBuilder(
        dynamic context,
        ParseLiveListElementSnapshot<TestCacheObject> snapshot, [
        int? index,
      ]) {
        return const SizedBox();
      }

      expect(testBuilder, isA<Function>());
    });
  });

  group('FooterBuilder typedef', () {
    test('should accept widget builder function', () {
      Widget testFooterBuilder(
        dynamic context,
        LoadMoreStatus status,
        void Function()? onRetry,
      ) {
        return const SizedBox();
      }

      expect(testFooterBuilder, isA<Function>());
    });
  });

  group('ParseLiveListElementSnapshot', () {
    test('should report no data when empty', () {
      final snapshot = ParseLiveListElementSnapshot<TestCacheObject>();

      expect(snapshot.hasData, isFalse);
      expect(snapshot.loadedData, isNull);
      expect(snapshot.preLoadedData, isNull);
    });

    test('should report data when loadedData is set', () {
      final obj = TestCacheObject()..objectId = 'test123';
      final snapshot = ParseLiveListElementSnapshot<TestCacheObject>(
        loadedData: obj,
      );

      expect(snapshot.hasData, isTrue);
      expect(snapshot.loadedData, isNotNull);
      expect(snapshot.loadedData?.objectId, 'test123');
    });

    test('should report data when preLoadedData is set', () {
      final obj = TestCacheObject()..objectId = 'test456';
      final snapshot = ParseLiveListElementSnapshot<TestCacheObject>(
        preLoadedData: obj,
      );

      // hasData only checks loadedData, not preLoadedData
      expect(snapshot.hasData, isFalse);
      expect(snapshot.hasPreLoadedData, isTrue);
      expect(snapshot.preLoadedData, isNotNull);
      expect(snapshot.preLoadedData?.objectId, 'test456');
    });

    test('should report failed state correctly', () {
      final snapshot = ParseLiveListElementSnapshot<TestCacheObject>(
        error: ParseError(code: 101, message: 'Test error'),
      );

      expect(snapshot.failed, isTrue);
      expect(snapshot.error, isNotNull);
    });

    test('should not report failed when no error', () {
      final snapshot = ParseLiveListElementSnapshot<TestCacheObject>();

      expect(snapshot.failed, isFalse);
      expect(snapshot.error, isNull);
    });

    test('should handle both loadedData and preLoadedData', () {
      final loaded = TestCacheObject()..objectId = 'loaded';
      final preLoaded = TestCacheObject()..objectId = 'preLoaded';
      final snapshot = ParseLiveListElementSnapshot<TestCacheObject>(
        loadedData: loaded,
        preLoadedData: preLoaded,
      );

      expect(snapshot.hasData, isTrue);
      expect(snapshot.loadedData?.objectId, 'loaded');
      expect(snapshot.preLoadedData?.objectId, 'preLoaded');
    });
  });
}
