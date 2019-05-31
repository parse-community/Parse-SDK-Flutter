part of flutter_parse_sdk;

abstract class CoreStore {
  Future<bool> containsKey(String key);

  Future<dynamic> get(String key);

  Future<bool> getBool(String key);

  Future<int> getInt(String key);

  Future<double> getDouble(String key);

  Future<String> getString(String key);

  Future<List<String>> getStringList(String key);

  Future<dynamic> setBool(String key, bool value);

  Future<dynamic> setInt(String key, int value);

  Future<dynamic> setDouble(String key, double value);

  Future<dynamic> setString(String key, String value);

  Future<dynamic> setStringList(String key, List<String> values);

  Future<dynamic> remove(String key);

  Future<dynamic> clear();
}
