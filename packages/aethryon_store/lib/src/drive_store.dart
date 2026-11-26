import 'package:drive_core/drive_core.dart';
import 'package:sqlite3/sqlite3.dart';

import 'db.dart';
import 'fts.dart';

/// Offline cache of folder listings + local name search. Never holds credentials.
class DriveStore {
  final Database db;
  DriveStore(this.db);

  int _now() => DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;

  void ensureAccount(String id, String providerId, String displayName) =>
      db.execute(
        'INSERT OR IGNORE INTO accounts(id,provider_id,display_name,created_utc) VALUES(?,?,?,?)',
        [id, providerId, displayName, _now()],
      );

  void saveChildren(String accountId, String parentId, List<RemoteNode> nodes) {
    inTransaction(db, () {
      final existing = db
          .select('SELECT id FROM nodes WHERE account_id=? AND parent_id=?', [
            accountId,
            parentId,
          ])
          .map((r) => r['id'] as String)
          .toSet();
      final keep = <String>{};
      for (final n in nodes) {
        db.execute(
          'INSERT INTO nodes(account_id,id,parent_id,name,is_folder,size,modified_utc,etag) VALUES(?,?,?,?,?,?,?,?) '
          'ON CONFLICT(account_id,id) DO UPDATE SET parent_id=excluded.parent_id,name=excluded.name,'
          'is_folder=excluded.is_folder,size=excluded.size,modified_utc=excluded.modified_utc,etag=excluded.etag',
          [
            accountId,
            n.id,
            parentId,
            n.name,
            n.isFolder ? 1 : 0,
            n.size,
            n.modifiedUtc == null
                ? null
                : n.modifiedUtc!.millisecondsSinceEpoch ~/ 1000,
            n.etag,
          ],
        );
        db.execute('DELETE FROM node_fts WHERE account_id=? AND node_id=?', [
          accountId,
          n.id,
        ]);
        db.execute(
          'INSERT INTO node_fts(name,account_id,node_id) VALUES(?,?,?)',
          [n.name, accountId, n.id],
        );
        keep.add(n.id);
      }
      for (final id in existing.difference(keep)) {
        db.execute('DELETE FROM node_fts WHERE account_id=? AND node_id=?', [
          accountId,
          id,
        ]);
        db.execute('DELETE FROM nodes WHERE account_id=? AND id=?', [
          accountId,
          id,
        ]);
      }
    });
  }

  RemoteNode _node(Row r) => RemoteNode(
    accountId: r['account_id'] as String,
    id: r['id'] as String,
    parentId: r['parent_id'] as String?,
    name: r['name'] as String,
    isFolder: (r['is_folder'] as int) == 1,
    size: r['size'] as int?,
    modifiedUtc: r['modified_utc'] == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(
            (r['modified_utc'] as int) * 1000,
            isUtc: true,
          ),
    etag: r['etag'] as String?,
  );

  static const _cols =
      'account_id,id,parent_id,name,is_folder,size,modified_utc,etag';

  List<RemoteNode> children(String accountId, String parentId) => db
      .select('SELECT $_cols FROM nodes WHERE account_id=? AND parent_id=?', [
        accountId,
        parentId,
      ])
      .map(_node)
      .toList();

  bool hasListing(String accountId, String parentId) => db.select(
    'SELECT 1 FROM nodes WHERE account_id=? AND parent_id=? LIMIT 1',
    [accountId, parentId],
  ).isNotEmpty;

  List<RemoteNode> search(String query, {String? accountId, int limit = 50}) {
    final q = ftsPrefixQuery(query);
    if (q == null) return const [];
    final sql =
        'SELECT n.account_id,n.id,n.parent_id,n.name,n.is_folder,n.size,n.modified_utc,n.etag '
        'FROM node_fts JOIN nodes n ON n.account_id=node_fts.account_id AND n.id=node_fts.node_id '
        'WHERE node_fts MATCH ?${accountId != null ? ' AND n.account_id=?' : ''} LIMIT ?';
    return db
        .select(sql, [q, if (accountId != null) accountId, limit])
        .map(_node)
        .toList();
  }

  void removeAccount(String accountId) {
    inTransaction(db, () {
      db.execute('DELETE FROM node_fts WHERE account_id=?', [accountId]);
      db.execute('DELETE FROM accounts WHERE id=?', [accountId]);
    });
  }

  void addFavorite(String accountId, String nodeId) => db.execute(
    'INSERT OR IGNORE INTO favorites(account_id,node_id,added_utc) VALUES(?,?,?)',
    [accountId, nodeId, _now()],
  );

  Set<String> favorites(String accountId) => db
      .select('SELECT node_id FROM favorites WHERE account_id=?', [accountId])
      .map((r) => r['node_id'] as String)
      .toSet();
}
