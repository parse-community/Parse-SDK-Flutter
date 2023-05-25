import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:path/path.dart' as path;

/// A storage directories
class CoreStoreDirectory {
  /// Returns the library directory path for the database file on iOS, or
  /// the documents directory path for other platforms. If the application is
  /// running on iOS, this function also migrates the database file from the
  /// documents directory to the library directory. This is done to prevent
  /// issues with Parse SDK Flutter on iOS.
  Future<String> getDatabaseDirectory() async {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      await _migrateDBFileToLibraryDirectory();

      return (await path_provider.getLibraryDirectory()).path;
    }

    return (await path_provider.getApplicationDocumentsDirectory()).path;
  }

  /// Returns the database directory.
  Future<String> dbDirectory() async {
    String dbDirectory = '';
    dbDirectory = await CoreStoreDirectory().getDatabaseDirectory();
    return path.join('$dbDirectory/parse', 'parse.db');
  }

  /// A migration algorithm for the internal SDK database file on iOS. This
  /// function moves the database file from the documents directory to the
  /// library directory to prevent issues with Parse SDK Flutter on iOS.
  /// Migrate SDK internal database file on iOS, see:
  /// https://github.com/parse-community/Parse-SDK-Flutter/issues/791
  /// TODO: Remove this migration algorithm in the future.
  Future<void> _migrateDBFileToLibraryDirectory() async {
    final dbFile = await _getDBFileIfExistsInAppDocDir();

    if (dbFile != null) {
      await _moveDatabaseFileToLibraryDirectory(dbFile);
    }
  }

  /// Returns the database file from the application documents directory if it
  /// exists, otherwise returns null.
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

  /// Moves the given database file to the library directory.
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

  /// Returns the path to the application temporary directory.
  Future<String> getTempDirectory() async {
    return (await path_provider.getTemporaryDirectory()).path;
  }
}
