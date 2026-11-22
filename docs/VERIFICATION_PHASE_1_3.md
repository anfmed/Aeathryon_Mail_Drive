# VERIFICATION_PHASE_1_3
তারিখ: ২০২৬-১১-১০ | পদ্ধতি: স্বয়ংক্রিয় স্ক্রিপ্ট (Python sqlite3, yaml, regex-ভিত্তিক কাঠামো-পরীক্ষা, স্বাধীন algorithm-port) — **Dart compile/test নয়**।

| # | যাচাই | ফল | প্রমাণ |
|---|---|---|---|
| V1 | Monorepo কাঠামো (apps/, packages/, schema/, tools/, docs/, .github/) | PASS | ফাইল-তালিকা |
| V2 | ৭টি Dart package + ২টি app shell লেখা | PASS (লেখা) | `find` |
| V3 | **Dart কোড compile/analyze/test সফল** | **UNVERIFIED** | Dart নেই; CI-তে প্রথম রান বাকি |
| V4 | CI workflow YAML বৈধ | PASS | `yaml.safe_load` ১১ ফাইল |
| V5 | CI-তে ৫টি platform × ২ অ্যাপ | PASS (কনফিগ) / UNVERIFIED (রান) | matrix চেক |
| V6 | Web কোথাও নেই | PASS | grep |
| V7 | কোনো secret/credential commit হয়নি | PASS | grep (প্যাটার্ন-ভিত্তিক; সম্পূর্ণ গ্যারান্টি নয়) |
| V8 | Drive schema বৈধ: FTS5, বাংলা অনুসন্ধান, CHECK/FK, cascade-delete | PASS | SQLite 3.45 |
| V9 | Mail schema বৈধ: FTS5, orphan-reject, bad-state-reject, cascade | PASS | SQLite 3.45 |
| V10 | Drive ও Mail DB আলাদা, কোনো token/password কলাম নেই | PASS | schema-স্ক্যান |
| V11 | SQLCipher-এ schema বৈধ | UNVERIFIED | SQLCipher নেই |
| V12 | PKCE S256 RFC 7636 vector | PASS (algorithm, Python hashlib) / UNVERIFIED (Dart `crypto`) | স্বাধীন হ্যাশ |
| V13 | Chunk planner, scheduler, threader, backoff — test-প্রত্যাশা | PASS (Python port) / UNVERIFIED (Dart) | port + assert |
| V14 | Import↔pubspec সামঞ্জস্য, barrel-export অস্তিত্ব | PASS | স্ক্রিপ্ট |
| V15 | Pooling `UNSUPPORTED`, FULL-এ source বাধ্যতামূলক (কোডে ও টেস্টে) | PASS (লেখা) / UNVERIFIED (রান) | কোড |
| V16 | WebDAV live-server আচরণ | UNVERIFIED | সার্ভার নেই |
| V17 | IMAP/SMTP, OAuth flow, secure-storage binding, UI | **অনুপস্থিত (ইচ্ছাকৃত স্থগিত)** | KNOWN_LIMITATIONS |
| V18 | Performance বাজেট P-01…P-14 | UNVERIFIED (অ-মাপা) | — |
| V19 | PROPOSED/OPEN সিদ্ধান্ত লক্ষ্য-ভিত্তিতে নিষ্পত্তি ও নথিভুক্ত | PASS | DECISIONS_PHASE_1_3 |

**সারসংক্ষেপ:** PASS 10 · PARTIAL (PASS+UNVERIFIED মিশ্র) 4 · UNVERIFIED 4 · অনুপস্থিত (ইচ্ছাকৃত স্থগিত) 1 · FAIL 0 (মোট 19)।
**অবস্থা:** Phase ১, ২, ৩ = `WRITTEN — NOT YET BUILD-VERIFIED`। প্রস্থান-শর্ত (exit gate) = GitHub-এ `ci-core` সবুজ। সেটি না হওয়া পর্যন্ত আমি এগুলোকে "সম্পূর্ণ সম্পন্ন" বলছি না।
