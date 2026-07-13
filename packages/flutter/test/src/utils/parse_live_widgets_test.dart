import 'dart:async';
import 'package:connectivity_plus_platform_interface/connectivity_plus_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
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

/// Test ParseObject class
class TestObject extends ParseObject implements ParseCloneable {
  TestObject() : super('TestObject');
  TestObject.clone() : this();

  @override
  TestObject clone(Map<String, dynamic> map) =>
      TestObject.clone()..fromJson(map);

  static TestObject fromJsonStatic(Map<String, dynamic> json) {
    return TestObject()..fromJson(json);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockConnectivityPlatform mockPlatform;

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

  setUp(() {
    mockPlatform = MockConnectivityPlatform();
    // Start in offline mode to avoid network calls and timers
    mockPlatform.setConnectivity([ConnectivityResult.none]);
    ConnectivityPlatform.instance = mockPlatform;
  });

  tearDown(() {
    mockPlatform.dispose();
  });

  group('ParseLiveListWidget', () {
    testWidgets('should create widget with required parameters', (
      WidgetTester tester,
    ) async {
      // Arrange
      final query = QueryBuilder<TestObject>(TestObject());

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ParseLiveListWidget<TestObject>(
              query: query,
              fromJson: TestObject.fromJsonStatic,
            ),
          ),
        ),
      );

      // Assert - widget should be created without throwing
      expect(find.byType(ParseLiveListWidget<TestObject>), findsOneWidget);
    });

    testWidgets('should display loading element initially', (
      WidgetTester tester,
    ) async {
      // Arrange
      final query = QueryBuilder<TestObject>(TestObject());
      const loadingWidget = Center(child: CircularProgressIndicator());

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ParseLiveListWidget<TestObject>(
              query: query,
              fromJson: TestObject.fromJsonStatic,
              listLoadingElement: loadingWidget,
            ),
          ),
        ),
      );

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should accept optional parameters', (
      WidgetTester tester,
    ) async {
      // Arrange
      final query = QueryBuilder<TestObject>(TestObject());
      final scrollController = ScrollController();

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ParseLiveListWidget<TestObject>(
              query: query,
              fromJson: TestObject.fromJsonStatic,
              pagination: true,
              pageSize: 10,
              lazyLoading: true,
              shrinkWrap: true,
              reverse: false,
              offlineMode: true,
              scrollController: scrollController,
              scrollDirection: Axis.vertical,
              padding: const EdgeInsets.all(8),
              duration: const Duration(milliseconds: 500),
            ),
          ),
        ),
      );

      // Assert
      expect(find.byType(ParseLiveListWidget<TestObject>), findsOneWidget);
    });
  });

  group('ParseLiveGridWidget', () {
    testWidgets('should create widget with required parameters', (
      WidgetTester tester,
    ) async {
      // Arrange
      final query = QueryBuilder<TestObject>(TestObject());

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ParseLiveGridWidget<TestObject>(
              query: query,
              fromJson: TestObject.fromJsonStatic,
              crossAxisCount: 2,
            ),
          ),
        ),
      );

      // Assert
      expect(find.byType(ParseLiveGridWidget<TestObject>), findsOneWidget);
    });

    testWidgets('should display loading element initially', (
      WidgetTester tester,
    ) async {
      // Arrange
      final query = QueryBuilder<TestObject>(TestObject());
      const loadingWidget = Center(child: CircularProgressIndicator());

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ParseLiveGridWidget<TestObject>(
              query: query,
              fromJson: TestObject.fromJsonStatic,
              crossAxisCount: 2,
              gridLoadingElement: loadingWidget,
            ),
          ),
        ),
      );

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  group('ParseLiveSliverListWidget', () {
    testWidgets('should create widget with required parameters', (
      WidgetTester tester,
    ) async {
      // Arrange
      final query = QueryBuilder<TestObject>(TestObject());

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomScrollView(
              slivers: [
                ParseLiveSliverListWidget<TestObject>(
                  query: query,
                  fromJson: TestObject.fromJsonStatic,
                ),
              ],
            ),
          ),
        ),
      );

      // Assert
      expect(
        find.byType(ParseLiveSliverListWidget<TestObject>),
        findsOneWidget,
      );
    });

    testWidgets('should display loading element initially', (
      WidgetTester tester,
    ) async {
      // Arrange
      final query = QueryBuilder<TestObject>(TestObject());
      const loadingWidget = Center(child: CircularProgressIndicator());

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomScrollView(
              slivers: [
                ParseLiveSliverListWidget<TestObject>(
                  query: query,
                  fromJson: TestObject.fromJsonStatic,
                  listLoadingElement: loadingWidget,
                ),
              ],
            ),
          ),
        ),
      );

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  group('ParseLiveSliverGridWidget', () {
    testWidgets('should create widget with required parameters', (
      WidgetTester tester,
    ) async {
      // Arrange
      final query = QueryBuilder<TestObject>(TestObject());

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomScrollView(
              slivers: [
                ParseLiveSliverGridWidget<TestObject>(
                  query: query,
                  fromJson: TestObject.fromJsonStatic,
                  crossAxisCount: 2,
                ),
              ],
            ),
          ),
        ),
      );

      // Assert
      expect(
        find.byType(ParseLiveSliverGridWidget<TestObject>),
        findsOneWidget,
      );
    });
  });

  group('ParseLiveListPageView', () {
    testWidgets('should create widget with required parameters', (
      WidgetTester tester,
    ) async {
      // Arrange
      final query = QueryBuilder<TestObject>(TestObject());

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ParseLiveListPageView<TestObject>(
              query: query,
              fromJson: TestObject.fromJsonStatic,
            ),
          ),
        ),
      );

      // Assert
      expect(find.byType(ParseLiveListPageView<TestObject>), findsOneWidget);
    });

    testWidgets('should display loading element initially', (
      WidgetTester tester,
    ) async {
      // Arrange
      final query = QueryBuilder<TestObject>(TestObject());
      const loadingWidget = Center(child: CircularProgressIndicator());

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ParseLiveListPageView<TestObject>(
              query: query,
              fromJson: TestObject.fromJsonStatic,
              listLoadingElement: loadingWidget,
            ),
          ),
        ),
      );

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should accept optional parameters', (
      WidgetTester tester,
    ) async {
      // Arrange
      final query = QueryBuilder<TestObject>(TestObject());
      final pageController = PageController();

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ParseLiveListPageView<TestObject>(
              query: query,
              fromJson: TestObject.fromJsonStatic,
              pagination: true,
              pageSize: 10,
              offlineMode: true,
              pageController: pageController,
              scrollDirection: Axis.horizontal,
              scrollPhysics: const BouncingScrollPhysics(),
            ),
          ),
        ),
      );

      // Assert
      expect(find.byType(ParseLiveListPageView<TestObject>), findsOneWidget);
    });
  });

  group('LoadMoreStatus enum', () {
    test('should have all expected values', () {
      expect(LoadMoreStatus.values, contains(LoadMoreStatus.idle));
      expect(LoadMoreStatus.values, contains(LoadMoreStatus.loading));
      expect(LoadMoreStatus.values, contains(LoadMoreStatus.noMoreData));
      expect(LoadMoreStatus.values, contains(LoadMoreStatus.error));
    });
  });
}
