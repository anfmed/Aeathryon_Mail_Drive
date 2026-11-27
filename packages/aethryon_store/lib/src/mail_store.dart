import 'package:mail_core/mail_core.dart';
import 'package:sqlite3/sqlite3.dart';
import 'db.dart';
import 'fts.dart';

const _bits = {'seen': 1, 'flagged': 2, 'answered': 4, 'draft': 8, 'deleted': 16};

int flagsToBits(Set<String> flags) => flags.fold(0, (a, f) => a | (_bits[f] ?? 0));
Set<String> bitsToFlags(int bits) => {for (final e in _bits.entries) if (bits & e.value != 0) e.key};

/// Persistent (encrypted) mail header cache. Message BODIES are never stored here.
class SqliteMailStore implements MailStore {
  final Database db;
  SqliteMailStore(this.db);

  void registerAccount(String id, String profileId, String address) => db.execute(
      'INSERT OR IGNORE INTO accounts(id,profile_id,address,created_utc) VALUES(?,?,?,?)',
      [id, profileId, address, DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000]);

  void removeAccount(String id) => inTransaction(db, () {
        db.execute('DELETE FROM msg_fts WHERE account_id=?', [id]);
        db.execute('DELETE FROM accounts WHERE id=?', [id]);
      });

  @override
  Future<FolderSyncState?> folderState(String accountId, String folder) async {
    final r = db.select('SELECT uid_validity,highest_modseq,last_seen_uid FROM folders WHERE account_id=? AND path=?',
        [accountId, folder]);
    if (r.isEmpty || r.first['uid_validity'] == null) return null;
    return FolderSyncState(
        uidValidity: r.first['uid_validity'] as int,
        highestModSeq: r.first['highest_modseq'] as int?,
        lastSeenUid: r.first['last_seen_uid'] as int?);
  }

  @override
  Future<void> saveFolderState(String accountId, String folder, FolderSyncState s) async {
    db.execute(
        'INSERT INTO folders(account_id,path,uid_validity,highest_modseq,last_seen_uid) VALUES(?,?,?,?,?) '
        'ON CONFLICT(account_id,path) DO UPDATE SET uid_validity=excluded.uid_validity,'
        'highest_modseq=excluded.highest_modseq,last_seen_uid=excluded.last_seen_uid',
        [accountId, folder, s.uidValidity, s.highestModSeq, s.lastSeenUid]);
  }

  @override
  Future<void> clearFolder(String accountId, String folder) async {
    inTransaction(db, () {
      db.execute('DELETE FROM msg_fts WHERE account_id=? AND folder_path=?', [accountId, folder]);
      db.execute('DELETE FROM messages WHERE account_id=? AND folder_path=?', [accountId, folder]);
      db.execute('UPDATE folders SET uid_validity=NULL,highest_modseq=NULL,last_seen_uid=NULL WHERE account_id=? AND path=?',
          [accountId, folder]);
    });
  }

  @override
  Future<void> upsertHeaders(String accountId, String folder, List<HeaderInfo> list) async {
    inTransaction(db, () {
      db.execute('INSERT OR IGNORE INTO folders(account_id,path) VALUES(?,?)', [accountId, folder]);
      for (final h in list) {
        db.execute(
            'INSERT INTO messages(account_id,folder_path,uid,message_id,in_reply_to,refs,subject,date_utc,flags) '
            'VALUES(?,?,?,?,?,?,?,?,?) ON CONFLICT(account_id,folder_path,uid) DO UPDATE SET '
            'message_id=excluded.message_id,in_reply_to=excluded.in_reply_to,refs=excluded.refs,'
            'subject=excluded.subject,date_utc=excluded.date_utc,flags=excluded.flags',
            [
              accountId, folder, h.uid, h.messageId, h.inReplyTo, h.references.join(' '), h.subject,
              h.dateUtc == null ? null : h.dateUtc!.millisecondsSinceEpoch ~/ 1000, flagsToBits(h.flags),
            ]);
        db.execute('DELETE FROM msg_fts WHERE account_id=? AND folder_path=? AND uid=?', [accountId, folder, h.uid]);
        db.execute('INSERT INTO msg_fts(subject,from_addr,account_id,folder_path,uid) VALUES(?,?,?,?,?)',
            [h.subject, '', accountId, folder, h.uid]);
      }
    });
  }

  HeaderInfo _h(Row r) => HeaderInfo(
        uid: r['uid'] as int,
        messageId: r['message_id'] as String?,
        inReplyTo: r['in_reply_to'] as String?,
        references: ((r['refs'] as String?) ?? '').split(' ').where((e) => e.isNotEmpty).toList(),
        subject: r['subject'] as String,
        dateUtc: r['date_utc'] == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch((r['date_utc'] as int) * 1000, isUtc: true),
        flags: bitsToFlags(r['flags'] as int),
      );

  static const _cols = 'uid,message_id,in_reply_to,refs,subject,date_utc,flags';

  @override
  Future<List<HeaderInfo>> headers(String accountId, String folder) async => db
      .select('SELECT $_cols FROM messages WHERE account_id=? AND folder_path=? ORDER BY uid DESC', [accountId, folder])
      .map(_h)
      .toList();

  @override
  Future<Set<int>> uids(String accountId, String folder) async => db
      .select('SELECT uid FROM messages WHERE account_id=? AND folder_path=?', [accountId, folder])
      .map((r) => r['uid'] as int)
      .toSet();

  @override
  Future<void> updateFlags(String accountId, String folder, Map<int, Set<String>> flags) async {
    inTransaction(db, () {
      flags.forEach((uid, f) => db.execute(
          'UPDATE messages SET flags=? WHERE account_id=? AND folder_path=? AND uid=?',
          [flagsToBits(f), accountId, folder, uid]));
    });
  }

  @override
  Future<void> deleteUids(String accountId, String folder, Iterable<int> uids) async {
    inTransaction(db, () {
      for (final u in uids) {
        db.execute('DELETE FROM msg_fts WHERE account_id=? AND folder_path=? AND uid=?', [accountId, folder, u]);
        db.execute('DELETE FROM messages WHERE account_id=? AND folder_path=? AND uid=?', [accountId, folder, u]);
      }
    });
  }

  List<HeaderInfo> search(String accountId, String query, {int limit = 50}) {
    final q = ftsPrefixQuery(query);
    if (q == null) return const [];
    return db
        .select(
            'SELECT m.uid,m.message_id,m.in_reply_to,m.refs,m.subject,m.date_utc,m.flags '
            'FROM msg_fts JOIN messages m ON m.account_id=msg_fts.account_id AND m.folder_path=msg_fts.folder_path AND m.uid=msg_fts.uid '
            'WHERE msg_fts MATCH ? AND m.account_id=? LIMIT ?',
            [q, accountId, limit])
        .map(_h)
        .toList();
  }
}
