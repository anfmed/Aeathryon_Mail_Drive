-- Aethryon Drive local database (DRAFT v1). Separate file/key from Mail by design.
-- Validated with SQLite (python3 sqlite3 + FTS5). NOT yet validated under SQLCipher.
PRAGMA foreign_keys = ON;

CREATE TABLE schema_meta (key TEXT PRIMARY KEY, value TEXT NOT NULL);
INSERT INTO schema_meta VALUES ('schema_version','1');

CREATE TABLE accounts (
  id            TEXT PRIMARY KEY,
  provider_id   TEXT NOT NULL,
  display_name  TEXT NOT NULL,
  created_utc   INTEGER NOT NULL,
  sync_mode     TEXT NOT NULL DEFAULT 'manual'
                CHECK (sync_mode IN ('realtime','background','manual','scheduled')),
  wifi_only     INTEGER NOT NULL DEFAULT 0 CHECK (wifi_only IN (0,1)),
  allow_metered INTEGER NOT NULL DEFAULT 1 CHECK (allow_metered IN (0,1))
  -- NO tokens or passwords here: they live only in the OS secure store.
);

CREATE TABLE nodes (
  account_id  TEXT NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
  id          TEXT NOT NULL,
  parent_id   TEXT,
  name        TEXT NOT NULL,
  is_folder   INTEGER NOT NULL CHECK (is_folder IN (0,1)),
  size        INTEGER CHECK (size IS NULL OR size >= 0),
  modified_utc INTEGER,
  etag        TEXT,
  trashed     INTEGER NOT NULL DEFAULT 0 CHECK (trashed IN (0,1)),
  PRIMARY KEY (account_id, id)
) WITHOUT ROWID;
CREATE INDEX idx_nodes_parent ON nodes(account_id, parent_id, name);

CREATE TABLE sync_cursors (
  account_id TEXT NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
  scope      TEXT NOT NULL,
  cursor     TEXT NOT NULL,
  updated_utc INTEGER NOT NULL,
  PRIMARY KEY (account_id, scope)
);

CREATE TABLE transfers (
  id            TEXT PRIMARY KEY,
  account_id    TEXT NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
  kind          TEXT NOT NULL CHECK (kind IN ('upload','download')),
  remote_id     TEXT NOT NULL,
  local_path    TEXT NOT NULL,
  total_bytes   INTEGER NOT NULL CHECK (total_bytes >= 0),
  confirmed_offset INTEGER NOT NULL DEFAULT 0 CHECK (confirmed_offset >= 0),
  state         TEXT NOT NULL DEFAULT 'queued'
                CHECK (state IN ('queued','running','paused','waitingForNetwork','failed','completed','cancelled')),
  attempts      INTEGER NOT NULL DEFAULT 0,
  session_ref   TEXT,
  CHECK (confirmed_offset <= total_bytes)
);
CREATE INDEX idx_transfers_state ON transfers(state, account_id);

CREATE TABLE offline_pins (
  account_id TEXT NOT NULL,
  node_id    TEXT NOT NULL,
  local_path TEXT NOT NULL,
  pinned_utc INTEGER NOT NULL,
  PRIMARY KEY (account_id, node_id),
  FOREIGN KEY (account_id, node_id) REFERENCES nodes(account_id, id) ON DELETE CASCADE
);

CREATE TABLE favorites (
  account_id TEXT NOT NULL,
  node_id    TEXT NOT NULL,
  added_utc  INTEGER NOT NULL,
  PRIMARY KEY (account_id, node_id),
  FOREIGN KEY (account_id, node_id) REFERENCES nodes(account_id, id) ON DELETE CASCADE
);

-- name-only full text search (no file-content indexing by default)
CREATE VIRTUAL TABLE node_fts USING fts5(name, account_id UNINDEXED, node_id UNINDEXED, tokenize='unicode61');
