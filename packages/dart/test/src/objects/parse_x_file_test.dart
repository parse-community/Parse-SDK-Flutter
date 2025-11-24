import 'package:cross_file/cross_file.dart';
import 'package:parse_server_sdk/parse_server_sdk.dart';
import 'package:test/test.dart';

import '../../test_utils.dart';

void main() {
  setUpAll(() async {
    await initializeParse();
  });

  group('Parse X File', () {
    test('should return a correct name', () {
      XFile file = XFile('/sdcard/aa/aa.jpg');
      final parseFile = ParseXFile(file, name: 'bb.jpg');
      expect(parseFile.name, 'bb.jpg');
    });

    test('should handle files with various extensions', () {
      // Test various file extensions
      final testCases = [
        'image.jpg',
        'photo.png',
        'document.pdf',
        'myfile.txt',
        'archive.zip',
      ];

      for (final filename in testCases) {
        XFile file = XFile('/path/to/$filename');
        final parseFile = ParseXFile(file, name: filename);
        // Verify that the name is set correctly
        expect(parseFile.name, filename);
      }
    });

    test('should handle files without extensions', () {
      // Test files without extensions
      final testCases = ['image', 'file', 'document'];

      for (final filename in testCases) {
        XFile file = XFile('/path/to/$filename');
        final parseFile = ParseXFile(file, name: filename);
        // Verify that the name is set correctly
        expect(parseFile.name, filename);
      }
    });
  });
}
