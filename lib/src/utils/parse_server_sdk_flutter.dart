
import 'dart:async';
import 'dart:io';
import 'package:parse_server_sdk/parse_server_sdk.dart' as sdk;
import 'package:path/path.dart' as path;
import 'package:sembast/sembast.dart';

import '../../parse_server_sdk.dart';
import '../storage/core_store_directory_io.dart';
export 'package:parse_server_sdk/parse_server_sdk.dart'
    hide Parse, CoreStoreSembastImp;

class Parse extends sdk.Parse
    implements sdk.ParseConnectivityProvider {
  /// To initialize Parse Server in your application
  ///
  /// This should be initialized in MyApp() creation
  ///
  /// ```
  /// Parse().initialize(
  ///        "PARSE_APP_ID",
  ///        "https://parse.myaddress.com/parse/,
  ///        clientKey: "asd23rjh234r234r234r",
  ///        debug: true,
  ///        liveQuery: true);
  /// ```
  /// [appName], [appVersion] and [appPackageName] are automatically set on Android and IOS, if they are not defined. You should provide a value on web.
  /// [fileDirectory] is not used on web
  @override
  Future<Parse> initialize(
      String appId,
      String serverUrl, {
        bool debug = false,
        String? appName,
        String? appVersion,
        String? appPackageName,
        String? locale,
        String? liveQueryUrl,
        String? clientKey,
        String? masterKey,
        String? sessionId,
        bool autoSendSessionId = true,
        SecurityContext? securityContext,
        sdk.CoreStore? coreStore,
        Map<String, sdk.ParseObjectConstructor>? registeredSubClassMap,
        sdk.ParseUserConstructor? parseUserConstructor,
        sdk.ParseFileConstructor? parseFileConstructor,
        List<int>? liveListRetryIntervals,
        sdk.ParseConnectivityProvider? connectivityProvider,
        String? fileDirectory,
        Stream<void>? appResumedStream,
        sdk.ParseClientCreator? clientCreator,
      }) async {


    return await super.initialize(
      appId,
      serverUrl,
      debug: debug,
      appName: appName,
      appVersion: appVersion,
      appPackageName: appPackageName,
      locale: locale,
      liveQueryUrl: liveQueryUrl,
      clientKey: clientKey,
      masterKey: masterKey,
      sessionId: sessionId,
      autoSendSessionId: autoSendSessionId,
      securityContext: securityContext,
      coreStore: coreStore,
      registeredSubClassMap: registeredSubClassMap,
      parseUserConstructor: parseUserConstructor,
      parseFileConstructor: parseFileConstructor,
      liveListRetryIntervals: liveListRetryIntervals,
      connectivityProvider: connectivityProvider ?? this,
      fileDirectory:
      fileDirectory,
      appResumedStream: appResumedStream ?? _appResumedStreamController.stream,
      clientCreator: clientCreator,
    ) as Parse;
  }


  Future<Parse> initializeFlutter(
      String appId,
      String serverUrl, {
        bool debug = false,
        String? appName,
        String? appVersion,
        String? appPackageName,
        String? locale,
        String? liveQueryUrl,
        String? clientKey,
        String? masterKey,
        String? sessionId,
        bool autoSendSessionId = true,
        SecurityContext? securityContext,
        Map<String, ParseObjectConstructor>? registeredSubClassMap,
        ParseUserConstructor? parseUserConstructor,
        ParseFileConstructor? parseFileConstructor,
        List<int>? liveListRetryIntervals,
        ParseConnectivityProvider? connectivityProvider,
        String? fileDirectory,
        Stream<void>? appResumedStream,
        ParseClientCreator? clientCreator,
        required dynamic packageInfo,
        required dynamic ui,
        required dynamic connectivity,
        required dynamic pathProvider,
        required sdk.CoreStore? coreStore,
      }) async {

    if (appName == null || appVersion == null || appPackageName == null) {

      appName ??= packageInfo.appName;
      appVersion ??= packageInfo.version;
      appPackageName ??= packageInfo.packageName;
    }

    this.connectivity=connectivity;
    this.pathProvider=pathProvider;

    initialize(
      appId,
      serverUrl,
      debug: debug,
      appName: appName,
      appVersion: appVersion,
      appPackageName: appPackageName,
      locale: locale ??
          (sdk.parseIsWeb ? ui.window.locale.toString() : Platform.localeName),
      liveQueryUrl: liveQueryUrl,
      masterKey: masterKey,
      clientKey: clientKey,
      sessionId: sessionId,
      autoSendSessionId: autoSendSessionId,
      securityContext: securityContext,
      registeredSubClassMap: registeredSubClassMap,
      parseUserConstructor: parseUserConstructor,
      parseFileConstructor: parseFileConstructor,
      liveListRetryIntervals: liveListRetryIntervals,
      connectivityProvider: connectivityProvider ?? this,
      fileDirectory: fileDirectory,
      appResumedStream: appResumedStream ?? _appResumedStreamController.stream,
      clientCreator: clientCreator,
    );


    return this;
  }


  final StreamController<void> _appResumedStreamController =
  StreamController<void>();
  late dynamic connectivity;
  late dynamic pathProvider;
  @override
  Future<sdk.ParseConnectivityResult> checkConnectivity() async {
    switch (await connectivity.checkConnectivity().name) {
      case "wifi":
        return sdk.ParseConnectivityResult.wifi;
      case "mobile":
        return sdk.ParseConnectivityResult.mobile;
      case "none":
        return sdk.ParseConnectivityResult.none;
      default:
        return sdk.ParseConnectivityResult.wifi;
    }
  }

  @override
  Stream<sdk.ParseConnectivityResult> get connectivityStream {
    return connectivity.onConnectivityChanged.map((dynamic event) {
      switch (event) {
        case "wifi":
          return sdk.ParseConnectivityResult.wifi;
        case "mobile":
          return sdk.ParseConnectivityResult.mobile;
        default:
          return sdk.ParseConnectivityResult.none;
      }
    });
  }
}

Future<String> dbDirectory(pathProvider) async {
  String dbDirectory = '';
  dbDirectory = await CoreStoreDirectory().getDatabaseDirectory(pathProvider);
  return path.join('$dbDirectory/parse', 'parse.db');
}

class CoreStoreSembastImp implements sdk.CoreStoreSembastImp {
  CoreStoreSembastImp._();

  static sdk.CoreStore? _sembastImp;

  static Future<CoreStoreSembastImp> getInstance(pathProvider,
      {DatabaseFactory? factory, String? password}) async {
    _sembastImp ??= await sdk.CoreStoreSembastImp.getInstance(
        await dbDirectory(pathProvider),
        factory: factory,
        password: password);
    return CoreStoreSembastImp._();
  }

  @override
  Future<bool> clear() async {
    await _sembastImp!.clear();
    return true;
  }

  @override
  Future<bool> containsKey(String key) => _sembastImp!.containsKey(key);

  @override
  Future<dynamic> get(String key) => _sembastImp!.get(key);

  @override
  Future<bool?> getBool(String key) => _sembastImp!.getBool(key);

  @override
  Future<double?> getDouble(String key) => _sembastImp!.getDouble(key);

  @override
  Future<int?> getInt(String key) => _sembastImp!.getInt(key);

  @override
  Future<String?> getString(String key) => _sembastImp!.getString(key);

  @override
  Future<List<String>?> getStringList(String key) =>
      _sembastImp!.getStringList(key);

  @override
  Future<void> remove(String key) => _sembastImp!.remove(key);

  @override
  Future<void> setBool(String key, bool value) =>
      _sembastImp!.setBool(key, value);

  @override
  Future<void> setDouble(String key, double value) =>
      _sembastImp!.setDouble(key, value);

  @override
  Future<void> setInt(String key, int value) => _sembastImp!.setInt(key, value);

  @override
  Future<void> setString(String key, String value) =>
      _sembastImp!.setString(key, value);

  @override
  Future<void> setStringList(String key, List<String> values) =>
      _sembastImp!.setStringList(key, values);
}