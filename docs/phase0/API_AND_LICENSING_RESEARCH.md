# API_AND_LICENSING_RESEARCH

পর্যালোচনার তারিখ (সব source): **২০২৬-১১-১০** | পদ্ধতি: web search (এই session)। **শুধু যে পাতা search ফলাফলে পাওয়া গেছে** তা source হিসেবে তালিকাভুক্ত। কোনো পাতা সম্পূর্ণ fetch করা হয়নি; ফলাফলের snippet ও বিবরণের ভিত্তিতে সারাংশ।

**Evidence level:** PRIMARY = provider/vendor-এর নিজস্ব official পাতা; SECONDARY = তৃতীয় পক্ষ (blog, বিক্রেতা, forum) — তাই নিশ্চিত দাবির জন্য যথেষ্ট নয়।

## ১. Source Register
| ID | URL | ধরন | বিষয় | মন্তব্য |
|---|---|---|---|---|
| S01 | https://developers.google.com/drive/api/guides/api-specific-auth | PRIMARY | Drive scope শ্রেণি (non-sensitive/sensitive/restricted), `drive.file` | — |
| S02 | https://developers.google.com/drive/scopes | PRIMARY | Drive scope তালিকা | — |
| S03 | https://developers.google.com/drive/api/terms | PRIMARY | Drive API Terms: restricted scope-এর অনুমোদিত ধরন; storage sharding/limit-circumvention নিষিদ্ধ | পুরো ToS পড়া হয়নি |
| S04 | https://developers.google.com/gmail/xoauth_migration | PRIMARY | IMAP/SMTP-এ OAuth/XOAUTH2, scope `https://mail.google.com/` | — |
| S05 | https://developers.google.com/gmail/api/guides/push | PRIMARY | Gmail push: `users.watch`, Cloud Pub/Sub, watch নবায়ন | — |
| S06 | https://docs.unified.to/skills/gmail-oauth-app/SKILL.md | SECONDARY | Gmail restricted scope ও CASA প্রক্রিয়া | Google-এর নিজস্ব CASA পাতা যাচাই করা হয়নি |
| S07 | https://github.com/orgs/meganz/repositories ও meganz/sdk source header | PRIMARY (GitHub) | MEGA SDK লাইসেন্স BSD-2-Clause; header: অ্যাপকে valid application key দিতে ও ToS মানতে হবে | — |
| S08 | MEGA ToS-এর পুরোনো (২০১৩) প্রতিলিপি (gist) | SECONDARY, **পুরোনো/archived** | তখনকার শর্ত: API ব্যবহারে developer নিবন্ধন ও অনুমোদন | বর্তমান শর্ত UNVERIFIED |
| S09 | https://learn.microsoft.com/en-us/exchange/client-developer/legacy-protocols/how-to-authenticate-an-imap-pop-smtp-application-by-using-oauth | PRIMARY | Exchange Online IMAP/POP/SMTP-এ OAuth, scope | — |
| S10 | LinkedIn পোস্ট ও Microsoft Q&A থ্রেড (SMTP AUTH basic retirement) | SECONDARY, **পরস্পরবিরোধী তারিখ** | Basic auth অপসারণের সময়সূচি | Microsoft-এর official ঘোষণা fetch হয়নি → UNVERIFIED |
| S11 | https://learn.microsoft.com/en-us/graph/api/driveitem-createuploadsession | PRIMARY | OneDrive resumable upload session; fragment ৩২০ KiB-এর গুণিতক | — |
| S12 | https://fast.io/resources/microsoft-graph-api-upload-large-file.md | SECONDARY | OneDrive সর্বোচ্চ ফাইল ২৫০ GB | official সংখ্যা যাচাই বাকি |
| S13 | https://docs.rs/dropbox-sdk/latest/dropbox_sdk/files/fn.upload_session_append.html | SECONDARY+ (SDK, Dropbox spec থেকে generated) | Dropbox upload session; একক request ≤১৫০ MB; session ≤৩৫০ GB | Dropbox-এর নিজস্ব docs পৃষ্ঠা নয় |
| S14 | https://developer.box.com/guides/getting-started/agent-playbook ও https://github.com/box/developer.box.com/blob/en-staging/guides/api-calls/permissions-and-errors/rate-limits.md | PRIMARY | Box OAuth token আয়ু, rate limit (~১০০০/মিনিট/ব্যবহারকারী; upload ২৪০/মিনিট), chunked upload | — |
| S15 | https://docs.pcloud.com ও https://help.pcloud.com/article/data-regions | PRIMARY | pCloud API: OAuth 2.0, দুই regional host (US/EU) | rate limit, resumable — UNVERIFIED |
| S16 | https://docs.nextcloud.com/server/latest/developer_manual/client_apis/index.html | PRIMARY | Nextcloud client API: WebDAV, Login Flow v2, chunked upload, trashbin, versions, search, OCS share | শুধু বিষয়সূচি/অস্তিত্ব; বিবরণ UNVERIFIED |
| S17 | https://proton.me/support/mail/bridge/introduction-bridge ও https://proton.me/hi/support/imap-smtp-and-pop3-setup | PRIMARY | Proton Bridge: Windows/macOS/Linux, paid plan, মোবাইলে নেই | Bridge-এর লাইসেন্স UNVERIFIED |
| S18 | https://support.apple.com/en-uz/102525 | PRIMARY | iCloud Mail IMAP/SMTP; app-specific password | — |
| S19 | https://developer.nylas.com/docs/provider-guides/yahoo-authentication/ | SECONDARY | Yahoo OAuth: Mail API Access ফর্ম ও Commercial Access Agreement; app password | Yahoo-র নিজস্ব পাতা fetch হয়নি |
| S20 | https://prezohoweb.zoho.com/mail/help/api/getting-started-with-api.html | PRIMARY (Zoho-র pre-production host) | Zoho Mail REST API, OAuth2, একাধিক data center | Production পাতা যাচাই বাকি |
| S21 | https://docs.github.com/en/billing/concepts/product-billing/github-actions ও https://docs.github.com/en/billing/managing-billing-for-github-actions/about-billing-for-github-actions | PRIMARY | Public repo-তে standard runner বিনামূল্যে; ব্যবহার-multiplier | Private repo-র ফ্রি কোটা SECONDARY (cicdpipelinecost.com); ২০২৬-এর মূল্য পরিবর্তনের খবর (itbrief) যাচাই বাকি |
| S22 | https://developer.apple.com/support/compare-memberships | PRIMARY | বিনামূল্যের provisioning সীমিত (৭ দিন); paid সদস্যপদের তুলনা | $99 সংখ্যা SECONDARY (expo.dev ইত্যাদি) |
| S23 | https://docs.flutter.dev/reference/supported-platforms | PRIMARY | Flutter-এর সমর্থিত platform ও সর্বনিম্ন সংস্করণ | সংস্করণ-বিভ্রান্তি — PLATFORM_COMPATIBILITY.md দেখুন |
| S24 | https://www.zetetic.net/sqlcipher/community/ ও https://pub.dev/packages/sqlcipher_flutter_libs/changelog | PRIMARY | SQLCipher Community: BSD-style, attribution; `sqlcipher_flutter_libs` EOL | — |
| S25 | https://mimestream.com/trust/private-push ও https://canarymail.io/help/?p=400 | SECONDARY (প্রতিযোগী/মেইল অ্যাপ বিক্রেতা) | iOS-এ IMAP IDLE সম্ভব নয়; push-এর জন্য server relay | Apple-এর নিজস্ব docs যাচাই বাকি |

## ২. প্রধান অনুসন্ধান
1. **Google restricted scope** (Drive `drive`, Gmail `mail.google.com`/গ্রানুলার): verification ও সম্ভাব্য বার্ষিক third-party security assessment (S01–S04, S06)। Local-only অ্যাপের জন্য assessment ছাড় আছে কি না — **UNVERIFIED**। Free-core নীতির সঙ্গে খরচের সংঘাত — RISK R-01।
2. **Google Drive ToS:** storage pooling/sharding নিষিদ্ধ (S03) → pooled-storage feature বাদ।
3. **Gmail push → backend প্রয়োজন** (S05) → local-first নীতির সঙ্গে সংঘাত → OPEN সিদ্ধান্ত।
4. **MEGA:** SDK BSD-2 (S07) = redistribution-বান্ধব লাইসেন্স, কিন্তু API ব্যবহার application key ও ToS দ্বারা নিয়ন্ত্রিত (S07); বর্তমান developer-অনুমোদন প্রক্রিয়া UNVERIFIED (S08 পুরোনো)।
5. **Microsoft:** IMAP/SMTP OAuth সমর্থিত (S09); basic auth অপসারণের সময়সূচি অনিশ্চিত (S10) → আমরা শুধু OAuth নকশা করব।
6. **Proton:** desktop-only, paid-only সহযোগী (S17) → mobile `UNSUPPORTED`।
7. **iCloud:** app-specific password; কোনো OAuth/REST API পাওয়া যায়নি (S18; অনুপস্থিতি UNVERIFIED)।
8. **Yahoo:** OAuth-এর জন্য অনুমোদন প্রক্রিয়া (S19 সেকেন্ডারি) → `REQUIRES_PERMISSION`।
9. **CI খরচ:** public repo-তে free (S21); macOS minute-multiplier উঁচু (S21) → private repo-তে দ্রুত শেষ হওয়ার ঝুঁকি।
10. **Apple:** বিনামূল্যের provisioning ৭ দিনের (S22) → অর্থবহ iOS বিতরণে paid সদস্যপদ অনিবার্য ধরে নেওয়া হচ্ছে (SECONDARY মূল্য)।
11. **SQLCipher:** লাইসেন্স অনুকূল (S24); কিন্তু Dart wrapper `sqlcipher_flutter_libs` EOL (S24) → বিকল্প পথ যাচাই আবশ্যক।

## ৩. এখনো যাচাই হয়নি (গবেষণা-ঋণ)
Google Drive/Gmail quota সংখ্যা; Microsoft Graph throttling; Dropbox রেট-লিমিট ও production-approval সীমা; Box app-approval শর্ত; pCloud রেট-লিমিট/resumable/WebDAV; Nextcloud push (`notify_push`) ও chunk আকার; WebDAV (RFC 4918) ও IMAP (RFC 3501/9051, IDLE, CONDSTORE/QRESYNC) RFC; Zoho IMAP ও রেট-লিমিট; Yahoo-র primary পাতা; MEGA-র বর্তমান ToS ও developer নীতি; Flutter/Dart প্যাকেজের (drift, enough_mail, flutter_appauth, flutter_secure_storage ইত্যাদি) লাইসেন্স, রক্ষণাবেক্ষণ ও আকার; Apple platform-এর background নিয়ম (primary)। এগুলো `PHASE_0_VERIFICATION.md`-এ PARTIAL/UNVERIFIED হিসেবে গণ্য।
