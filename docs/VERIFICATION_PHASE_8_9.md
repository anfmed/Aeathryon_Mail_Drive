# VERIFICATION_PHASE_8_9
তারিখ: ২০২৬-১১-১০ | পদ্ধতি: আসল CI-লগ বিশ্লেষণ + Python/yaml/regex স্ক্রিপ্ট; **নতুন Dart কোড compile/test নয়**।
| # | যাচাই | ফল | প্রমাণ |
|---|---|---|---|
| V60 | লাল-ফিক্স: loopback port আগেই সংরক্ষণ (কারণ আসল CI-লগের পর্যবেক্ষণ + `HttpServer.port` আচরণ থেকে অনুমিত) | PASS (নির্ণয়) / UNVERIFIED (ফিক্স চালানো হয়নি) | CI-লগ: ২১ পাস/১ ফেল |
| V61 | store-এর **হুবহু SQL** (upsert, diff-delete, FTS-join, cascade, isolation) Python-এ | PASS (SQL) / UNVERIFIED (Dart) | স্ক্রিপ্ট |
| V62 | `splitSql` স্ট্যাটমেন্ট-সংখ্যা = CREATE/INSERT/PRAGMA-সংখ্যা; FTS-query-নির্মাণ (hostile ইনপুট, বাংলা) | PASS (Python port) / UNVERIFIED (Dart) | স্ক্রিপ্ট |
| V63 | `schemas.dart` = `schema/*.sql` (স্বয়ংক্রিয় freshness-চেক CI-তে) | PASS | `validate_schema.py` |
| V64 | সব package/app CI-স্ক্রিপ্টে আচ্ছাদিত; import↔pubspec; path-dependency; barrel-export; ১৬ pubspec; ২টি workflow YAML | PASS | স্ক্রিপ্ট |
| V65 | `aethryon_store`, flag-sync, TransferController, file_io, self-test, OAuthTokenSource, PollScheduler, OAuth-UI, দুই অ্যাপ (~৩৫ নতুন টেস্ট) | UNVERIFIED | Dart; কখনো চালানো হয়নি |
| V66 | `mail_imap` নতুন call (UID-search/flags/body/xoauth2) | UNVERIFIED | `UNVERIFIED-API` |
| V67 | অ্যাপ-pubspec `hooks: sqlite3mc` সব platform-এ build হয় | UNVERIFIED | CI-build বাকি |
| V68 | এনক্রিপশন সত্যিই কাজ করে (ফাইল plaintext নয়, ভুল key ব্যর্থ, FTS5) | UNVERIFIED | `db-spike` ফল আসেনি |
| V69 | Release-CI (label/backup/build-number/apksigner) | UNVERIFIED | CI-রান বাকি |
| V70 | নিরাপত্তা self-review ও নথি (Release, Privacy-খসড়া, Store-খসড়া) | PASS (লেখা) | docs/ |
| V71 | secret-কমিট/Web/Apple-job অনুপস্থিত | PASS | grep |
| V72 | ডিভাইস performance, TalkBack-পরীক্ষা, আসল-provider, নিরাপত্তা-নিরীক্ষা, Google/Box/pCloud adapter, background sync, attachment | অনুপস্থিত (কারণসহ স্থগিত) | KNOWN_LIMITATIONS |

**সারসংক্ষেপ:** PASS 4 · PARTIAL 3 · UNVERIFIED 5 · অনুপস্থিত 1 · FAIL ০ (মোট 13)।
**অবস্থা:** Phase ৮–৯ = `WRITTEN — NOT YET BUILD-VERIFIED`।
