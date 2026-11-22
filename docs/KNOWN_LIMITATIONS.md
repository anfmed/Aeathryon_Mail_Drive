# KNOWN_LIMITATIONS (Phase ১–৫ পর্যন্ত, খোলাখুলি)
1. **কোনো Dart/Flutter কোড compile/analyze/test হয়নি।** এই পরিবেশে Dart/Flutter নেই, network বন্ধ। প্রথম আসল যাচাই = GitHub Actions। প্রথম রানে ত্রুটি আসার সম্ভাবনা **বেশি** (বিশেষত UI ও `mail_imap`)।
2. **সত্যিই যাচাই হয়েছে (Dart-এর বাইরে):** SQL schema (SQLite 3.45 + FTS5 + বাংলা), YAML syntax (৩ workflow, ১০+ pubspec), import↔pubspec সামঞ্জস্য, barrel export, PKCE RFC-7636 vector (Python hashlib), এবং Python port-এ: chunk planner, transfer scheduler, threader, backoff bound, **mail sync-service (৪ দৃশ্য)**, **plain-text extractor (৬ টেস্ট)**। **এগুলো Dart কোড যাচাই নয়।**
3. **`mail_imap` blind-লেখা।** `enough_mail` docs-এ যে call-গুলো হুবহু দেখেছি (connectToServer, authenticateWithOAuth2, capability, selectMailbox, fetchMessages) সেগুলো ছাড়া বাকি (UID fetch, MessageSequence, startTls ইত্যাদি) `UNVERIFIED-API` চিহ্নিত। সংস্করণ-constraint (`^2.1.0`) অনুমান। `setFlags` অবাস্তবায়িত। UID-fetch সব ফেরত এনে ছাঁটে (অদক্ষ)।
4. **Sync শুধু নতুন-মেইল আবিষ্কার + UIDVALIDITY রিসেট।** Flag-পরিবর্তন/মোছা (CONDSTORE/QRESYNC) sync নেই; কৌশল শনাক্ত হয়, চলে না।
5. **অ্যাপে এখনো আসল ডেটা নেই।** UI demo (in-memory) ডেটায় চলে। IMAP transport, secure-store wrapper, OAuth অ্যাপে wired নয় — কারণ unverified কোড অ্যাপ-build ভাঙতে পারে (ADR-024)। Wiring = সবুজ CI-র পর।
6. **OAuth:** desktop loopback ও token-exchange আছে (MockClient-টেস্ট লেখা)। **মোবাইল redirect নেই।** কোনো provider-এর আসল endpoint/scope বসানো হয়নি।
7. **WebDAV:** live test CI-তে wsgidav-এ (`--auth=anonymous` flag UNVERIFIED)। Nextcloud-নির্দিষ্ট (chunked, trashbin, OCS, Login Flow) নেই। Upload-stream রিপ্লে হয় না → upload-retry transfer-manager স্তরে (অবাস্তবায়িত)।
8. **এনক্রিপশন:** DB-encryption অমীমাংসিত (SQLCipher পথ: `sqlite3` Dart প্যাকেজ ৩.x — অযাচাইকৃত; `sqlcipher_flutter_libs` EOL)। Schema সাধারণ SQLite-এ যাচাইকৃত। **বর্তমান কোডে কোনো স্থানীয় ডেটা এনক্রিপ্টেড সংরক্ষণ হয় না** (সবই in-memory)।
9. **Performance:** SQLite-স্তর মাপা হয়েছে (`docs/bench_sqlite_result.json`) — in-memory, warm cache, desktop CPU, SQLCipher ছাড়া → **device-এর সংখ্যা নয়**। UI/স্টার্টআপ/RAM/ব্যাটারি (P-01…P-06, P-09…P-14) **অ-মাপা**। Flutter-ঝুঁকি R-06 অমীমাংসিত।
10. **Release:** unsigned draft মাত্র। Android/Windows signing, macOS/iOS স্বয়ংক্রিয় নয়।
11. **CI-র অনুমানগুলো:** Flutter `stable` ট্যাগ অনির্দিষ্ট; Linux apt-তালিকা; Android licence ধাপ; `flutter create` থেকে platform-ফোল্ডার অনুলিপি; `actions/*@v4` সংস্করণ — সব প্রথম রানে সংশোধন লাগতে পারে।
12. **Provider তথ্য-ঋণ** (Phase ০ §৩) বেশিরভাগ এখনো বাকি; MEGA, Box, Dropbox, pCloud, OneDrive adapter নেই।
13. **নিরাপত্তা-নিরীক্ষা, accessibility-নিরীক্ষা (screen reader), স্টোর-নীতি পর্যালোচনা** — হয়নি।
14. GitHub-এ push/Actions চালানো আমি করতে পারি না — আপনার (docs/USER_ACTION_CHECKLIST.md)।
