# DEPENDENCY_GATE
Phase 0 নিয়ম: "শুধু জনপ্রিয় বলে নির্বাচন নয়"। বর্তমান runtime dependency:

| প্যাকেজ | কেন দরকার | লাইসেন্স | রক্ষণাবেক্ষণ | আকার/RAM | অবস্থা |
|---|---|---|---|---|---|
| `crypto` | PKCE S256 (SHA-256) | UNVERIFIED | UNVERIFIED | UNVERIFIED | প্রার্থী; বিকল্প: নিজে SHA-256 লেখা (নিষিদ্ধ — crypto নিজে বানানো নয়) |
| `http` | WebDAV/REST | UNVERIFIED | UNVERIFIED | UNVERIFIED | প্রার্থী |
| `xml` | PROPFIND multistatus | UNVERIFIED | UNVERIFIED | UNVERIFIED | প্রার্থী; বিকল্প regex-পার্সিং (ভঙ্গুর → প্রত্যাখ্যাত) |
| `test` | dev-only | — | — | — | dev |
| `enough_mail` (`mail_imap`, isolated) | IMAP/SMTP | MPL-2.0 (S27) | UNVERIFIED | UNVERIFIED | Phase 4: blind-লেখা wrapper; CI `isolated` job; সংস্করণ-constraint `^2.1.0` অনুমান (UNVERIFIED) |
| `flutter_secure_storage` (isolated wrapper) | OS secure store | UNVERIFIED | UNVERIFIED | UNVERIFIED | Linux-এ libsecret লাগে; এখনো অ্যাপে wired নয় |
| `flutter_test` | dev-only | SDK | — | — | dev |

CI: `tools/dependency_report.sh` প্রতি রানে সমাধানকৃত সব প্যাকেজ তালিকা করে ও `docs/dependency_allowlist.txt`-এর বাইরের গুলো `UNREVIEWED:` দেখায় (এখন non-blocking; Phase 4 এ blocking)।
**Supply-chain নিয়ম:** Flutter/Actions সংস্করণ pin (প্রথম সবুজ রানের পর); নতুন-প্রকাশিত (≤১৪ দিন) সংস্করণ গ্রহণ নয়; লকফাইল commit।

| `sqlite3` (শুধু `spikes/`) | এনক্রিপ্টেড-DB পরীক্ষা | SQLite: public domain; **SQLite3MultipleCiphers ও SQLCipher-এর নিজস্ব লাইসেন্স**; SQLCipher-build Windows/Linux/Android-এ OpenSSL লিঙ্ক করে (pub.dev docs) | সক্রিয় (docs ৩.৫.x) | spike-এ মাপা হবে | **অ্যাপে নেই**; সিদ্ধান্ত spike-এর পর (ADR-035) |
> বাস্তব CI-রান থেকে সমাধানকৃত সংস্করণ (২০২৬-১১): http 1.6.0, xml 7.1.0, crypto 3.0.8, test 1.33.0 — লাইসেন্স/আকার এখনো অযাচাইকৃত।
