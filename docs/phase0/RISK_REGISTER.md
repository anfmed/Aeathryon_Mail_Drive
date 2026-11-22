# RISK_REGISTER

পর্যালোচনার তারিখ: ২০২৬-১১-১০ | সম্ভাবনা/প্রভাব: H=উচ্চ, M=মাঝারি, L=নিম্ন (বিচারভিত্তিক অনুমান — পরিমাপ নয়)

| ID | ঝুঁকি | শ্রেণি | P | I | প্রশমন/পরবর্তী পদক্ষেপ | Owner/Phase | Source |
|---|---|---|---|---|---|---|---|
| R-01 | **Google restricted-scope verification ও সম্ভাব্য বার্ষিক security assessment** — সময়, খরচ ও অনুমোদনের অনিশ্চয়তা; Free-core নীতির সঙ্গে সংঘাত। Drive-এ অ্যাপ-শ্রেণি অনুমোদিত না হলে Drive/Gmail সমর্থন ব্যাহত | Licensing/Auth | H | H | ADR-009 সিদ্ধান্ত; Google-এর CASA ও local-only পাতা primary-থেকে যাচাই; বিকল্প: ব্যবহারকারী-নিজস্ব OAuth client | ব্যবহারকারী + Phase 0.1/1 | S01–S04, S06 |
| R-02 | MEGA ToS/API-key নীতি অজানা বা বাধাসৃষ্টিকারী; পুরোনো ToS-এ অনুমোদন-শর্ত | Licensing | M | M | MEGA-র বর্তমান ToS ও developer পাতা প্রাইমারি-যাচাই; অ্যাপ-key আবেদন; ঐচ্ছিক flavor | Phase 1 | S07, S08 |
| R-03 | Microsoft basic auth অপসারণ-সময়সূচি ও tenant admin-consent অনিশ্চয়তা | Auth | M | M | শুধু OAuth নকশা; Microsoft Learn/Exchange blog primary-যাচাই | Phase 1 | S09, S10 |
| R-04 | Yahoo OAuth-অনুমোদন (ফর্ম+চুক্তি) প্রত্যাখ্যাত/ধীর | Provider | M | M | App-password fallback; primary-যাচাই | Phase 1 | S19 |
| R-05 | Apple Developer Program খরচ (paid) — iOS/macOS বিতরণ অসম্ভব এটা ছাড়া | Platform/Cost | H | H | ADR-008; বিকল্প নেই (বিনামূল্যে ৭ দিনের সীমিত) | ব্যবহারকারী | S22 |
| R-06 | **Flutter-এর RAM/স্টার্টআপ ৪ GB desktop ও low-end Android-এ বাজেট পূরণ না-ও করতে পারে** | Performance | M | H | Phase 1 spike; ব্যর্থ হলে বিকল্প স্ট্যাক (ADR-003) | Phase 1 | S23 (পরিমাপ নেই) |
| R-07 | iOS-এ নির্ভরযোগ্য background/push সম্ভব নয় → "real-time" প্রত্যাশা-ফাঁক | Platform | H | M | সৎ UI-বার্তা; ঐচ্ছিক relay (ADR-007) | Phase 2 | S25 |
| R-08 | Private repo-তে CI মিনিট (বিশেষত macOS ×১০) দ্রুত শেষ | Cost | M | M | ADR-010; public repo বা macOS বিল্ড বিরল রাখা; ক্যাশ | ব্যবহারকারী | S21 |
| R-09 | ঐচ্ছিক relay-এর অপারেশন/খরচ/গোপনীয়তা-দায় (Gmail Pub/Sub-এ অ্যাপ-মালিক GCP লাগে) | Architecture | M | M | Relay-তে কনটেন্ট/টোকেন নয়; self-host; ঐচ্ছিক রাখা | ADR-007 | S05 |
| R-10 | `sqlcipher_flutter_libs` EOL — এনক্রিপ্টেড DB-র সমর্থিত পথ অনিশ্চিত | Dependency | M | H | `sqlite3` ৩.x-এর বিকল্প পথ যাচাই; বিকল্প field-level AEAD | Phase 1 | S24 |
| R-11 | গবেষণা-ঋণ: quota, RFC, প্যাকেজ লাইসেন্স ইত্যাদি অনেক ঘর UNVERIFIED — ভুল সিদ্ধান্তের ঝুঁকি | Process | H | M | Phase 0.1 গবেষণা-ধাপ বা Phase 1 প্রথম স্প্রিন্টে সম্পন্ন | Phase 0.1/1 | API_AND_LICENSING §৩ |
| R-12 | Linux-এ Secret Service অনুপস্থিত/headless → নিরাপদ token-সংরক্ষণ দুর্বল | Security | M | M | স্পষ্ট ব্যবহারকারী-সতর্কতা + পাসফ্রেজ-ভিত্তিক master-key fallback | Phase 1 | — |
| R-13 | Dependency supply-chain/CVE | Security | M | H | নূন্যতম dep, লকফাইল, কুলিং-পিরিয়ড, SBOM | সব Phase | — |
| R-14 | Provider API পরিবর্তন/বন্ধ (Basic auth ধরনের) | Provider | M | M | Capability registry; adapter-সীমা; নিয়মিত পুনর্যাচাই | চলমান | — |
| R-15 | Play/App Store নীতি (restricted-scope ডেটা, background service) লঙ্ঘন-ঝুঁকি | Platform | M | H | প্রকাশের পূর্বে নীতি-পর্যালোচনা | Phase 5+ | UNVERIFIED |
| R-16 | একক ডেভেলপার + ৪ GB মেশিন + ৫ platform = ক্ষমতা-সীমা | Delivery | H | H | Drive বা Mail-এর একটি আগে; phased roadmap; CI-নির্ভরতা; platform-ক্রম (Android/Windows আগে) | ব্যবহারকারী | — |
| R-17 | Google Drive ToS: storage pooling/sharding নিষিদ্ধ — ভবিষ্যৎ feature-ধারণা লঙ্ঘন করতে পারে | Licensing | L | H | ADR-013; legal পর্যালোচনা প্রতিটি "storage intelligence" feature-এর | চলমান | S03 |
| R-18 | Proton ব্যবহারকারীর প্রত্যাশা-ফাঁক (mobile নেই, paid, Bridge লাগে) | UX | H | L | স্পষ্ট ব্যাখ্যা; `UNSUPPORTED` সৎভাবে | Phase 2 | S17 |
| R-19 | Flutter সংস্করণ/ন্যূনতম OS অস্পষ্ট (৩.৪৪ বনাম ৩.৪৭ পাতা) | Platform | M | L | Phase 1-এ pin ও পুনঃযাচাই | Phase 1 | S23 |
| R-20 | Provider-স্তরে অপরিবর্তনীয় মুছে ফেলায় ডেটা-ক্ষতি | Data safety | L | H | trash-first, নিশ্চিতকরণ, ব্যতিক্রম-নথি | Phase 2+ | — |
