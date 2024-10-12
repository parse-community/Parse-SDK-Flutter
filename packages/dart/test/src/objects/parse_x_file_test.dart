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
  });
}
