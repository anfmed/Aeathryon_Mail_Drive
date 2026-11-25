import 'package:aethryon_platform/aethryon_platform.dart';
import 'package:aethryon_store/aethryon_store.dart';
import 'package:http/http.dart' as http;

class MailDb {
  final SqliteMailStore? store;
  final String? problem;
  final bool recreated;
  const MailDb({this.store, this.problem, this.recreated = false});
}

class MailServices {
  final SecureStore secureStore;
  final FilePlatform files;
  final UrlOpener opener;
  final http.Client httpClient;
  final Future<MailDb> Function() openDb;
  const MailServices({
    required this.secureStore,
    required this.files,
    required this.opener,
    required this.httpClient,
    required this.openDb,
  });
}

Future<MailDb> openProductionDb(SecureStore store, FilePlatform files) async {
  final dir = await files.appDataDir();
  final r = await openAppDatabase(
    store: store,
    namespace: 'aethryon.mail',
    path: '$dir/mail.db',
    schema: mailSchemaV1,
  );
  return MailDb(
    store: r.db == null ? null : SqliteMailStore(r.db!),
    problem: r.problem,
    recreated: r.recreated,
  );
}
