@TestOn('dart-vm')
library;

import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:path/path.dart' as path;
import 'package:flutter_test/flutter_test.dart';
import 'package:parse_server_sdk_flutter/src/storage/core_store_directory_io.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('Core store directory IO', () {
    late CoreStoreDirectory coreStoreDirectory;
    setUp(() {
      PathProviderPlatform.instance = FakePathProviderPlatform();
      coreStoreDirectory = CoreStoreDirectory();
    });

    test('getTemporaryDirectory', () async {
      final result = await path_provider.getTemporaryDirectory();
      expect(result.path, kTemporaryPath);
    });

    test('getLibraryDirectory', () async {
      final result = await path_provider.getLibraryDirectory();
      expect(result.path, libraryPath);
    });

    test('getApplicationDocumentsDirectory', () async {
      final result = await path_provider.getApplicationDocumentsDirectory();
      expect(result.path, applicationDocumentsPath);
    });

    test('defaultTargetPlatform should equals iOS', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

      final platform = defaultTargetPlatform;
      expect(platform, equals(TargetPlatform.iOS));
    });

    test('getTempDirectory() should return kTemporaryPath', () async {
      final path = await coreStoreDirectory.getTempDirectory();
      expect(path, kTemporaryPath);
    });

    group('getDatabaseDirectory()', () {
      setUp(() {
        deleteApplicationDocumentDir();
        deleteLibraryDir();
      });

      tearDown(() {
        deleteApplicationDocumentDir();
        deleteLibraryDir();
      });

      test(
          'on ios, should copy the db file if exists from the old dir path '
          '(applicationDocumentDirectory) to the new dir path (LibraryDirectory)'
          ' and the old db file should be deleted from the old dir path '
          'then return the new dir path (LibraryDirectory)', () async {
        debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

        final oldDBFile = create1MBParseDBFileInAppDocDir();
        final oldDBFileSize = oldDBFile.lengthSync();
        final dbDirectory = await coreStoreDirectory.getDatabaseDirectory();
        expect(
          oldDBFile.existsSync(),
          isFalse,
          reason: 'the old db file should be deleted from app doc dir',
        );
        expect(
          dbDirectory,
          equals(libraryPath),
          reason:
              'dbDirectory should be the new db dir path for iOS (LibraryDir)',
        );

        final newDBFilePath = path.join(
          dbDirectory,
          'parse',
          'parse.db',
        );
        final newDBFile = File(newDBFilePath);
        expect(newDBFile.existsSync(), isTrue);
        expect(
          newDBFile.lengthSync(),
          equals(oldDBFileSize),
          reason: 'the old and the new coped db file should be the same size',
        );
      });

      test(
          'on ios, if there is no db file in the old dir (applicationDocumentDirectory)'
          ' and there is db file in the new dir (LibraryDirectory) '
          'the (copy) migration should not work and so the getDatabaseDirectory()'
          'should return the new db dir path (LibraryDirectory)', () async {
        debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

        final dbFileInNewPath = create1MBParseDBFileInLibraryPath();
        final dbFileSizeBefore = dbFileInNewPath.lengthSync();
        final dbFileLastModifiedBefore = dbFileInNewPath.lastModifiedSync();
        final dbDirectory = await coreStoreDirectory.getDatabaseDirectory();
        expect(dbFileInNewPath.existsSync(), isTrue);

        final dbFileSizeAfter = dbFileInNewPath.lengthSync();
        final dbFileLastModifiedAfter = dbFileInNewPath.lastModifiedSync();
        expect(
          dbFileSizeBefore,
          equals(dbFileSizeAfter),
          reason: 'the db file should be the same',
        );
        expect(
          dbFileLastModifiedBefore.compareTo(dbFileLastModifiedAfter),
          equals(0), // 0 if this DateTime [isAtSameMomentAs] [other]
          reason: 'last modified date should not change',
        );
        expect(
          dbDirectory,
          equals(libraryPath),
          reason:
              'dbDirectory should be the new db dir path for iOS (LibraryDir)',
        );
      });

      test(
          'on any platform other than iOS, the copy migration algorithm should '
          'not run and the db file should and will remain in '
          '(applicationDocumentDirectory) and getDatabaseDirectory() should '
          'return (applicationDocumentDirectory) as db directory', () async {
        final targetPlatforms = TargetPlatform.values.toSet();
        targetPlatforms.remove(TargetPlatform.iOS);

        final dbFile = create1MBParseDBFileInAppDocDir();
        final dbFileSizeBefore = dbFile.lengthSync();
        final dbFileLastModifiedBefore = dbFile.lastModifiedSync();

        for (final platform in targetPlatforms) {
          debugDefaultTargetPlatformOverride = platform;

          final dbDirectory = await coreStoreDirectory.getDatabaseDirectory();
          expect(dbFile.existsSync(), isTrue);

          final dbFileSizeAfter = dbFile.lengthSync();
          final dbFileLastModifiedSyncAfter = dbFile.lastModifiedSync();
          expect(
            dbFileSizeBefore,
            equals(dbFileSizeAfter),
            reason: 'the db file should be the same',
          );
          expect(
            dbFileLastModifiedBefore.compareTo(dbFileLastModifiedSyncAfter),
            equals(0), // 0 if this DateTime [isAtSameMomentAs] [other]
            reason: 'last modified date should not change',
          );
          expect(
            dbDirectory,
            equals(applicationDocumentsPath),
            reason:
                'dbDirectory should point to application Documents Directory',
          );
        }
      });
    });
  });
}

File create1MBParseDBFileInAppDocDir() {
  final databaseFilePath = path.join(
    applicationDocumentsPath,
    'parse',
    'parse.db',
  );

  return generate1MBFile(databaseFilePath);
}

File create1MBParseDBFileInLibraryPath() {
  final databaseFilePath = path.join(
    libraryPath,
    'parse',
    'parse.db',
  );

  return generate1MBFile(databaseFilePath);
}

File generate1MBFile(String path) {
  final dbFile = File(path);
  dbFile.createSync(recursive: true);

  const fileSize = 1024 * 1024; // 1 MB
  final random = Random();
  final data = List.generate(fileSize, (_) => random.nextInt(256));

  dbFile.writeAsBytesSync(data, flush: true, mode: FileMode.write);
  return dbFile;
}

void deleteApplicationDocumentDir() {
  deleteDirectory(applicationDocumentsPath);
}

void deleteLibraryDir() {
  deleteDirectory(libraryPath);
}

void deleteDirectory(String path) {
  final dir = Directory(path);
  if (dir.existsSync()) {
    dir.deleteSync(recursive: true);
  }
}

const String kTemporaryPath = "temporaryPath";
final String libraryPath = path.join(path.current, 'library');
final String applicationDocumentsPath =
    path.join(path.current, 'applicationDocument');

class FakePathProviderPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  @override
  Future<String?> getTemporaryPath() async {
    return kTemporaryPath;
  }

  @override
  Future<String?> getLibraryPath() async {
    return libraryPath;
  }

  @override
  Future<String?> getApplicationDocumentsPath() async {
    return applicationDocumentsPath;
  }
}
