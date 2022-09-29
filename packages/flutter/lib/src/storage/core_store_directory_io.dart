import 'dart:io' show Platform;

import 'package:path_provider/path_provider.dart' as path_provider;

class CoreStoreDirectory {
  Future<String> getDatabaseDirectory() async {
   if (Platform.isIOS) {
        return (await path_provider.getLibraryDirectory()).path;
    } else {
        return (await path_provider.getApplicationDocumentsDirectory()).path;
    }
  }

  Future<String?> getTempDirectory() async {
    return (await path_provider.getTemporaryDirectory()).path;
  }
}
