part of flutter_parse_sdk;

abstract class CoreStore {
  Future<bool> containsKey(String key);

  Future<dynamic> get(String key);

  Future<bool> getBool(String key);

  Future<int> getInt(String key);

  Future<double> getDouble(String key);

  Future<String> getString(String key);

  Future<List<String>> getStringList(String key);

  Future setBool(String key, bool value);

  Future setInt(String key, int value);

  Future setDouble(String key, double value);

  Future setString(String key, String value);

  Future setStringList(String key, List<String> values);

  Future remove(String key);

  Future clear();
}
