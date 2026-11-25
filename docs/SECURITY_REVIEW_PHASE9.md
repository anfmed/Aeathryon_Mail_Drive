# SECURITY_REVIEW (self-review, Phase 8–9) — penetration test নয়
কোড-পর্যালোচনা `SECURITY_THREAT_MODEL.md`-এর বিপরীতে। অবস্থা: ✔ কোডে আছে (CI-যাচাই বাকি) · ⚠ ঝুঁকি/সীমা · ✘ নেই।
| # | বিষয় | অবস্থা | মন্তব্য |
|---|---|---|---|
| 1 | Credential শুধু OS secure store | ✔ | `AccountVault`, `SecureTokenStore`; settings-এ secret-জাতীয় key নিষিদ্ধ (টেস্টসহ) |
| 2 | স্থানীয় DB এনক্রিপ্টেড; কখনো নীরব plaintext নয় | ✔ | `cipherActive` পরীক্ষা; না থাকলে সংরক্ষণ বন্ধ + UI-তে কারণ। **আসল cipher-build CI-spike-এ যাচাই বাকি** |
| 3 | DB key | ✔ | ২৫৬-বিট, `Random.secure`, secure store-এ; হারালে cache নতুন করে (শুধু cache) |
| 4 | DB-তে শুধু পুনর্নির্মাণযোগ্য ডেটা | ✔ | header/নাম; body, attachment, password নয় |
| 5 | FTS-এ ইনজেকশন | ✔ | প্রতিটি token quoted; টেস্টে hostile input |
| 6 | https বাধ্যতামূলক (server URL) | ✔ | `validateServerUrl` (http শুধু loopback) |
| 7 | ডাউনলোড-নাম path-traversal | ✔ | `sanitizeFileName`, `uniqueFile` — overwrite নয় |
| 8 | HTML মেইল | ✔ | শুধু plain text; script/ছবি/tracking-pixel লোড হয় না |
| 9 | OAuth: PKCE, state (constant-time), loopback | ✔ | টেস্ট আছে। ⚠ Google/Microsoft মোবাইলে loopback আচরণ UNVERIFIED |
| 10 | Token pre-authenticated URL-এ যায় না | ✔ | OneDrive download/upload |
| 11 | ত্রুটি-বার্তা ও লগে secret নেই | ✔ | `OAuthError`, `RedactingLogger`; self-test শুধু exception-টাইপ দেখায় |
| 12 | Android backup | ✔ (CI-patch, best effort) | `allowBackup=false` |
| 13 | Basic-auth password | ⚠ | https-এ ঠিক; সার্ভার-সার্টিফিকেট ব্যর্থ হলে সংযোগ ব্যর্থ (পিনিং নেই — ইচ্ছাকৃত) |
| 14 | Linux secret store অনুপস্থিত | ⚠ R-12 | কোনো পাসওয়ার্ড-fallback নেই; ব্যবহারকারীকে ব্যাখ্যা-বার্তা দেখানো বাকি |
| 15 | মেমরিতে secret | ⚠ | Dart `String` শূন্য করা যায় না |
| 16 | মেইল outbox স্থায়ী নয় | ✘ | পাঠানো ব্যর্থ হলে লেখা মেইল হারায় (UI সৎভাবে বলে "Nothing was sent") |
| 17 | `mail_imap`/Dropbox/OneDrive আসল সার্ভারে | ✘ UNVERIFIED | self-test দিয়ে ব্যবহারকারী যাচাই করবেন |
| 18 | Dependency-নিরীক্ষা (CVE/লাইসেন্স) | ✘ | allowlist শুধু নাম; স্বয়ংক্রিয় CVE-স্ক্যান নেই |
| 19 | বাহ্যিক নিরীক্ষা | ✘ | প্রকাশের আগে সুপারিশকৃত |
## Accessibility (স্বয়ংক্রিয় পরীক্ষা আছে, মানুষের নয়)
Widget-টেস্টে `androidTapTargetGuideline`, `labeledTapTargetGuideline` (দুই অ্যাপ)। ✘ screen-reader (TalkBack/Narrator) হাতে-পরীক্ষা, ✘ contrast-পরীক্ষা, ✘ কীবোর্ড-ফোকাস-ক্রম পরীক্ষা — আপনার ডিভাইসে করতে হবে।
