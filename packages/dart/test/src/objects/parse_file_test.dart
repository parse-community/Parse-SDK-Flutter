import 'dart:io';
import 'package:parse_server_sdk/parse_server_sdk.dart';
import 'package:test/test.dart';
import 'package:path/path.dart' as path;

import '../../test_utils.dart';

void main() {
  setUpAll(() async {
    await initializeParse();
  });

  group('Parse X File', () {
    test('should return a correct name', () {
      File file = File('/sdcard/aa/aa.jpg');
      final parseFile = ParseFile(file, name: 'bb.jpg');
      expect(parseFile.name, 'bb.jpg');
    });

    test('should detect file extension correctly for files with extensions',
        () {
      // Test various file extensions
      final testCases = [
        'image.jpg',
        'photo.png',
        'document.pdf',
        'myfile.txt',
        'archive.zip',
      ];

      for (final filename in testCases) {
        File file = File('/path/to/$filename');
        final parseFile = ParseFile(file, name: filename);
        // Verify that the extension is detected
        expect(path.extension(parseFile.name).isNotEmpty, true,
            reason: '$filename should have an extension');
      }
    });

    test(
        'should detect missing extension correctly for files without extensions',
        () {
      // Test files without extensions
      final testCases = [
        'image',
        'file',
        'document',
      ];

      for (final filename in testCases) {
        File file = File('/path/to/$filename');
        final parseFile = ParseFile(file, name: filename);
        // Verify that no extension is detected
        expect(path.extension(parseFile.name).isEmpty, true,
            reason: '$filename should not have an extension');
      }
    });
  });
}
