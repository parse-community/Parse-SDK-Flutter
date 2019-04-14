import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sembast/sembast.dart';
import 'package:sembast/sembast_io.dart';

Future<Database> getDB() async {
  final String dbDirectory = (await getApplicationDocumentsDirectory()).path;
  final String dbPath = join(dbDirectory, 'no_sql');
  final DatabaseFactory dbFactory = databaseFactoryIo;
  return await dbFactory.openDatabase(dbPath);
}
