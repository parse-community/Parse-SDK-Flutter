import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:path/path.dart' as path;

class CoreStoreDirectory {
  Future<String> getDatabaseDirectory() async {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      await _migrateDBFileToLibraryDirectory();

      return (await path_provider.getLibraryDirectory()).path;
    }

    return (await path_provider.getApplicationDocumentsDirectory()).path;
  }

  /// Why do we need this migration on iOS? see:
  /// https://github.com/parse-community/Parse-SDK-Flutter/issues/791
  ///
  /// TODO: remove this migration algorithm after at least two major releases
  ///
  /// the release when this migration added is `3.1.14`
  Future<void> _migrateDBFileToLibraryDirectory() async {
    final dbFile = await _getDBFileIfExistsInAppDocDir();

    if (dbFile != null) {
      await _moveDatabaseFileToLibraryDirectory(dbFile);
    }
  }

  Future<File?> _getDBFileIfExistsInAppDocDir() async {
    final appDocDirPath =
        (await path_provider.getApplicationDocumentsDirectory()).path;

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
    File databaseFileToMove,
  ) async {
    final libraryDirectoryPath =
        (await path_provider.getLibraryDirectory()).path;

    final libraryDirectoryDatabaseFilePath = path.join(
      libraryDirectoryPath,
      'parse',
      'parse.db',
    );

    await File(libraryDirectoryDatabaseFilePath).create(recursive: true);
    await databaseFileToMove.rename(libraryDirectoryDatabaseFilePath);
  }

  Future<String> getTempDirectory() async {
    return (await path_provider.getTemporaryDirectory()).path;
  }
}
