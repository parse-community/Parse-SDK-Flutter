import 'package:path_provider/path_provider.dart';

class CoreStoreDirectory {
  Future<String> getDatabaseDirectory() async {
    return (await getApplicationDocumentsDirectory()).path;
  }

  Future<String?> getTempDirectory() async {
    return (await getTemporaryDirectory()).path;
  }
}
