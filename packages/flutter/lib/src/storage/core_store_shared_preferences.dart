part of flutter_parse_sdk_flutter;

/// A class that implements the `sdk.CoreStore` interface using `SharedPreferences`.
class CoreStoreSharedPreferences implements sdk.CoreStore {
  CoreStoreSharedPreferences._internal(this._store);

  static CoreStoreSharedPreferences? _instance;

  /// Returns a new instance of `CoreStoreSharedPrefsImp`.
  ///
  /// If no instance exists, this function creates a new instance of
  /// `SharedPreferences` and passes it as a parameter to the constructor of
  /// `CoreStoreSharedPrefsImp`.
  static Future<CoreStoreSharedPreferences> getInstance(
      {SharedPreferences? store}) async {
    if (_instance == null) {
      store ??= await SharedPreferences.getInstance();
      _instance = CoreStoreSharedPreferences._internal(store);
    }

    return _instance!;
  }

  final SharedPreferences _store;

  @override
  Future<bool> clear() {
    return _store.clear();
  }

  @override
  Future<bool> containsKey(String key) async {
    return _store.containsKey(key);
  }

  @override
  Future<dynamic> get(String key) async {
    return _store.get(key);
  }

  @override
  Future<bool?> getBool(String key) async {
    return _store.getBool(key);
  }

  @override
  Future<double?> getDouble(String key) async {
    return _store.getDouble(key);
  }

  @override
  Future<int?> getInt(String key) async {
    return _store.getInt(key);
  }

  @override
  Future<String?> getString(String key) async {
    return _store.getString(key);
  }

  @override
  Future<List<String>?> getStringList(String key) async {
    return _store.getStringList(key);
  }

  @override
  Future<bool> remove(String key) async {
    return _store.remove(key);
  }

  @override
  Future<void> setBool(String key, bool value) {
    return _store.setBool(key, value);
  }

  @override
  Future<void> setDouble(String key, double value) {
    return _store.setDouble(key, value);
  }

  @override
  Future<void> setInt(String key, int value) {
    return _store.setInt(key, value);
  }

  @override
  Future<void> setString(String key, String value) {
    return _store.setString(key, value);
  }

  @override
  Future<void> setStringList(String key, List<String> values) {
    return _store.setStringList(key, values);
  }
}
