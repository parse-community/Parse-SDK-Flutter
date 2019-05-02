part of flutter_parse_sdk;

class SharedPreferencesCoreStore implements CoreStore {
  SharedPreferencesCoreStore(FutureOr<SharedPreferences> sharedPreference)
      : _sharedPreferencesFuture = Future.value(sharedPreference);

  Future<SharedPreferences> _sharedPreferencesFuture;

  @override
  Future<bool> clear() async {
    final SharedPreferences sharedPreferences = await _sharedPreferencesFuture;
    final bool result = await sharedPreferences.clear();
    return result;
  }

  @override
  Future get(String key) =>
      _sharedPreferencesFuture.then<dynamic>((shared) => shared.get(key));

  @override
  Future<bool> getBool(String key) =>
      _sharedPreferencesFuture.then((shared) => shared.getBool(key));

  @override
  Future<double> getDouble(String key) =>
      _sharedPreferencesFuture.then((shared) => shared.getDouble(key));

  @override
  Future<int> getInt(String key) =>
      _sharedPreferencesFuture.then((shared) => shared.getInt(key));

  @override
  Future<String> getString(String key) =>
      _sharedPreferencesFuture.then((shared) => shared.getString(key));

  @override
  Future<List<String>> getStringList(String key) =>
      _sharedPreferencesFuture.then((shared) => shared.getStringList(key));

  @override
  Future<bool> remove(String key) =>
      _sharedPreferencesFuture.then((shared) => shared.remove(key));

  @override
  Future<bool> setBool(String key, bool value) =>
      _sharedPreferencesFuture.then((shared) => shared.setBool(key, value));

  @override
  Future<bool> setDouble(String key, double value) =>
      _sharedPreferencesFuture.then((shared) => shared.setDouble(key, value));

  @override
  Future<bool> setInt(String key, int value) =>
      _sharedPreferencesFuture.then((shared) => shared.setInt(key, value));

  @override
  Future<bool> setString(String key, String value) =>
      _sharedPreferencesFuture.then((shared) => shared.setString(key, value));

  @override
  Future<bool> setStringList(String key, List<String> values) =>
      _sharedPreferencesFuture
          .then((shared) => shared.setStringList(key, values));

  @override
  Future<bool> containsKey(String key) =>
      _sharedPreferencesFuture.then((shared) => shared.containsKey(key));
}
