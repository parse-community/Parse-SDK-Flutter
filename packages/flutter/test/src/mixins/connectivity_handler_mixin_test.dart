import 'dart:async';
import 'package:connectivity_plus_platform_interface/connectivity_plus_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'package:parse_server_sdk_flutter/src/mixins/connectivity_handler_mixin.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Mock implementation of ConnectivityPlatform for testing
class MockConnectivityPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements ConnectivityPlatform {
  List<ConnectivityResult> _connectivity = [ConnectivityResult.wifi];
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

/// Test widget that uses ConnectivityHandlerMixin
class TestConnectivityWidget extends StatefulWidget {
  final bool offlineModeEnabled;

  const TestConnectivityWidget({super.key, this.offlineModeEnabled = true});

  @override
  State<TestConnectivityWidget> createState() => TestConnectivityWidgetState();
}

class TestConnectivityWidgetState extends State<TestConnectivityWidget>
    with ConnectivityHandlerMixin<TestConnectivityWidget> {
  int loadFromServerCallCount = 0;
  int loadFromCacheCallCount = 0;
  int disposeLiveListCallCount = 0;

  @override
  void initState() {
    super.initState();
    initConnectivityHandler();
  }

  @override
  void dispose() {
    disposeConnectivityHandler();
    super.dispose();
  }

  @override
  String get connectivityLogPrefix => 'TestWidget';

  @override
  bool get isOfflineModeEnabled => widget.offlineModeEnabled;

  @override
  Future<void> loadDataFromServer() async {
    loadFromServerCallCount++;
  }

  @override
  Future<void> loadDataFromCache() async {
    loadFromCacheCallCount++;
  }

  @override
  void disposeLiveList() {
    disposeLiveListCallCount++;
  }

  @override
  Widget build(BuildContext context) {
    return Text(isOffline ? 'Offline' : 'Online');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockConnectivityPlatform mockPlatform;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues(<String, String>{});
    await Parse().initialize(
      'appId',
      'serverUrl',
      clientKey: 'clientKey',
      appName: 'testApp',
      appPackageName: 'com.test.app',
      appVersion: '1.0.0',
      fileDirectory: 'testDirectory',
      debug: true,
    );
  });

  setUp(() {
    mockPlatform = MockConnectivityPlatform();
    ConnectivityPlatform.instance = mockPlatform;
  });

  tearDown(() {
    mockPlatform.dispose();
  });

  group('ConnectivityHandlerMixin', () {
    testWidgets('should initialize with online state when wifi connected', (
      WidgetTester tester,
    ) async {
      // Arrange
      mockPlatform.setConnectivity([ConnectivityResult.wifi]);

      // Act
      await tester.pumpWidget(
        const MaterialApp(home: TestConnectivityWidget()),
      );
      await tester.pumpAndSettle();

      // Assert
      final state = tester.state<TestConnectivityWidgetState>(
        find.byType(TestConnectivityWidget),
      );
      expect(state.isOffline, isFalse);
      expect(state.loadFromServerCallCount, greaterThanOrEqualTo(1));
    });

    testWidgets('should initialize with offline state when no connection', (
      WidgetTester tester,
    ) async {
      // Arrange
      mockPlatform.setConnectivity([ConnectivityResult.none]);

      // Act
      await tester.pumpWidget(
        const MaterialApp(home: TestConnectivityWidget()),
      );
      await tester.pumpAndSettle();

      // Assert
      final state = tester.state<TestConnectivityWidgetState>(
        find.byType(TestConnectivityWidget),
      );
      expect(state.isOffline, isTrue);
      expect(state.loadFromCacheCallCount, greaterThanOrEqualTo(1));
    });

    testWidgets('should transition to offline when connection lost', (
      WidgetTester tester,
    ) async {
      // Arrange - Start with wifi
      mockPlatform.setConnectivity([ConnectivityResult.wifi]);

      await tester.pumpWidget(
        const MaterialApp(home: TestConnectivityWidget()),
      );
      await tester.pumpAndSettle();

      final state = tester.state<TestConnectivityWidgetState>(
        find.byType(TestConnectivityWidget),
      );

      // Act - Lose connection
      mockPlatform.setConnectivity([ConnectivityResult.none]);
      await tester.pumpAndSettle();

      // Assert
      expect(state.isOffline, isTrue);
      expect(state.disposeLiveListCallCount, greaterThanOrEqualTo(1));
      expect(state.loadFromCacheCallCount, greaterThanOrEqualTo(1));
    });

    testWidgets('should transition to online when connection restored', (
      WidgetTester tester,
    ) async {
      // Arrange - Start offline
      mockPlatform.setConnectivity([ConnectivityResult.none]);

      await tester.pumpWidget(
        const MaterialApp(home: TestConnectivityWidget()),
      );
      await tester.pumpAndSettle();

      final state = tester.state<TestConnectivityWidgetState>(
        find.byType(TestConnectivityWidget),
      );
      expect(state.isOffline, isTrue);

      // Act - Restore connection
      mockPlatform.setConnectivity([ConnectivityResult.wifi]);
      await tester.pumpAndSettle();

      // Assert
      expect(state.isOffline, isFalse);
      expect(state.loadFromServerCallCount, greaterThanOrEqualTo(1));
    });

    testWidgets('should handle mobile connection as online', (
      WidgetTester tester,
    ) async {
      // Arrange
      mockPlatform.setConnectivity([ConnectivityResult.mobile]);

      // Act
      await tester.pumpWidget(
        const MaterialApp(home: TestConnectivityWidget()),
      );
      await tester.pumpAndSettle();

      // Assert
      final state = tester.state<TestConnectivityWidgetState>(
        find.byType(TestConnectivityWidget),
      );
      expect(state.isOffline, isFalse);
    });

    testWidgets('should not load from cache when offline mode disabled', (
      WidgetTester tester,
    ) async {
      // Arrange
      mockPlatform.setConnectivity([ConnectivityResult.none]);

      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: TestConnectivityWidget(offlineModeEnabled: false),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      final state = tester.state<TestConnectivityWidgetState>(
        find.byType(TestConnectivityWidget),
      );
      expect(state.isOffline, isTrue);
      expect(state.loadFromCacheCallCount, equals(0));
    });

    testWidgets('should expose isOffline getter', (WidgetTester tester) async {
      // Arrange
      mockPlatform.setConnectivity([ConnectivityResult.wifi]);

      // Act
      await tester.pumpWidget(
        const MaterialApp(home: TestConnectivityWidget()),
      );
      await tester.pumpAndSettle();

      // Assert
      final state = tester.state<TestConnectivityWidgetState>(
        find.byType(TestConnectivityWidget),
      );
      expect(state.isOffline, isFalse);
    });

    testWidgets('should properly dispose connectivity subscription', (
      WidgetTester tester,
    ) async {
      // Arrange
      mockPlatform.setConnectivity([ConnectivityResult.wifi]);

      await tester.pumpWidget(
        const MaterialApp(home: TestConnectivityWidget()),
      );
      await tester.pumpAndSettle();

      // Act - Remove widget to trigger dispose
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      await tester.pumpAndSettle();

      // Changing connectivity after dispose should not cause errors
      mockPlatform.setConnectivity([ConnectivityResult.none]);
      await tester.pumpAndSettle();
      // No exception means success
    });
  });
}
