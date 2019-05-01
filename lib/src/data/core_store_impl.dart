part of flutter_parse_sdk;

class CoreStoreImp implements CoreStore {
  CoreStoreImp._internal(this._store);
  static CoreStoreImp _instance;
  static Future<CoreStoreImp> getInstance(
      {DatabaseFactory factory, String password = 'flutter_sdk'}) async {
    if (_instance == null) {
      factory ??= databaseFactoryIo;
      final SembastCodec codec = getXXTeaSembastCodec(password: password);
      String dbDirectory = '';
      if (Platform.isIOS || Platform.isAndroid)
        dbDirectory = (await getApplicationDocumentsDirectory()).path;
      final String dbPath = path.join('$dbDirectory+/parse', 'parse.db');
      final Database db = await factory.openDatabase(dbPath, codec: codec);
      _instance = CoreStoreImp._internal(db);
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
  Future get(String key) {
    return _store.get(key);
  }

  @override
  Future<bool> getBool(String key) async {
    return await _store.get(key) as bool;
  }

  @override
  Future<double> getDouble(String key) async {
    return await _store.get(key) as double;
  }

  @override
  Future<int> getInt(String key) async {
    return await _store.get(key) as int;
  }

  @override
  Future<String> getString(String key) async {
    return await _store.get(key) as String;
  }

  @override
  Future<List<String>> getStringList(String key) async {
    return await _store.get(key) as List<String>;
  }

  @override
  Future remove(String key) {
    return _store.delete(key);
  }

  @override
  Future setBool(String key, bool value) {
    return _store.put(value, key);
  }

  @override
  Future setDouble(String key, double value) {
    return _store.put(value, key);
  }

  @override
  Future setInt(String key, int value) {
    return _store.put(value, key);
  }

  @override
  Future setString(String key, String value) {
    return _store.put(value, key);
  }

  @override
  Future setStringList(String key, List<String> values) {
    return _store.put(values, key);
  }
}
