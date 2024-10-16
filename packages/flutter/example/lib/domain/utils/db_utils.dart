import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:sembast/sembast_io.dart';

Future<dynamic> getDB() async {
  final String dbDirectory = (await getApplicationDocumentsDirectory()).path;
  final String dbPath = path.join(dbDirectory, 'no_sql');
  final dynamic dbFactory = databaseFactoryIo;
  return await dbFactory.openDatabase(dbPath);
}
