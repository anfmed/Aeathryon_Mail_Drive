# DECISIONS_PHASE_1_3 — লক্ষ্য-ভিত্তিক সিদ্ধান্ত

তারিখ: ২০২৬-১১-১০ | ক্ষমতা: ব্যবহারকারী নির্দেশ দিয়েছেন — "লক্ষ্যের সঙ্গে যেটা মেলে সেটাই নির্বাচন করো, লক্ষ্যের বাইরে যেও না"।

## লক্ষ্য-ছাঁকনি (প্রতিটি সিদ্ধান্ত এই ৭টি দিয়ে যাচাই)
G1 হালকা/দ্রুত/কম-ব্যাটারি · G2 Local-first, বাধ্যতামূলক Aethryon cloud নয় · G3 Free core, বাধ্যতামূলক paid নয় (অনিবার্য ব্যতিক্রম ছাড়া) · G4 ৫টি platform, Web নয় · G5 ৪ GB Windows মেশিন, cloud build · G6 নিরাপদ, কোনো plain-text credential নয় · G7 Unsupported কখনো supported দেখানো নয়।

## Phase 0-এর OPEN সিদ্ধান্ত — এখন সমাধান
| ADR | সিদ্ধান্ত | কেন (লক্ষ্য) | শর্ত/ফেরার পথ |
|---|---|---|---|
| 003 | **Flutter/Dart গৃহীত — শর্তসাপেক্ষ** | G4+G5: ৫ platform একক codebase-এ একমাত্র বাস্তবসম্মত পথ (প্রতি-platform native ৫ গুণ কাজ) | Phase 4-এর প্রথম gate: P-01/P-02/P-03 রেফারেন্স ডিভাইসে মাপা। ব্যর্থ হলে TECH_STACK বিকল্প পুনর্মূল্যায়ন |
| 007 | **Push relay নেই** (Phase 1–৩ ও ডিফল্টে) | G2: Gmail push-এ backend লাগে (S05) যা বাধ্যতামূলক cloud-নীতি ভাঙে | Desktop: IDLE; mobile: periodic fetch (`PARTIAL`, UI-তে সৎ বার্তা)। ঐচ্ছিক self-host relay Phase 6+ এ পুনর্বিবেচ্য |
| 008 | **Apple Developer Program এখন কেনা হবে না; CI-তে শুধু `--no-codesign` কম্পাইল-যাচাই** | G3: paid কেবল অনিবার্য হলে — এখন অনিবার্য নয় (কম্পাইল-যাচাই সাইনিং ছাড়াই) | বিতরণ-milestone এ (TestFlight/App Store/notarization) সদস্যপদ অনিবার্য (S22) — তখন আপনার অনুমোদন |
| 009 | **Google: BYO OAuth client ডিফল্ট; verified-client পরে ঐচ্ছিক** | G3+G2: verification/CASA বাধ্যতামূলক খরচ ও কেন্দ্রীয় প্রক্রিয়া এড়ায়। ব্যবহারকারী নিজের Google Cloud client বানান, "In production" করেন → Testing-এর ৭-দিনের refresh-expiry নেই; unverified সীমা ~১০০ ব্যবহারকারী/client (প্রতি-ব্যবহারকারী নিজস্ব client হলে অপ্রাসঙ্গিক) — S26 | UX ঘর্ষণ বেশি (গাইড লাগবে)। পরবর্তীতে verified shared client = বার্ষিক CASA (সেকেন্ডারি: ≥প্রতি ১২ মাস) — আপনার আলাদা সিদ্ধান্ত |
| 010 | **Repository public** | G3: private repo-তে macOS মিনিট ×১০ (S21) দ্রুত শেষ → macOS/iOS build অসম্ভব হতে পারে; public-এ CI বিনামূল্যে (S21) | Secrets কখনো repo-তে নয়। লাইসেন্স আলাদা (ADR-021) |
| 011 | Monorepo গৃহীত | G5: একটি clone, একটি IDE | — |
| 012 | Mail: **IMAP/SMTP-first**; প্রার্থী লাইব্রেরি `enough_mail` | G1: একটি transport সব provider; pub.dev docs অনুযায়ী MPL-2.0 এবং IDLE, CONDSTORE, QRESYNC, MOVE, THREAD, SORT সমর্থিত (S27) | রক্ষণাবেক্ষণ-অবস্থা UNVERIFIED; MPL-2.0 ফাইল-স্তরের copyleft (সংশোধিত ফাইল শেয়ার করতে হয়); Phase 4 spike |
| 013 | কোনো storage pooling/sharding নেই | G7: Google Drive ToS নিষিদ্ধ করে (S03) | `buildDriveRegistry` এ `UNSUPPORTED` হিসেবে কোডিত |
| 014 | Free/paid বিভাজন **Phase 1–৩ এ কোড করা হয়নি** | A5 (আপনার অনুমোদিত নীতি): চূড়ান্ত বিভাজন ভবিষ্যতে অনুমোদনসাপেক্ষ; এখন কোনো feature-gating নেই, core কখনো paywall-এ নয় | Phase 6+ |
| 015 | ন্যূনতম OS = Flutter-এর সমর্থিত সর্বনিম্ন (S23); চূড়ান্ত pin Phase 4-এ | G4 | সংস্করণ-বিভ্রান্তি (R-19) |
| 016 | **MEGA Phase 1–৩ এর বাইরে** | G7+G1: বর্তমান ToS/application-key নীতি অজানা (S07/S08), native SDK binary ভারী হতে পারে | ToS যাচাই হলে ঐচ্ছিক flavor |
| 017 | Proton: desktop-only via Bridge, Bridge bundle নয়, mobile `UNSUPPORTED` | G7 (S17) | কোডে `mobileSupported:false`, `requiresCompanion` |
| 018 | HTML-mail: Phase 1–৩ এ কোনো renderer নেই; Phase 4: plain-text + কঠোর sanitizer; WebView ডিফল্টে নয় | G1+G6 | নিজে-লেখা sanitizer নিরাপত্তা-ঝুঁকিপূর্ণ — যাচাইকৃত লাইব্রেরি মূল্যায়ন Phase 4 |
| 019 | Drive-এ প্রথম provider = **WebDAV/Nextcloud**; পরে OneDrive, Dropbox, Box, pCloud; Google BYO; MEGA শেষে | G3: কোনো developer-approval, কোনো paid নেই; self-host/ফ্রি সার্ভারে পরীক্ষা সম্ভব | — |
| 020 | Mail-এ প্রথম provider = generic IMAP + iCloud (app-password) + Proton Bridge; পরে Outlook OAuth, Yahoo, Gmail BYO | G3: OAuth-অনুমোদন-মুক্ত পথ আগে | — |
| 021 | **সফটওয়্যার-লাইসেন্স: নির্ধারিত নয়** (NOTICE.md) | ব্যবসায়িক সিদ্ধান্ত (free core + paid advanced) আপনার লক্ষ্যের মূল অংশ — আমি অনুমান করে বেছে নিইনি | open-source বনাম source-available আপনার সিদ্ধান্ত |

## নতুন source (এই ধাপে)
- **S26** https://developers.google.com/identity/protocols/oauth2/production-readiness/overview — PRIMARY — Testing: ১০০ test-user সীমা ও ৭ দিনে refresh-token মেয়াদ; Published+unverified: কড়া ~১০০-ব্যবহারকারী সীমা ও সতর্কতা-স্ক্রিন; sensitive/restricted scope-সহ পাবলিক অ্যাপে verification আবশ্যক। (পর্যালোচনা ২০২৬-১১-১০)
- **S27** https://pub.dev/documentation/enough_mail/latest/ — PRIMARY (pub.dev) — features ও MPL-2.0।
- **S28** (সেকেন্ডারি) গিটহাব README/পোস্ট: CASA অন্তত প্রতি ১২ মাসে পুনরাবৃত্ত; BYO-client প্যাটার্ন — Google-এর নিজস্ব CASA পাতা এখনো যাচাই হয়নি।

## যা এখনো অজানা (সিদ্ধান্তে প্রভাব ফেলতে পারে)
Local-only অ্যাপের CASA-ছাড় আছে কি না (S26 এটি নিশ্চিত করে না); Flutter বর্তমান stable ট্যাগ; `enough_mail` সক্রিয় রক্ষণাবেক্ষণ; MEGA ToS; WebDAV/IMAP RFC-পর্যালোচনা।

---
# Phase ৪–৫ সিদ্ধান্ত (লক্ষ্য-ভিত্তিক)
| ADR | সিদ্ধান্ত | লক্ষ্য | টীকা |
|---|---|---|---|
| 022 | State management: Flutter-এর নিজস্ব `setState`/`FutureBuilder`; কোনো তৃতীয়-পক্ষ state প্যাকেজ নয় | G1 হালকা, কম dependency | জটিলতা বাড়লে পুনর্বিবেচনা |
| 023 | মেইল রেন্ডারিং v1 = **শুধু plain text** (HTML→text, ডিফল্টে কোনো HTML/JS/রিমোট ছবি নয়) — ADR-018 নিষ্পত্তি | G1+G6 | রিচ-HTML পরে, যাচাইকৃত sanitizer-সহ |
| 024 | **Isolation নীতি:** blind-লেখা/৩য়-পক্ষ API-কোড (`mail_imap`, secure-store wrapper) আলাদা package ও আলাদা CI job (`continue-on-error`), যাতে ব্যর্থতা বাকিকে আটকায় না। অ্যাপে wiring শুধু সবুজ হওয়ার পর | G7 সততা, G5 | `UNVERIFIED-API` মার্কার |
| 025 | Release = **unsigned draft release** (Android APK/Windows ZIP/Linux tar.gz + SHA256); signing ও macOS/iOS স্বয়ংক্রিয় নয় | G3 | ADR-008 অপেক্ষমাণ |
| 026 | WebDAV integration-test সার্ভার = `wsgidav` (Python), Nextcloud container নয় | G1/G5 CI মিনিট কম | Nextcloud-নির্দিষ্ট আচরণ পরে |
| 027 | OAuth: desktop = loopback (RFC 8252); mobile redirect স্থগিত; IMAP OAuth শুধু যাচাইকৃত পথে | G6 | `authenticateWithOAuth2` enough_mail docs-এ আছে |
| 028 | Mobile background sync = periodic fetch; push relay নেই (ADR-007) | G2 | — |
| 029 | **Apple (iOS ও macOS) সম্পূর্ণ বাদ** — CI/release কোথাও নেই; Phase ১০-এ, আপনি চাইলে | ব্যবহারকারীর নির্দেশ + G3 | আগে Android+Windows, তারপর Linux (ঐচ্ছিক checkbox) |
| 030 | **Build-গেট:** `build-apps` = `check` (analyze+test) সফল হলেই build; ত্রুটিযুক্ত কোড build হয় না | ব্যবহারকারীর নির্দেশ | infos fatal নয়; errors+warnings fatal |
| 031 | **Auto-format (সংশোধিত, ADR-033):** প্রতিটি push-এ `format` workflow `dart format` চালিয়ে commit ফেরত পাঠায় (`[skip ci]`, bot-actor বাদ — লুপ নেই) | ব্যবহারকারীর নির্দেশ | ফলে push-এর পর `git pull` লাগতে পারে |
| 032 | CI স্ক্রিপ্ট সবসময় `bash tools/x.sh` দিয়ে চালানো (executable-bit ভরসা নয়); ZIP `zip` কমান্ডে | প্রথম CI-ব্যর্থতার শিক্ষা | — |
| 033 | **Workflow মাত্র ২টি:** `format` (প্রতিটি push-এ নিজে, কোনো path/branch ফিল্টার নেই) ও `ci` (হাতে: check→build, ঐচ্ছিক Linux/extra/draft-release)। আলাদা `ci-core`/`build-apps`/`release` বাতিল | ব্যবহারকারীর নির্দেশ; কম বিভ্রান্তি | প্রথম `format` না চলার কারণ: ফিল্টার ছিল `**.dart` পরিবর্তনে, কিন্তু v2 push-এ কোনো .dart বদলায়নি (সম্ভাব্য; branch-নাম `main` না হলেও চলত না) |
| 034 | CI-তে `flutter analyze --no-fatal-infos`: error ও **warning** build আটকায়, info আটকায় না | G7 + অকারণ-ব্লকিং এড়ানো | প্রথম আসল ব্যর্থতা: test ফাইলে unused import (warning) |

---
# Phase ৬–৭ সিদ্ধান্ত (লক্ষ্য-ভিত্তিক)
| ADR | সিদ্ধান্ত | লক্ষ্য | টীকা |
|---|---|---|---|
| 035 | **এনক্রিপ্টেড স্থানীয় DB:** `package:sqlite3` ৩.x-এর build-hook দিয়ে `sqlite3mc` (SQLite3MultipleCiphers) বনাম `sqlcipher` — সিদ্ধান্ত **CI-spike-এর ফলের পর**। প্রত্যাশা: `sqlite3mc` (OpenSSL-মুক্ত, ছোট)। শর্ত: FTS5 কাজ করতে হবে। (হুক-সেটিং শুধু **root package**-এর pubspec থেকে পড়া হয় — ফলে সেটি অ্যাপ-pubspec-এ যাবে) | G1 + G6 | সূত্র: pub.dev sqlite3 hook-options (PRIMARY)। `sqlcipher_flutter_libs` EOL (S24) |
| 036 | আসল account আগে **OAuth-মুক্ত পথে**: WebDAV/Nextcloud (app-password), IMAP (app-password: iCloud/Yahoo/generic)। Gmail/Outlook = OAuth UI আসা পর্যন্ত UI-তে সৎ ব্যাখ্যাসহ **আটকানো** | G3 + G7 | `connectBlockedReason` |
| 037 | Password **শুধু OS secure store-এ** (`AccountVault`); account-metadata-তে secret-জাতীয় key গ্রহণযোগ্য নয়; সার্ভার-URL **https বাধ্যতামূলক** (http শুধু loopback) | G6 | — |
| 038 | যাচাই-না-হওয়া provider (Dropbox, OneDrive) = adapter + mock-test আছে, কিন্তু **UI-তে নির্বাচনযোগ্য নয়**; live-test পাস করলে তবেই | G7 | capability `UNVERIFIED` |
| 039 | যে provider-এ trash নেই সেখানে মোছা = "চিরতরে মোছা" লিখিত স্পষ্ট নিশ্চিতকরণ, Undo নেই | G6 recoverability | — |
| 040 | **Retry-নিরাপত্তা:** body প্রতি attempt-এ নতুন করে বানানো; upload-stream স্বয়ংক্রিয় retry হয় না; ত্রুটি-বার্তায় response-body/token থাকে না; **bearer token কখনো pre-authenticated URL-এ পাঠানো হয় না** (OneDrive download/upload) | G6 | প্রথম live-CI-র শিক্ষা |
| 041 | Proton Bridge সংযোগ এখনো বাস্তবায়িত নয় (STARTTLS-পথ অযাচাইকৃত) → UI-তে আটকানো | G7 | — |

---
# Phase ৮–৯ সিদ্ধান্ত (লক্ষ্য-ভিত্তিক; Apple/macOS বাদ)
| ADR | সিদ্ধান্ত | লক্ষ্য | টীকা |
|---|---|---|---|
| 042 | **এনক্রিপ্টেড DB = `sqlite3mc`** (OpenSSL-মুক্ত, ছোট)। একটি শব্দ (`source:`) বদলে `sqlcipher` করা যায় — **CI `db-spike`-এর ফল** অনুযায়ী নিশ্চিত/বদল। (ADR-035-এর নিষ্পত্তি) | G1 + G6 | হুক-সেটিং দুই অ্যাপের pubspec-এ (root) |
| 043 | **নীরব plaintext নিষিদ্ধ:** cipher সক্রিয় না থাকলে ডিস্কে কিছু লেখা হয় না; অ্যাপ মেমরি-মোডে চলে ও Settings-এ কারণ দেখায় | G6 + G7 | plain SQLite `PRAGMA key` চুপচাপ উপেক্ষা করে — তাই স্পষ্ট পরীক্ষা |
| 044 | DB-তে **শুধু পুনর্নির্মাণযোগ্য cache** (Drive: নাম/আকার; Mail: header)। body/attachment/password কখনো নয়; key হারালে cache নতুন | G6 | — |
| 045 | **ব্যাকগ্রাউন্ড service নেই (v1):** শুধু অ্যাপ-খোলা অবস্থায় polling (`PollScheduler`, ব্যর্থতায় backoff, অ্যাপ-ব্যাকগ্রাউন্ডে বন্ধ)। Android WorkManager/Windows ট্রে — plugin-খরচ/ব্যাটারি মেপে পরে | G1 (ব্যাটারি, হালকা) | মেইল push নেই (ADR-007) |
| 046 | Dropbox/OneDrive = **opt-in "experimental"** টগল + অ্যাকাউন্ট-পর্যায়ের **self-test** (নিজেই পরিষ্কার করে; secret/নাম রিপোর্টে নেই) | G7 | live-যাচাই = আপনার account-এ |
| 047 | সব OAuth-এ **নিজস্ব client ID** (BYO); Aethryon কোনো client ID/secret পাঠায় না | G3 + G2 | ADR-009 |
| 048 | **Release:** Android = আপনার keystore-এ `apksigner` (secrets থাকলে), নইলে debug-সই preview; Windows = unsigned zip + SmartScreen নোট; Linux = tar.gz; package-id `com.aethryon.*` | G3 | `RELEASE_GUIDE.md` |
| 049 | অ্যাপের নাম "Aethryon Drive/Mail"; Android backup বন্ধ; build-number = CI run-number | G6 | CI-patch best-effort |
| 050 | ডাউনলোড: desktop = `Downloads/Aethryon`; ফোন = অ্যাপ-documents/`Aethryon` (SAF save-dialog নয় — অতিরিক্ত plugin এড়াতে); নাম sanitize; কখনো overwrite নয় | G1 + G6 | ফোনে ফাইল-ম্যানেজার দিয়ে দেখতে হবে |
| 051 | Upload: ≤৪ MiB বা non-resumable provider ⇒ একক stream-request; বড় + resumable provider ⇒ session | G1 (RAM) | WebDAV-এ resume নেই |
| 052 | **কোনো telemetry/analytics/crash-report নেই**; Diagnostics শুধু স্থানীয়, ব্যবহারকারী নিজে কপি করে | G2 + G6 | Privacy Policy খসড়া |

---
# Welcome / About / Support / Feedback (লক্ষ্য-ভিত্তিক)
| ADR | সিদ্ধান্ত | লক্ষ্য | টীকা |
|---|---|---|---|
| 053 | দুটি নতুন package: `aethryon_brand_core` (pure Dart: credits, **কেন্দ্রীয় link-সেবা**, URL-নিরাপত্তা, feedback client — `dart test`-এ পরীক্ষিত) ও `aethryon_brand` (Flutter UI)। দুই অ্যাপ একই কোড ব্যবহার করে — নকল নেই | G1 | — |
| 054 | **Link একটিই উৎস:** `LinkConfigService.links` (`getInTouchUrl`, `supportUrl`)। About-এর দুই বোতাম ও আলাদা Support বোতাম সবাই এখান থেকে পড়ে। অগ্রাধিকার: সর্বশেষ **বৈধ** AUS মান → স্থানীয় cache → ডিফল্ট (`https://aethryon-labs.sh010.workers.dev/` ও `…/support/`) | — | ডিফল্ট-literal শুধু `links.dart`-এ |
| 055 | **AUS-সংযোগ:** `GET {AUS_BASE_URL}/v1/links`, ≥৬ ঘণ্টা ব্যবধানে (throttle), ১০ সেকেন্ড timeout, ≤৬৪ KB, ব্যাকগ্রাউন্ডে, ব্যর্থতায় নীরব। `AUS_BASE_URL` build-সময়ে `--dart-define` (CI-তে GitHub **Variable**; secret নয়, কারণ URL সর্বজনীন)। খালি থাকলে নেটওয়ার্ক-কলই হয় না | G2 + G6 | **response-আকার আমি জানি না** — logical নাম `get_in_touch_url`/`support_url` (camelCase ও `links`/`data`-এর ভেতরেও) গ্রহণ করে; `docs/central-links.md` পেলে মিলিয়ে নেব |
| 056 | **URL-নিয়ম:** শুধু `https`, host বাধ্যতামূলক, ভেতরে user:pass নয়, ফাঁকা-স্থান নয়, ≤২০৪৮ অক্ষর। remote মান **প্রতি-ঘর** যাচাই — অবৈধটি বৈধ মানকে কখনো বদলায় না। খোলার আগেও আবার যাচাই (`openLink`), ব্যর্থতায় snackbar | G6 | `javascript:`, `file:`, `intent:`, `http:` সবই প্রত্যাখ্যাত |
| 057 | **Welcome:** প্রথম চালুতে একবার; স্থায়ী ফ্ল্যাগ `welcomeDone` অ্যাপের বিদ্যমান preference-JSON-এ (অন্য ফ্ল্যাগ মুছে না — টেস্টসহ); back/Get Started দুই-ভাবেই "দেখানো হয়েছে" ধরা হয়; কোনো feedback-অনুরোধ নেই | — | ডেটা মুছলে/পুনরায় install-এ আবার দেখাবে (অনুমোদিত) |
| 058 | **Support বোতাম:** ছোট `FilledButton.tonalIcon` (আইকন + "Support"), রঙ থিমের tertiary-accent থেকে, Files/Inbox toolbar-এর **ডান কোণ** (খালি জায়গা; Mail-এ refresh-এর বাঁয়ে); ৪৮dp tap-target; overlap-পরীক্ষা টেস্টে | — | থিমে tertiary না থাকলে `colorSchemeSeed` নিজে বানায় |
| 059 | **Feedback:** Settings-এ "Send feedback" (welcome-এ নয়); `POST {AUS}/v1/feedback` মালিকের দেওয়া চুক্তি অনুযায়ী (source=অ্যাপ-id, message ৩–২০০০, category, ঐচ্ছিক contact, appVersion, platform, `website:""`); ২০২⇒ধন্যবাদ+টেক্সট মোছা, ব্যর্থ/৪২৯⇒টেক্সট রাখা; **কোনো device-id/IP নয়** | G6 | `AUS_APP_ID` ডিফল্ট `com.aethryon.drive_app` / `com.aethryon.mail_app` — আপনার অ্যাপ-id আলাদা হলে বদলান |
| 060 | **Logo:** আপনার আপলোড করা অফিসিয়াল PNG, অনুপাত ১:১ অক্ষুণ্ণ, `1254px → 640px` (১,০৯২ KB → ২৭৬ KB, আকার-লক্ষ্যের জন্য); সাদা গোলাকার টাইলে বসে (logo-র পটভূমি হালকা, তাই dark theme-এও বিকৃত হয় না); নিজে কোনো logo বানানো/বদলানো হয়নি | G1 | `packages/aethryon_brand/assets/branding/aethryon_labs_logo.png` |
| 061 | Credits-কাঠামো `Credits(organization, developers[])` — কোম্পানি ও ব্যক্তি আলাদা; নতুন developer যোগ = তালিকায় এক লাইন | — | — |
