# Aethryon — Phase 1–5 repository
দুটি স্বতন্ত্র অ্যাপ (Aethryon Drive, Aethryon Mail) + shared foundation। Web নয়।
**অবস্থা: লেখা হয়েছে; CI-তে এখনো সবুজ প্রমাণিত নয়।** → `docs/KNOWN_LIMITATIONS.md` · **বাকি phase: `docs/ROADMAP_REMAINING.md`**
**আপনার করণীয় তালিকা: `docs/USER_ACTION_CHECKLIST.md`**
## কাঠামো
- `packages/` — shared: `aethryon_capability/net/log/auth/platform/design`; `drive_core`, `mail_core` (pure Dart); isolated: `mail_imap`, `aethryon_secure_store_flutter`
- `apps/` — `drive_app`, `mail_app` (demo-ডেটায় চলমান UI; platform-ফোল্ডার CI তৈরি করে)
- `schema/` — Drive ও Mail-এর আলাদা SQL schema (SQLite-এ যাচাইকৃত)
- `tools/` — CI স্ক্রিপ্ট ও `bench_sqlite.py`; `.github/workflows/` — `format` (auto), `build-apps` (check→build; Android+Windows, Linux ঐচ্ছিক), `ci-core` (ঐচ্ছিক পূর্ণ CI), `release`
- `docs/` — সিদ্ধান্ত, পরিকল্পনা, যাচাই, রিপোর্ট, গাইড; `docs/phase0/` — Phase 0 নথি
## নিয়ম
কোনো secret/keystore/token commit করবেন না। কোনো লাইসেন্স এখনো নির্ধারিত নয় (`NOTICE.md`)।
