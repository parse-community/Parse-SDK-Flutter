import 'dart:io';

import 'package:path/path.dart' as path;

class CoreStoreDirectory {
  Future<String> getDatabaseDirectory(dynamic pathProvider) async {
    if (Platform.isIOS) {
      await _migrateDBFileToLibraryDirectory(pathProvider);

      return (await pathProvider.getLibraryDirectory()).path;
    }

    return (await pathProvider.getApplicationDocumentsDirectory()).path;
  }

  /// Migrate SDK internal database file on iOS, see:
  /// https://github.com/parse-community/Parse-SDK-Flutter/issues/791
  /// TODO: Remove this migration algorithm in the future.
  Future<void> _migrateDBFileToLibraryDirectory(dynamic pathProvider) async {
    final dbFile = await _getDBFileIfExistsInAppDocDir(pathProvider);

    if (dbFile != null) {
      await _moveDatabaseFileToLibraryDirectory(dbFile, pathProvider);
    }
  }

  Future<File?> _getDBFileIfExistsInAppDocDir(dynamic pathProvider) async {
    final appDocDirPath =
        (await pathProvider.getApplicationDocumentsDirectory()).path;

    final databaseFilePath = path.join(
      appDocDirPath,
      'parse',
      'parse.db',
    );

    final dbFile = File(databaseFilePath);

    if (await dbFile.exists()) {
      return dbFile;
    }

    return null;
  }

  Future<void> _moveDatabaseFileToLibraryDirectory(
      File databaseFileToMove, dynamic pathProvider) async {
    final libraryDirectoryPath =
        (await pathProvider.getLibraryDirectory()).path;

    final libraryDirectoryDatabaseFilePath = path.join(
      libraryDirectoryPath,
      'parse',
      'parse.db',
    );

    await File(libraryDirectoryDatabaseFilePath).create(recursive: true);
    await databaseFileToMove.rename(libraryDirectoryDatabaseFilePath);
  }

  Future<String> getTempDirectory(dynamic pathProvider) async {
    return (await pathProvider.getTemporaryDirectory()).path;
  }
}
