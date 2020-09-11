part of flutter_parse_sdk;

class CoreStoreMemoryImp implements CoreStore {
  static Map<String, dynamic> _data = <String, dynamic>{};

  @override
  Future<void> clear() async {
    _data = <String, dynamic>{};
  }

  @override
  Future<bool> containsKey(String key) async {
    return _data.containsKey(key);
  }

  @override
  Future<dynamic> get(String key) async {
    return _data[key];
  }

  @override
  Future<bool> getBool(String key) async {
    return _data[key];
  }

  @override
  Future<double> getDouble(String key) async {
    return _data[key];
  }

  @override
  Future<int> getInt(String key) async {
    return _data[key];
  }

  @override
  Future<String> getString(String key) async {
    return _data[key];
  }

  @override
  Future<List<String>> getStringList(String key) async {
    return _data[key];
  }

  @override
  Future<dynamic> remove(String key) async {
    return _data.remove(key);
  }

  @override
  Future<void> setBool(String key, bool value) async {
    _data[key] = value;
  }

  @override
  Future<void> setDouble(String key, double value) async {
    _data[key] = value;
  }

  @override
  Future<void> setInt(String key, int value) async {
    _data[key] = value;
  }

  @override
  Future<void> setString(String key, String value) async {
    _data[key] = value;
  }

  @override
  Future<void> setStringList(String key, List<String> values) async {
    _data[key] = values;
  }
}
