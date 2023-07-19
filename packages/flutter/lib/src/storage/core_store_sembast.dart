part of flutter_parse_sdk_flutter;

/// provides database operations using Sembast
class CoreStoreSembast implements sdk.CoreStoreSembastImp {
  CoreStoreSembast._();

  static sdk.CoreStore? _sembastImp;

  static Future<CoreStoreSembast> getInstance(
      {DatabaseFactory? factory, String? password}) async {
    _sembastImp ??= await sdk.CoreStoreSembastImp.getInstance(
        await _dbDirectory(),
        factory: factory,
        password: password);
    return CoreStoreSembast._();
  }

  /// Returns the database directory.
  static Future<String> _dbDirectory() async {
    String dbDirectory = await CoreStoreDirectory().getDatabaseDirectory();
    return path.join('$dbDirectory/parse', 'parse.db');
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
