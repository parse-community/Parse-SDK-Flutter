part of flutter_parse_sdk;

abstract class AppInfo {
  Future<String> getLanguage();

  Future<String> getAppName();

  Future<String> getPackageName();

  Future<String> getVersion();

  Future<String> getBuildNumber();
}
