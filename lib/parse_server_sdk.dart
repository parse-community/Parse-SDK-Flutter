import 'dart:io';

import 'package:connectivity/connectivity.dart';
import 'package:package_info/package_info.dart';

import 'parse_server_sdk_dart.dart' as sdk;

export 'parse_server_sdk_dart.dart' hide Parse;

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
