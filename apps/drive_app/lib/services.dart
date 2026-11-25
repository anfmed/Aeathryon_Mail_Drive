import 'package:aethryon_platform/aethryon_platform.dart';
import 'package:aethryon_store/aethryon_store.dart';
import 'package:drive_core/drive_core.dart';
import 'package:http/http.dart' as http;

import 'errors.dart';

class DriveDb {
  final DriveStore? store;
  final String? problem;
  final bool recreated;
  const DriveDb({this.store, this.problem, this.recreated = false});
}

class DriveServices {
  final SecureStore secureStore;
  final FilePlatform files;
  final UrlOpener opener;
  final http.Client httpClient;
  final Future<DriveDb> Function() openDb;
  late final TransferController transfers = TransferController(
    files,
    explain: explainError,
  );
  DriveServices({
    required this.secureStore,
    required this.files,
    required this.opener,
    required this.httpClient,
    required this.openDb,
  });
}

Future<DriveDb> openProductionDb(SecureStore store, FilePlatform files) async {
  final dir = await files.appDataDir();
  final r = await openAppDatabase(
    store: store,
    namespace: 'aethryon.drive',
    path: '$dir/drive.db',
    schema: driveSchemaV1,
  );
  return DriveDb(
    store: r.db == null ? null : DriveStore(r.db!),
    problem: r.problem,
    recreated: r.recreated,
  );
}
