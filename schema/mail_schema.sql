-- Aethryon Mail local database (DRAFT v1). Separate file/key from Drive by design.
-- Validated with SQLite (python3 sqlite3 + FTS5). NOT yet validated under SQLCipher.
PRAGMA foreign_keys = ON;

CREATE TABLE schema_meta (key TEXT PRIMARY KEY, value TEXT NOT NULL);
INSERT INTO schema_meta VALUES ('schema_version','1');

CREATE TABLE accounts (
  id            TEXT PRIMARY KEY,
  profile_id    TEXT NOT NULL,
  address       TEXT NOT NULL,
  created_utc   INTEGER NOT NULL,
  sync_mode     TEXT NOT NULL DEFAULT 'manual'
                CHECK (sync_mode IN ('realtime','background','manual','scheduled')),
  wifi_only     INTEGER NOT NULL DEFAULT 0 CHECK (wifi_only IN (0,1))
  -- NO credentials here (OS secure store only).
);

CREATE TABLE folders (
  account_id   TEXT NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
  path         TEXT NOT NULL,
  role         TEXT CHECK (role IN ('inbox','sent','drafts','archive','trash','spam','other')),
  uid_validity INTEGER,
  highest_modseq INTEGER,
  last_seen_uid INTEGER,
  PRIMARY KEY (account_id, path)
);

CREATE TABLE messages (
  account_id  TEXT NOT NULL,
  folder_path TEXT NOT NULL,
  uid         INTEGER NOT NULL,
  message_id  TEXT,
  in_reply_to TEXT,
  refs        TEXT,                 -- space-separated Message-IDs
  thread_id   TEXT,
  subject     TEXT NOT NULL DEFAULT '',
  from_addr   TEXT,
  date_utc    INTEGER,
  flags       INTEGER NOT NULL DEFAULT 0,   -- bitmask: 1 seen, 2 flagged, 4 answered, 8 draft, 16 deleted
  body_state  TEXT NOT NULL DEFAULT 'none' CHECK (body_state IN ('none','partial','full')),
  PRIMARY KEY (account_id, folder_path, uid),
  FOREIGN KEY (account_id, folder_path) REFERENCES folders(account_id, path) ON DELETE CASCADE
) WITHOUT ROWID;
CREATE INDEX idx_messages_list   ON messages(account_id, folder_path, date_utc DESC);
CREATE INDEX idx_messages_thread ON messages(account_id, thread_id);
CREATE INDEX idx_messages_msgid  ON messages(account_id, message_id);

CREATE TABLE outbox (
  id          TEXT PRIMARY KEY,
  account_id  TEXT NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
  state       TEXT NOT NULL DEFAULT 'pending'
              CHECK (state IN ('pending','sending','sent','failedRetryable','failedPermanent')),
  attempts    INTEGER NOT NULL DEFAULT 0,
  next_attempt_utc INTEGER,
  rfc822      BLOB NOT NULL
);
CREATE INDEX idx_outbox_due ON outbox(state, next_attempt_utc);

CREATE VIRTUAL TABLE msg_fts USING fts5(subject, from_addr, account_id UNINDEXED, folder_path UNINDEXED, uid UNINDEXED, tokenize='unicode61');
