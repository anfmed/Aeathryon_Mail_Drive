# VERIFICATION_PHASE_4_5
তারিখ: ২০২৬-১১-১০ | পদ্ধতি: Python/yaml/regex স্ক্রিপ্ট ও স্বাধীন algorithm-port; **Dart compile/test নয়**।
| # | যাচাই | ফল | প্রমাণ |
|---|---|---|---|
| V20 | Mail sync-service যুক্তি (প্রথম/ইনক্রিমেন্টাল/UIDVALIDITY/খালি) | PASS (Python port) / UNVERIFIED (Dart) | port + assert |
| V21 | Plain-text extractor — ৬টি প্রত্যাশা | PASS (Python port) / UNVERIFIED (Dart) | port + assert |
| V22 | Drive memory-adapter, sort, BrowseState, formatBytes | UNVERIFIED | Dart; স্বাধীন port নেই |
| V23 | OAuth URL/exchange/refresh/state, loopback, SecureTokenStore | UNVERIFIED | Dart; (PKCE vector আলাদা PASS, Phase ১–৩) |
| V24 | SQLite-স্তরের গতি (৫ লক্ষ সারি) মাপা হয়েছে | PASS (মাপা; সীমা: in-memory/desktop/SQLCipher নয়) | bench_sqlite_result.json |
| V25 | দুই অ্যাপের UI + ৭ widget test | UNVERIFIED | কখনো চালানো হয়নি |
| V26 | `mail_imap` (blind) | UNVERIFIED | `UNVERIFIED-API` মার্কার |
| V27 | CI/release YAML বৈধ (৩ workflow) | PASS | yaml.safe_load |
| V28 | import↔pubspec ও barrel-export (সব package+app) | PASS | স্ক্রিপ্ট |
| V29 | secret/Web-build অনুপস্থিত | PASS | grep |
| V30 | Checklist/গাইড/পরিমাপ-প্রোটোকল/স্টোর-তালিকা নথি | PASS (লেখা) | ফাইল |
| V31 | Device performance P-01…P-14 | UNVERIFIED | অ-মাপা |
| V32 | IMAP/secure-store/OAuth অ্যাপে wired; মোবাইল OAuth; flag-sync; এনক্রিপ্টেড স্থানীয় সংরক্ষণ | অনুপস্থিত (ইচ্ছাকৃত স্থগিত) | KNOWN_LIMITATIONS |

**সারসংক্ষেপ:** PASS 5 · PARTIAL 2 · UNVERIFIED 5 · অনুপস্থিত 1 · FAIL ০ (মোট 13)।
**অবস্থা:** Phase ৪ ও ৫ = `WRITTEN — NOT YET BUILD-VERIFIED`। প্রস্থান-শর্ত: CI সবুজ + ডিভাইস-পরিমাপ।
