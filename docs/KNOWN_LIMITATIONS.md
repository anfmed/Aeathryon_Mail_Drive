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

## Welcome / About / Support / Feedback (v6)
14. **AUS-সংযোগ আংশিক:** link-সেবা `GET {AUS_BASE_URL}/v1/links` ডাকে, কিন্তু (ক) **AUS base URL এই প্রকল্পে কনফিগার করা নেই** — GitHub Variable `AUS_BASE_URL` বসাতে হবে; (খ) **AUS-এর আসল response-আকার আমার অজানা** (অনুমানভিত্তিক সহনশীল parser); (গ) কোনো আসল AUS-এর বিরুদ্ধে পরীক্ষা হয়নি; (ঘ) এই প্রকল্পে AUS-এর কোনো বিদ্যমান client ছিল না, তাই নতুন integration-point বানানো হয়েছে। Feedback-ও আসল endpoint-এ পরীক্ষিত নয়।
15. **Logo:** ফাইলটি ছোট করা (৬৪০px); আরও বড় পর্দায় (উচ্চ-DPI desktop-এ ১২৮dp+) সামান্য নরম দেখাতে পারে — দরকার হলে আসল মাপ ব্যবহার করব।
16. Welcome-flag secure-store-এ থাকে (বিদ্যমান preference-পথ)। Android-এ uninstall করলে মুছে যায় (backup বন্ধ)।
17. Support বোতাম Files ও Inbox-এর toolbar-এ; অন্য ট্যাবে (Transfers, Search, Accounts, Settings) নেই — Settings → About-এ Support আছে।
18. `flutter test`-এ `assets` লোড হয় কি না (logo) ও Support-বোতামের ৪৮dp-নির্দেশিকা — **কখনো চালানো হয়নি**।
19. সর্বশেষ আসল CI-রানে **`aethryon_store` টেস্ট-ফাইল লোড হয়নি** (`loading test/store_test.dart (failed)`, ত্রুটি-বার্তা পেস্টে ছিল না; `dart analyze` পরিষ্কার ছিল)। সন্দেহ: `sqlite3` build-hook। এখন `-r expanded` রিপোর্টার চালু — পরের রানের লগ লাগবে।
20. **v6-এ `git pull -X ours` দিয়ে merge করায় দুই অ্যাপের `main.dart` ভেঙেছিল** (`Expected to find ')'`) — আমার সংস্করণ সিনট্যাক্সে ঠিক ছিল, কিন্তু `format`-এর commit-এর সঙ্গে মিশে গিয়েছিল। এখন নিয়ম: আগে `pull`, তারপর ZIP overwrite (`USER_ACTION_CHECKLIST.md` §০)।
21. `SupportButton` প্রথমে ৪০dp উঁচু ছিল (compact density) ও accessibility tap-target (৪৮dp) টেস্টে আসল CI-তে ব্যর্থ হয়েছিল; v7-এ ৪৮dp।
