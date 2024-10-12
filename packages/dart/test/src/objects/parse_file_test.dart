import 'dart:io';
import 'package:parse_server_sdk/parse_server_sdk.dart';
import 'package:test/test.dart';

import '../../test_utils.dart';

void main() {
  setUpAll(() async {
    await initializeParse();
  });

  group('Parse X File', () {
    test('should return a correct name', () {
      // arrange
      File file = File('/sdcard/aa/aa.jpg');

      // act
      final parseFile = ParseFile(file, name: 'bb.jpg');

      // assert
      expect(parseFile.name, 'bb.jpg');
    });
  });
}
