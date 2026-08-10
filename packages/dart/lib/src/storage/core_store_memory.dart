part of '../../parse_server_sdk.dart';

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
  Future<bool?> getBool(String key) async {
    return _data[key];
  }

  @override
  Future<double?> getDouble(String key) async {
    return _data[key];
  }

  @override
  Future<int?> getInt(String key) async {
    return _data[key];
  }

  @override
  Future<String?> getString(String key) async {
    return _data[key];
  }

  @override
  Future<List<String>?> getStringList(String key) async {
    final value = _data[key];
    if (value == null) return null;
    // Copy, so a caller mutating the result cannot reach into the store. The
    // backing map is static, so that mutation would be process-wide.
    if (value is List<String>) return List<String>.of(value);
    // A list that round-tripped through JSON comes back as List<dynamic>, so
    // returning _data[key] directly threw a CastError instead of the list.
    if (value is Iterable) return value.map((e) => e.toString()).toList();
    return null;
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
