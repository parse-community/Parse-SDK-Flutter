import 'dart:io';

import 'package:connectivity/connectivity.dart';
import 'package:package_info/package_info.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:sembast/sembast.dart';

import 'parse_server_sdk_dart.dart' as sdk;

export 'parse_server_sdk_dart.dart' hide Parse, CoreStoreSembastImp;

class Parse extends sdk.Parse implements sdk.ParseConnectivityProvider {
  /// To initialize Parse Server in your application
  ///
  /// This should be initialized in MyApp() creation
  ///
  /// ```
  /// Parse().initialize(
  ///        "PARSE_APP_ID",
  ///        "https://parse.myaddress.com/parse/,
  ///        masterKey: "asd23rjh234r234r234r",
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
    String appName,
    String appVersion,
    String appPackageName,
    String liveQueryUrl,
    String clientKey,
    String masterKey,
    String sessionId,
    bool autoSendSessionId,
    SecurityContext securityContext,
    sdk.CoreStore coreStore,
    Map<String, sdk.ParseObjectConstructor> registeredSubClassMap,
    sdk.ParseUserConstructor parseUserConstructor,
    sdk.ParseFileConstructor parseFileConstructor,
    List<int> liveListRetryIntervals,
    sdk.ParseConnectivityProvider connectivityProvider,
    String fileDirectory,
  }) async {
    if (!sdk.parseIsWeb) {
      final PackageInfo packageInfo = await PackageInfo.fromPlatform();
      appName ??= packageInfo.appName;
      appVersion ??= packageInfo.version;
      appPackageName ??= packageInfo.packageName;
    }

    return await super.initialize(
      appId,
      serverUrl,
      debug: debug,
      appName: appName,
      appVersion: appVersion,
      appPackageName: appPackageName,
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
      connectivityProvider: connectivityProvider ?? this,
      fileDirectory: fileDirectory ?? (await getTemporaryDirectory()).path,
    );
  }

  @override
  Future<sdk.ParseConnectivityResult> checkConnectivity() async {
    //Connectivity works differently on web
    if (!sdk.parseIsWeb) {
      switch (await Connectivity().checkConnectivity()) {
        case ConnectivityResult.wifi:
          return sdk.ParseConnectivityResult.wifi;
        case ConnectivityResult.mobile:
          return sdk.ParseConnectivityResult.mobile;
        case ConnectivityResult.none:
          return sdk.ParseConnectivityResult.none;
      }
    }
    return sdk.ParseConnectivityResult.wifi;
  }

  @override
  Stream<sdk.ParseConnectivityResult> get connectivityStream {
    return Connectivity().onConnectivityChanged.map((ConnectivityResult event) {
      switch (event) {
        case ConnectivityResult.wifi:
          return sdk.ParseConnectivityResult.wifi;
        case ConnectivityResult.mobile:
          return sdk.ParseConnectivityResult.mobile;
        default:
          return sdk.ParseConnectivityResult.none;
      }
    });
  }
}

class CoreStoreSembastImp implements sdk.CoreStoreSembastImp {
  CoreStoreSembastImp._();

  static sdk.CoreStoreSembastImp _sembastImp;

  static Future<sdk.CoreStore> getInstance(String dbPath,
      {DatabaseFactory factory, String password}) async {
    if (_sembastImp == null) {
      String dbDirectory = '';
      if (!sdk.parseIsWeb &&
          (Platform.isIOS || Platform.isAndroid || Platform.isMacOS))
        dbDirectory = (await getApplicationDocumentsDirectory()).path;
      final String dbPath = path.join('$dbDirectory/parse', 'parse.db');
      _sembastImp ??= await sdk.CoreStoreSembastImp.getInstance(dbPath,
          factory: factory, password: password);
    }
    return CoreStoreSembastImp._();
  }

  @override
  Future<bool> clear() => _sembastImp.clear();

  @override
  Future<bool> containsKey(String key) => _sembastImp.containsKey(key);

  @override
  Future<dynamic> get(String key) => _sembastImp.get(key);

  @override
  Future<bool> getBool(String key) => _sembastImp.getBool(key);

  @override
  Future<double> getDouble(String key) => _sembastImp.getDouble(key);

  @override
  Future<int> getInt(String key) => _sembastImp.getInt(key);

  @override
  Future<String> getString(String key) => _sembastImp.getString(key);

  @override
  Future<List<String>> getStringList(String key) =>
      _sembastImp.getStringList(key);

  @override
  Future<void> remove(String key) => _sembastImp.remove(key);

  @override
  Future<void> setBool(String key, bool value) =>
      _sembastImp.setBool(key, value);

  @override
  Future<void> setDouble(String key, double value) =>
      _sembastImp.setDouble(key, value);

  @override
  Future<void> setInt(String key, int value) => _sembastImp.setInt(key, value);

  @override
  Future<void> setString(String key, String value) =>
      _sembastImp.setString(key, value);

  @override
  Future<void> setStringList(String key, List<String> values) =>
      _sembastImp.setStringList(key, values);
}
