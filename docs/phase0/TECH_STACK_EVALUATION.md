# TECH_STACK_EVALUATION

পর্যালোচনার তারিখ: ২০২৬-১১-১০ | অবস্থা: PROPOSED। **কোনো dependency "জনপ্রিয়" বলে নির্বাচিত নয়।** অধিকাংশ মেট্রিক এই session-এ পরিমাপ/যাচাই হয়নি → `UNVERIFIED`; Phase 1-এ spike দিয়ে পূরণ।

## ১. UI/অ্যাপ ফাউন্ডেশন
| বিকল্প | সুবিধা | অসুবিধা/ঝুঁকি | অবস্থা |
|---|---|---|---|
| **Flutter/Dart** | একক codebase ৫ platform (S23); Dart FFI; hot-reload; custom রেন্ডারিং | RAM/স্টার্টআপ ৪ GB ডেস্কটপে অপরিমিত (R-06); Linux distro-সীমা (S23); ন্যূনতম OS সংস্করণ উঁচু | **PROPOSED** (Phase 1 spike-এর পর নিশ্চিত) |
| Kotlin Multiplatform + Compose | নেটিভ-ঘেঁষা | iOS/desktop পরিপক্কতা ও আকার UNVERIFIED | বিবেচিত, মূল্যায়ন বাকি |
| প্রতি-platform native (Kotlin/Swift/C#/GTK) | সর্বোত্তম performance | ৫ গুণ কাজ; একক-ডেভেলপারে অসম্ভবপ্রায় | অগ্রহণযোগ্য-প্রবণ |
| Tauri/Rust + WebView | ছোট binary (দাবি — UNVERIFIED) | মোবাইল পরিপক্কতা UNVERIFIED; WebView নির্ভরতা | বিবেচিত, মূল্যায়ন বাকি |

**Fallback শর্ত:** Phase 1 spike-এ Flutter রেফারেন্স ডিভাইসে বাজেট (`PERFORMANCE_REQUIREMENTS.md`) পূরণ না করলে ADR-003 পুনর্বিবেচনা।

## ২. ডেটা ও এনক্রিপশন
| উপাদান | লাইসেন্স | রক্ষণাবেক্ষণ | মন্তব্য |
|---|---|---|---|
| SQLite | UNVERIFIED (public-domain বলে সুপরিচিত, তবে এই session-এ যাচাই হয়নি) | UNVERIFIED | অ্যাপ-অভ্যন্তরীণ ডেটা |
| **SQLCipher Community Edition** | BSD-style, attribution বাধ্যতামূলক (S24, PRIMARY) | সক্রিয় (S24 পাতা) | Full-DB encryption; binary ও CPU overhead UNVERIFIED |
| `sqlcipher_flutter_libs` (pub.dev) | UNVERIFIED | **EOL** (S24) | **ব্যবহার করা যাবে না**; বিকল্প: `sqlite3` Dart প্যাকেজ ৩.x-এর SQLCipher সমর্থন পথ — Phase 1-এ যাচাই |
| Drift (ORM) | UNVERIFIED | UNVERIFIED | Phase 1-এ বিবেচ্য; schema এই Phase-এ নয় |
| বিকল্প: field-level AEAD + সাধারণ SQLite | — | — | Metadata-leak ঝুঁকি বেশি; FTS index এনক্রিপ্ট করা কঠিন → দ্বিতীয় পছন্দ |

## ৩. Credential ও Auth
| উপাদান | মূল্যায়ন |
|---|---|
| OS secure storage | Keychain/Keystore/Credential Manager/libsecret — platform-নেটিভ; Flutter প্লাগইন (`flutter_secure_storage`-ধরন) লাইসেন্স/রক্ষণাবেক্ষণ UNVERIFIED |
| OAuth2 + PKCE | স্ট্যান্ডার্ড (RFC 7636 — সংস্করণ UNVERIFIED); `flutter_appauth`-ধরন লাইব্রেরি বনাম নিজস্ব হালকা client — UNVERIFIED |
| Embedded WebView লগইন | **এড়ানো** (Google embedded-WebView OAuth সীমাবদ্ধ করে বলে সুপরিচিত — এই session-এ যাচাই হয়নি → UNVERIFIED); system browser পছন্দ |

## ৪. Protocol লাইব্রেরি
| বিষয় | বিকল্প | অবস্থা |
|---|---|---|
| IMAP/SMTP | Dart `enough_mail`-ধরন বনাম নেটিভ FFI (যেমন Rust/C লাইব্রেরি) | লাইসেন্স, IDLE/QRESYNC সমর্থন, রক্ষণাবেক্ষণ — **সব UNVERIFIED**; Phase 1 spike |
| WebDAV | Dart-এ থিন নিজস্ব client বনাম প্যাকেজ | UNVERIFIED |
| REST SDK | অফিসিয়াল SDK-র বদলে `dio`/`http` + হালকা নিজস্ব client (binary ছোট; বিক্রেতা SDK সাধারণত ভারী — অনুমান, UNVERIFIED) | PROPOSED |
| **MEGA** | অফিসিয়াল C++ SDK (BSD-2, S07) + FFI/নেটিভ bridge | পুনঃবিতরণ-বান্ধব লাইসেন্স; application key বাধ্যতামূলক (S07); binary আকার UNVERIFIED; ঐচ্ছিক build flavor |

## ৫. Background ও নেটিভ ইন্টারঅপ
Android: Kotlin (WorkManager, foreground service ঐচ্ছিক); iOS/macOS: Swift (BGTaskScheduler, Keychain); Windows/Linux: Dart FFI/প্লাগইন (C++/Rust ছোট শিম)। Flutter প্লাগইন নির্ভরতা ন্যূনতম রাখা।

## ৬. মূল্যায়ন-ছক (Phase 1-এ পূরণ হবে)
প্রতিটি প্রার্থী dependency-র জন্য: লাইসেন্স | শেষ release/রক্ষণাবেক্ষণ | ৫ platform সমর্থন | binary আকার delta | RAM/CPU delta | নিরাপত্তা-ইতিহাস (CVE) | বিকল্প। **গেট:** ছক অসম্পূর্ণ থাকলে dependency গ্রহণ নয়।

## ৭. বর্জন-নীতি
ভারী SDK-সমষ্টি (Firebase পুরো স্যুট, বিশাল analytics), অপ্রয়োজনীয় WebView, ব্যবহারহীন ফন্ট/অ্যাসেট, রানটাইম-কোডজেন-নির্ভর ভারী প্যাকেজ।
