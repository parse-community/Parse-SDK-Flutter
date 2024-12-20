library;

import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:path/path.dart' as path;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:parse_server_sdk/parse_server_sdk.dart' as sdk;
import 'package:parse_server_sdk_flutter/src/storage/core_store_directory_io.dart'
    if (dart.library.html) 'package:parse_server_sdk_flutter/src/storage/core_store_directory_web.dart';
import 'package:sembast/sembast.dart';
import 'package:shared_preferences/shared_preferences.dart';

export 'package:parse_server_sdk/parse_server_sdk.dart'
    hide Parse, CoreStoreSembastImp;

part 'src/storage/core_store_shared_preferences.dart';

part 'src/storage/core_store_sembast.dart';

part 'src/utils/parse_live_grid.dart';

part 'src/utils/parse_live_list.dart';

part 'src/notification/parse_notification.dart';

part 'src/push//parse_push.dart';

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
    if (appName == null || appVersion == null || appPackageName == null) {
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
      locale: locale ??
          (sdk.parseIsWeb
              ? PlatformDispatcher.instance.locale.toString()
              : Platform.localeName),
      liveQueryUrl: liveQueryUrl,
      clientKey: clientKey,
      masterKey: masterKey,
      sessionId: sessionId,
      autoSendSessionId: autoSendSessionId,
      securityContext: securityContext,
      coreStore: coreStore ?? await CoreStoreSharedPreferences.getInstance(),
      registeredSubClassMap: registeredSubClassMap,
      parseUserConstructor: parseUserConstructor,
      parseFileConstructor: parseFileConstructor,
      liveListRetryIntervals: liveListRetryIntervals,
      connectivityProvider: connectivityProvider ?? this,
      fileDirectory:
          fileDirectory ?? (await CoreStoreDirectory().getTempDirectory()),
      appResumedStream: appResumedStream ?? _appResumedStreamController.stream,
      clientCreator: clientCreator,
    ) as Parse;
  }

  final StreamController<void> _appResumedStreamController =
      StreamController<void>();

  @override
  Future<sdk.ParseConnectivityResult> checkConnectivity() async {
    List<ConnectivityResult> list = await Connectivity().checkConnectivity();

    if (list.contains(ConnectivityResult.wifi)) {
      return sdk.ParseConnectivityResult.wifi;
    } else if (list.contains(ConnectivityResult.mobile)) {
      return sdk.ParseConnectivityResult.mobile;
    } else {
      return sdk.ParseConnectivityResult.none;
    }
  }

  @override
  Stream<sdk.ParseConnectivityResult> get connectivityStream {
    return Connectivity().onConnectivityChanged.map(
      (List<ConnectivityResult> event) {
        if (event.contains(ConnectivityResult.wifi)) {
          return sdk.ParseConnectivityResult.wifi;
        } else if (event.contains(ConnectivityResult.mobile)) {
          return sdk.ParseConnectivityResult.mobile;
        } else {
          return sdk.ParseConnectivityResult.none;
        }
      },
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _appResumedStreamController.sink.add(null);
    }

    if (state == AppLifecycleState.paused) {
      _appResumedStreamController.close();
    }
  }
}
