part of flutter_parse_sdk;

// ignore_for_file: deprecated_member_use
class CoreStoreSembastImp implements CoreStore {
  CoreStoreSembastImp._internal(this._db, this._store);

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
      _instance = CoreStoreSembastImp._internal(db, StoreRef.main());
    }

    return _instance;
  }

  final StoreRef _store;
  final Database _db;

  @override
  Future<bool> clear() {
    return _store.drop(_db);
  }

  @override
  Future<bool> containsKey(String key) {
    return _store.record(key).exists(_db);
  }

  @override
  Future<dynamic> get(String key)async {
    return await _store.record(key).get(_db);
  }

  @override
  Future<bool> getBool(String key) async {
    final bool storedItem = await _store.record(key).get(_db);
    return storedItem;
  }

  @override
  Future<double> getDouble(String key) async {
    final double storedItem = await _store.record(key).get(_db);
    return storedItem;
  }

  @override
  Future<int> getInt(String key) async {
    final int storedItem = await _store.record(key).get(_db);
    return storedItem;
  }

  @override
  Future<String> getString(String key) async {
    final String storedItem = await _store.record(key).get(_db);
    return storedItem;
  }

  @override
  Future<List<String>> getStringList(String key) async {
    final List<String> storedItem = await _store.record(key).get(_db);
    return storedItem;
  }

  @override
  Future<void> remove(String key)async {
    return await _store.record(key).delete(_db);
  }

  @override
  Future<void> setBool(String key, bool value) async{
    return await _store.record(key).put(_db,  value);
//    return _store.put(value, key);
  }

  @override
  Future<void> setDouble(String key, double value) async {
    return await _store.record(key).put(_db,  value);
//    return _store.put(value, key);
  }

  @override
  Future<void> setInt(String key, int value) async {
    return await _store.record(key).put(_db,  value);
//    return _store.put(value, key);
  }

  @override
  Future<void> setString(String key, String value) async {
    return await _store.record(key).put(_db,  value);
//    return _store.put(value, key);
  }

  @override
  Future<void> setStringList(String key, List<String> values) async {
    return await _store.record(key).put(_db,  values);
//    return _store.put(values, key);
  }
}
