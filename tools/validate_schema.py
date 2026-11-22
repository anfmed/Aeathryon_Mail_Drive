#!/usr/bin/env python3
"""Loads both SQL schemas into in-memory SQLite and runs constraint/FTS5 checks."""
import sqlite3, sys

def load(path):
    c = sqlite3.connect(":memory:")
    c.executescript(open(path, encoding="utf-8").read())
    return c

def must_reject(conn, sql, label):
    try:
        conn.execute(sql)
    except sqlite3.IntegrityError:
        return
    sys.exit(f"FAIL: accepted invalid row ({label})")

d = load("schema/drive_schema.sql")
d.execute("insert into accounts(id,provider_id,display_name,created_utc) values('a','nextcloud','x',1)")
d.execute("insert into node_fts(name,account_id,node_id) values('report 2026','a','/r')")
assert d.execute("select count(*) from node_fts where node_fts match 'report*'").fetchone()[0] == 1
must_reject(d, "insert into nodes(account_id,id,name,is_folder) values('zz','/z','z',0)", "drive FK")
d.execute("delete from accounts where id='a'")

m = load("schema/mail_schema.sql")
m.execute("insert into accounts(id,profile_id,address,created_utc) values('m','icloud','u@x.y',1)")
m.execute("insert into folders(account_id,path,role) values('m','INBOX','inbox')")
must_reject(m, "insert into messages(account_id,folder_path,uid) values('m','NOPE',1)", "mail orphan")
for name, c in (("drive", d), ("mail", m)):
    cols = [r[1].lower() for (t,) in c.execute("select name from sqlite_master where type='table'") for r in c.execute(f"pragma table_info('{t}')")]
    bad = {"token", "password", "secret", "refresh_token", "access_token"} & set(cols)
    if bad:
        sys.exit(f"FAIL: secret-like column in {name}: {bad}")
print("schemas OK")
