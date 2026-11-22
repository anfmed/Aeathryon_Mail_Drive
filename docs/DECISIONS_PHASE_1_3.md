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
