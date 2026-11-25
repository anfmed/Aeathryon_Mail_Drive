# Aethryon — Phase 1–9 repository
দুটি স্বতন্ত্র অ্যাপ (Aethryon Drive, Aethryon Mail) + shared foundation। Web নয়।
**অবস্থা: লেখা হয়েছে; CI-তে এখনো সবুজ প্রমাণিত নয়।** → `docs/KNOWN_LIMITATIONS.md` · **বাকি phase: `docs/ROADMAP_REMAINING.md`**
**আপনার করণীয় তালিকা: `docs/USER_ACTION_CHECKLIST.md`**
## কাঠামো
- `packages/` — shared: `aethryon_capability/net/log/auth/platform/design`; `drive_core`, `mail_core` (pure Dart); isolated: `mail_imap`, `aethryon_secure_store_flutter`
- `apps/` — `drive_app`, `mail_app` (এনক্রিপ্টেড offline-cache, ট্রান্সফার, OAuth, flag-sync; platform-ফোল্ডার CI তৈরি করে)
- `spikes/` — এনক্রিপ্টেড-DB পরীক্ষা (`db_sqlite3mc`, `db_sqlcipher`) — অ্যাপের অংশ নয়
- `schema/` — Drive ও Mail-এর আলাদা SQL schema (SQLite-এ যাচাইকৃত)
- `tools/` — CI স্ক্রিপ্ট ও `bench_sqlite.py`; `.github/workflows/` — মাত্র ২টি: `format` (প্রতিটি push-এ নিজে) ও `ci` (হাতে: check→build; Android+Windows, ঐচ্ছিক Linux/extra/draft-release)
- `docs/` — সিদ্ধান্ত, পরিকল্পনা, যাচাই, রিপোর্ট, গাইড; `docs/phase0/` — Phase 0 নথি
## নিয়ম
কোনো secret/keystore/token commit করবেন না। কোনো লাইসেন্স এখনো নির্ধারিত নয় (`NOTICE.md`)।
