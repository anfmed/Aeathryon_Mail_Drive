# KNOWN_LIMITATIONS (Phase ১–৯ পর্যন্ত, খোলাখুলি)
## আসল CI থেকে প্রমাণিত (আপনার রিপোর্ট অনুযায়ী)
- Phase ১–৫ কোড compile ও test পাস করেছে; Android+Windows build সফল হয়েছিল।
- Phase ৬–৭ চালানোর সময় **একমাত্র লাল**: `oauth_signin_test` — কারণ নিশ্চিত: `redirectUri` পড়া হচ্ছিল loopback server বন্ধ হওয়ার **পরে**; ফিক্স (port আগেই সংরক্ষণ) + regression-টেস্ট Phase ৮-এ। ওই রানে `ci_core.sh` প্রথম ব্যর্থতায় থেমেছিল, তাই `drive_core`, `mail_core`, `mail_imap`, Flutter অংশ **তখনো চলেইনি**।
## Phase ৮–৯-এর কোড: অ-কম্পাইলকৃত ও অপরীক্ষিত
1. **এই ধাপের সব নতুন Dart কোড** (store, flag-sync, transfer-controller, self-test, OAuth-UI, দুই অ্যাপের পুনর্লিখন) compile/test হয়নি। Python-এ যাচাই হয়েছে শুধু: store-এর **হুবহু SQL** (upsert, FTS-join, cascade), `splitSql`-গণনা, FTS-query-নির্মাণ।
2. **সবচেয়ে ঝুঁকিপূর্ণ ৩টি জায়গা** (প্রথম রানে লাল হলে সম্ভাব্য কারণ): (ক) অ্যাপ-pubspec-এ `hooks: user_defines: sqlite3: source: sqlite3mc` — build-hook সব platform-এ চলবে কি না অযাচাইকৃত (লাল হলে Android/Windows build-লগ পাঠান); (খ) `mail_imap`-এর `UNVERIFIED-API` লাইনগুলো (UID-fetch/flags/body/xoauth2); (গ) Flutter-plugin (`file_selector`, `path_provider`, `url_launcher`, `flutter_secure_storage`)-এর Android/Windows build।
3. `aethryon_store` টেস্ট ধরে নেয় ডিফল্ট sqlite3 build **cipher-মুক্ত** (তাই "plaintext প্রত্যাখ্যান" টেস্ট পাস করে)।
## বৈশিষ্ট্য যা নেই / আংশিক
4. **Mail:** শুধু INBOX; ফোল্ডার-তালিকা নেই; পড়া/মোছা/archive/flag-পরিবর্তন UI নেই (flag-sync সার্ভার→অ্যাপ দিকে আছে); **attachment নেই**; মেইল-search UI নেই (store-এ আছে); outbox স্থায়ী নয়; HTML = শুধু plain text।
5. **Drive:** উপরের ছাড়া offline-**ফাইল** (শুধু নাম-তালিকা cache); সার্ভার-সাইড search নেই; Wi-Fi-only/metered নীতি নেই (connectivity plugin লাগবে); folder-sync/mirror নেই; WebDAV-এ resumable নেই।
6. **Provider:** Dropbox/OneDrive = blind adapter (experimental, self-test আছে); **Google Drive, Box, pCloud, MEGA adapter নেই** (প্রতিটির আসল docs পড়তে হবে; blind লেখা এড়ানো হয়েছে)।
7. **Background sync নেই** (ইচ্ছাকৃত, ADR-045); মেইল push নেই।
8. **OAuth:** সব endpoint `endpointsVerified: false`; Google/Microsoft মোবাইলে loopback-redirect UNVERIFIED; ব্যবহারকারীকে নিজের client ID বানাতে হয়।
9. `material.dart` deprecated (info) — `material_ui` migration করা হয়নি (API অযাচাইকৃত)।
10. **Performance:** ডিভাইসে P-01…P-14 **অ-মাপা** (আমি ডিভাইস পাই না) — Diagnostics-স্ক্রিন + প্রোটোকল দেওয়া হয়েছে, মাপবেন আপনি। SQLite-স্তর মাপা (desktop, in-memory)।
11. **Release:** Windows সাইন নেই; Linux শুধু tar.gz; Play-এর জন্য AAB নেই; আইকন নেই; Privacy Policy খসড়া (আইনি পর্যালোচনা ও ইমেইল বাকি)।
12. নিরাপত্তা-নিরীক্ষা ও accessibility: কেবল self-review + স্বয়ংক্রিয় tap-target পরীক্ষা (`SECURITY_REVIEW_PHASE9.md`)।
13. Apple (iOS/macOS) সম্পূর্ণ বাদ।
