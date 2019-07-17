part of flutter_parse_sdk;

class CoreStoreSembastImp implements CoreStore {
  CoreStoreSembastImp._internal(this._store);

  static CoreStoreSembastImp _instance;

  static Future<CoreStore> getInstance(
      {DatabaseFactory factory, String password = 'flutter_sdk'}) async {
    if (_instance == null) {
      factory ??= databaseFactoryIo;
      final SembastCodec codec = getXXTeaSembastCodec(password: password);
      String dbDirectory = '';
      if (Platform.isIOS || Platform.isAndroid)
        dbDirectory = (await getApplicationDocumentsDirectory()).path;
      final String dbPath = path.join('$dbDirectory/parse', 'parse.db');
      final Database db = await factory.openDatabase(dbPath, codec: codec);
      _instance = CoreStoreSembastImp._internal(db);
    }

    return _instance;
  }

  Database _store;

  @override
  Future<bool> clear() {
    return _store.clear();
  }

  @override
  Future<bool> containsKey(String key) {
    return _store.containsKey(key);
  }

  @override
  Future<dynamic> get(String key) {
    return _store.get(key);
  }

  @override
  Future<bool> getBool(String key) async {
    final bool storedItem = await _store.get(key);
    return storedItem;
  }

  @override
  Future<double> getDouble(String key) async {
    final double storedItem = await _store.get(key);
    return storedItem;
  }

  @override
  Future<int> getInt(String key) async {
    final int storedItem = await _store.get(key);
    return storedItem;
  }

  @override
  Future<String> getString(String key) async {
    final String storedItem = await _store.get(key);
    return storedItem;
  }

  @override
  Future<List<String>> getStringList(String key) async {
    final List<String> storedItem = await _store.get(key);
    return storedItem;
  }

  @override
  Future<void> remove(String key) {
    return _store.delete(key);
  }

  @override
  Future<void> setBool(String key, bool value) {
    return _store.put(value, key);
  }

  @override
  Future<void> setDouble(String key, double value) {
    return _store.put(value, key);
  }

  @override
  Future<void> setInt(String key, int value) {
    return _store.put(value, key);
  }

  @override
  Future<void> setString(String key, String value) {
    return _store.put(value, key);
  }

  @override
  Future<void> setStringList(String key, List<String> values) {
    return _store.put(values, key);
  }
}
