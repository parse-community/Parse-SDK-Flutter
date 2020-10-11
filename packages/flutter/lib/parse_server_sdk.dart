library flutter_parse_sdk_flutter;

import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:connectivity/connectivity.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:package_info/package_info.dart';
import 'package:parse_server_sdk/parse_server_sdk.dart' as sdk;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:sembast/sembast.dart';
import 'package:shared_preferences/shared_preferences.dart';

export 'package:parse_server_sdk/parse_server_sdk.dart'
    hide Parse, CoreStoreSembastImp;

part 'src/storage/core_store_sp_impl.dart';
part 'src/utils/parse_live_list.dart';

class Parse extends sdk.Parse
    with WidgetsBindingObserver
    implements sdk.ParseConnectivityProvider {
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
    String locale,
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
    Stream<void> appResumedStream,
  }) async {
    if (!sdk.parseIsWeb &&
        (appName == null || appVersion == null || appPackageName == null)) {
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
      locale: locale ?? sdk.parseIsWeb
          ? ui.window.locale.toString()
          : Platform.localeName,
      liveQueryUrl: liveQueryUrl,
      clientKey: clientKey,
      masterKey: masterKey,
      sessionId: sessionId,
      autoSendSessionId: autoSendSessionId,
      securityContext: securityContext,
      coreStore: coreStore ??
          await CoreStoreSharedPrefsImp.getInstance(password: masterKey),
      registeredSubClassMap: registeredSubClassMap,
      parseUserConstructor: parseUserConstructor,
      parseFileConstructor: parseFileConstructor,
      liveListRetryIntervals: liveListRetryIntervals,
      connectivityProvider: connectivityProvider ?? this,
      fileDirectory: fileDirectory ??
          (!sdk.parseIsWeb ? (await getTemporaryDirectory()).path : null),
      appResumedStream: appResumedStream ?? _appResumedStreamController.stream,
    );
  }

  final StreamController<void> _appResumedStreamController =
      StreamController<void>();

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

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _appResumedStreamController.sink.add(null);
  }
}

class CoreStoreSembastImp implements sdk.CoreStoreSembastImp {
  CoreStoreSembastImp._();

  static sdk.CoreStoreSembastImp _sembastImp;

  static Future<sdk.CoreStore> getInstance(
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
