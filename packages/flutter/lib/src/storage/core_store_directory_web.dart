/// A storage directories for web
class CoreStoreDirectory {
  /// Returns the library directory path for the database file
  Future<String> getDatabaseDirectory() async {
    return '';
  }

  /// Returns the path to the application temporary directory.
  Future<String?> getTempDirectory() async {
    return '';
  }
}
