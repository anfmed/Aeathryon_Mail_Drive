#!/usr/bin/env python3
"""Measures P-07 / P-08 style numbers for the REAL schemas on THIS machine.
Limits (printed in the report): plain SQLite (no SQLCipher), desktop-class CPU,
synthetic English-like data. NOT a device measurement."""
import random, sqlite3, statistics, time, json, sys

random.seed(42)
VOCAB = [f"w{i:04d}" for i in range(3000)] + ["quarterly", "report", "invoice", "lunch", "meeting", "budget"]

def load(path):
    c = sqlite3.connect(":memory:")
    c.executescript(open(path, encoding="utf-8").read())
    return c

def timeit(fn, n=60):
    ts = []
    for _ in range(n):
        t = time.perf_counter(); fn(); ts.append((time.perf_counter() - t) * 1000)
    ts.sort()
    return {"p50_ms": round(statistics.median(ts), 3), "p95_ms": round(ts[int(len(ts) * 0.95) - 1], 3)}

res = {"sqlite_version": sqlite3.sqlite_version}

# ---------- Mail: 500k headers (list) + 100k FTS ----------
m = load("schema/mail_schema.sql")
m.execute("insert into accounts(id,profile_id,address,created_utc) values('a','icloud','u@x.y',1)")
m.execute("insert into folders(account_id,path,role) values('a','INBOX','inbox')")
N = 500_000
t0 = time.perf_counter()
rows = ((  'a', 'INBOX', i, f"<{i}@x>", " ".join(random.choices(VOCAB, k=5)), f"s{i%5000}@x.y", 1_700_000_000 + i * 60) for i in range(1, N + 1))
m.executemany("insert into messages(account_id,folder_path,uid,message_id,subject,from_addr,date_utc) values(?,?,?,?,?,?,?)", rows)
m.commit()
res["mail_insert_500k_s"] = round(time.perf_counter() - t0, 1)

t0 = time.perf_counter()
m.execute("insert into msg_fts(subject,from_addr,account_id,folder_path,uid) select subject,from_addr,account_id,folder_path,uid from messages where uid<=100000")
m.commit()
res["mail_fts_build_100k_s"] = round(time.perf_counter() - t0, 1)

res["P08_inbox_first_page_500k"] = timeit(lambda: m.execute(
    "select uid,subject,date_utc from messages where account_id='a' and folder_path='INBOX' order by date_utc desc limit 50").fetchall())
terms = ["quarterly*", "report*", "w0042*", "invoice*", "lunch*", "w2999*"]
res["P07_mail_fts_prefix_100k"] = timeit(lambda: m.execute(
    "select uid from msg_fts where msg_fts match ? limit 50", (random.choice(terms),)).fetchall())
res["P07_mail_fts_two_terms_100k"] = timeit(lambda: m.execute(
    "select uid from msg_fts where msg_fts match 'quarterly* report*' limit 50").fetchall())

# ---------- Drive: 500k nodes + name FTS ----------
d = load("schema/drive_schema.sql")
d.execute("insert into accounts(id,provider_id,display_name,created_utc) values('a','nextcloud','x',1)")
t0 = time.perf_counter()
rows = (('a', f"/f{i%1000}/n{i}", f"/f{i%1000}", " ".join(random.choices(VOCAB, k=2)) + f"_{i}.txt", 0, i % 100000, 1_700_000_000 + i) for i in range(1, N + 1))
d.executemany("insert into nodes(account_id,id,parent_id,name,is_folder,size,modified_utc) values(?,?,?,?,?,?,?)", rows)
d.commit()
res["drive_insert_500k_s"] = round(time.perf_counter() - t0, 1)
t0 = time.perf_counter()
d.execute("insert into node_fts(name,account_id,node_id) select name,account_id,id from nodes")
d.commit()
res["drive_fts_build_500k_s"] = round(time.perf_counter() - t0, 1)
res["P07_drive_fts_prefix_500k"] = timeit(lambda: d.execute(
    "select node_id from node_fts where node_fts match ? limit 50", (random.choice(["quarterly*", "report*", "w0042*", "w2999*"]),)).fetchall())
res["drive_folder_listing_500_children"] = timeit(lambda: d.execute(
    "select id,name,size from nodes where account_id='a' and parent_id='/f7' order by name limit 200").fetchall())

print(json.dumps(res, indent=2))
json.dump(res, open("docs/bench_sqlite_result.json", "w"), indent=2)

# pass/fail against PROPOSED budgets (desktop-class machine only)
budget = {"P08_inbox_first_page_500k": 500, "P07_mail_fts_prefix_100k": 200,
          "P07_mail_fts_two_terms_100k": 200, "P07_drive_fts_prefix_500k": 200}
bad = [k for k, v in budget.items() if res[k]["p95_ms"] > v]
print("BUDGET CHECK (p95, this machine):", "within budget" if not bad else f"EXCEEDED: {bad}")
sys.exit(0)
