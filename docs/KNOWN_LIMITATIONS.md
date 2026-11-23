# KNOWN_LIMITATIONS (Phase ১–৭ পর্যন্ত, খোলাখুলি)
## প্রমাণিত (আসল CI-রান থেকে, আপনার রিপোর্ট অনুযায়ী)
- Phase ১–৫-এর কোড compile হয়েছে; check (analyze+test) ও Android+Windows build **সবুজ**। একমাত্র লাল ছিল `webdav-live` (ঐচ্ছিক)।
- সেই লালের **নিশ্চিত কারণ** (CI-লগ): retry একই, ইতিমধ্যে-ব্যবহৃত body-stream আবার পড়ছিল (`Stream has already been listened to`) — আমার adapter-bug। প্রথম ত্রুটি (`HttpException: unsolicited response`) এর কারণ **অনুমান**: body-ছাড়া request chunked-encoding-এ যাচ্ছিল। দুটোরই ফিক্স Phase ৬-এ; **ফিক্স এখনো CI-তে চালানো হয়নি**।
## Phase ৬–৭-এর কোড: অ-কম্পাইলকৃত ও অপরীক্ষিত
1. **এই ধাপের সব নতুন Dart কোড** (আসল-account UI, vault, adapter, runner, OAuth sign-in) compile/test হয়নি — প্রথম CI-রানই যাচাই। Python-এ শুধু হিসাব-যুক্তি (chunk-ভাগ, resume-নিয়ম, Dropbox call-ক্রম, URL-নিয়ম, ascii-escape, blocked-matrix) মেলানো হয়েছে।
2. **Dropbox ও OneDrive adapter blind-লেখা** (API-আকার সাধারণ জ্ঞান থেকে; OneDrive-এর শুধু createUploadSession ও ৩২০ KiB-নিয়ম Phase ০-এ যাচাইকৃত)। mock-test প্রমাণ করে কোড নিজের সঙ্গে সঙ্গত, **আসল সার্ভারের সঙ্গে নয়**। তাই UI-তে নির্বাচনযোগ্য নয়।
3. **`mail_imap` আসল সার্ভারে কখনো চলেনি।** UID-fetch, startTls ইত্যাদি `UNVERIFIED-API`। আপনি `isolated` চালিয়ে থাকলে ফল জানাবেন; এখন এটি gate-এর অংশ, তাই ব্যর্থ হলে build আটকাবে।
4. **Mail অ্যাপ:** আসল account-এ শুধু **ইনবক্সের subject-তালিকা**। বার্তার body ডাউনলোড নেই, ফোল্ডার-তালিকা নেই, flag-sync নেই। স্থানীয় ক্যাশ **শুধু মেমরিতে** (অ্যাপ বন্ধ করলে যায়); account ও password থাকে secure store-এ।
5. **Drive অ্যাপ:** আসল WebDAV account-এ ব্রাউজ ও মোছা আছে; **ফাইল upload/download UI নেই** (`TransferRunner` লেখা, কিন্তু UI-তে জোড়া নয়); offline-ফাইল ও search নেই।
6. **OAuth:** provider-তালিকা ও desktop loopback sign-in (টেস্টসহ) আছে; **অ্যাপে "Sign in" বোতাম নেই** (ব্রাউজার খুলতে `url_launcher` লাগবে — Phase ৮); মোবাইল redirect নেই; সব endpoint `endpointsVerified: false`।
7. **এনক্রিপশন:** DB-র সিদ্ধান্ত অমীমাংসিত; spike লেখা, **ফল আসেনি**। বর্তমানে কোনো মেইল/ফাইল-মেটাডাটা ডিস্কে সংরক্ষিত হয় না।
8. **Proton, Gmail, Outlook** UI-তে আটকানো (কারণ ব্যাখ্যাসহ)।
9. **Flutter `material.dart` deprecated** (stable ≥3.47; নতুন নাম `material_ui`) — এখন শুধু info; Phase ৮-এ যাচাই করে migrate।
10. **Performance:** SQLite-স্তর মাপা (`docs/bench_sqlite_result.json`; in-memory, desktop, SQLCipher ছাড়া)। UI/স্টার্টআপ/RAM/ব্যাটারি **অ-মাপা**।
11. **Release:** unsigned draft মাত্র; signing, Privacy Policy, স্টোর — বাকি।
12. Box, pCloud, Google Drive, MEGA adapter নেই; Zoho/Yahoo/Outlook/Gmail আসল সংযোগ নেই।
13. নিরাপত্তা-নিরীক্ষা, accessibility (screen-reader) নিরীক্ষা, স্টোর-নীতি পর্যালোচনা — হয়নি।
