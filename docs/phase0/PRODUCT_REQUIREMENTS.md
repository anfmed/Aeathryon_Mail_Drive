# PRODUCT_REQUIREMENTS

পর্যালোচনার তারিখ: ২০২৬-১১-১০

## ১. অনুমোদিত সিদ্ধান্ত (ACCEPTED — ব্যবহারকারীর নির্দেশনা অনুযায়ী)
| # | সিদ্ধান্ত |
|---|-----------|
| A1 | অ্যাপের নাম: **Aethryon Drive**, **Aethryon Mail**। দুটি স্বতন্ত্র অ্যাপ। |
| A2 | বাধ্যতামূলক platform: Android, iOS, Windows, Linux, macOS। |
| A3 | Web, PWA, browser-based অ্যাপ target নয়। |
| A4 | Account সংখ্যায় কৃত্রিম সীমা নেই; সীমা আসবে শুধু provider, device resource, API quota ও authentication থেকে। |
| A5 | Monetization: Free core + ঐচ্ছিক paid advanced feature। Core কার্যকারিতা paywall-এর কারণে বন্ধ করা যাবে না। কোন feature free/paid তা **ভবিষ্যতে অনুমোদনসাপেক্ষ** (OPEN)। |
| A6 | Privacy: local-first; ঐচ্ছিক encrypted hybrid sync; কোনো বাধ্যতামূলক Aethryon-hosted cloud নয়; AI ঐচ্ছিক ও বন্ধ থাকলেও core সম্পূর্ণ কার্যকর। |
| A7 | Sync mode ব্যবহারকারী বেছে নেবেন (provider ও feature অনুযায়ী): real-time (যেখানে সম্ভব), background, manual, scheduled, Wi-Fi-only, metered-network restriction। |
| A8 | Lightweight, performance ও modern UI/UX release gate। |
| A9 | Low-resource: ৪ GB RAM desktop ও low-end Android বিশেষভাবে বিবেচ্য। |
| A10 | Development পরিবেশ: Windows 10, ৪ GB RAM, VS Code, Android Studio নয়, local heavy build নয় → GitHub Actions cloud build। |
| A11 | কোনো paid service/credit card বাধ্যতামূলক করে architecture হবে না, যদি না platform-এর অনিবার্য শর্ত হয়। |

## ২. এখনো অনুমোদিত নয় (OPEN/PROPOSED) — ভুলে অনুমোদিত দেখানো হয়নি
- Flutter/Dart চূড়ান্ত পছন্দ (PROPOSED; Phase 1 spike-এর পর নিশ্চিত)।
- Free বনাম paid feature বিভাজন (OPEN)।
- Repository public হবে নাকি private (OPEN; CI খরচে প্রভাব — `BUILD_AND_RELEASE_STRATEGY.md`)।
- Mobile mail push-এর জন্য ঐচ্ছিক relay থাকবে কি না (OPEN; `MAIL_ARCHITECTURE.md` §৬)।
- Apple Developer Program ($99/বছর) গ্রহণ (OPEN; iOS/macOS বিতরণের অনিবার্য শর্ত)।
- Google restricted-scope verification/CASA পথ বনাম "নিজস্ব OAuth client" পথ (OPEN)।
- সর্বনিম্ন OS সংস্করণ (Flutter-এর সীমা অনুসারে Android 7.0 / API 24 — PROPOSED)।

## ৩. Functional requirements (সংক্ষিপ্ত)
### Aethryon Drive
FR-D1 একাধিক provider account যোগ/অপসারণ; FR-D2 unified dashboard; FR-D3 file browser (pagination, lazy); FR-D4 recent/favorites; FR-D5 search (local index + provider search); FR-D6 resumable transfer queue; FR-D7 offline files; FR-D8 storage intelligence (শুধু পঠন-বিশ্লেষণ); FR-D9 sharing (provider সমর্থন অনুযায়ী, capability-gated); FR-D10 destructive action-এ নিশ্চিতকরণ ও recoverability।

**সীমা:** Google Drive API Terms "storage sharding / storage limit circumvention" ধরনের tool নিষিদ্ধ করে (S03)। তাই একাধিক account মিলিয়ে একটি "pooled storage" বা file split করে সংরক্ষণ **প্রস্তাবিত scope-এর বাইরে**। Storage intelligence শুধু বিশ্লেষণ ও পরামর্শ দেবে।

### Aethryon Mail
FR-M1 একাধিক account; FR-M2 unified inbox; FR-M3 folder/label; FR-M4 compose/drafts/sent/archive; FR-M5 search (local FTS + server search); FR-M6 attachment হ্যান্ডলিং (streaming, দ্বিতীয়বার download নয়); FR-M7 offline পঠন ও outbox; FR-M8 thread/conversation (provider অনুযায়ী capability-based); FR-M9 notification (platform-সীমা অনুযায়ী)।

## ৪. Non-functional requirements
পরিমাপযোগ্য বাজেট `PERFORMANCE_REQUIREMENTS.md`-এ। নিরাপত্তা `SECURITY_THREAT_MODEL.md`-এ। Accessibility: screen-reader, keyboard নেভিগেশন, contrast, scalable text — উভয় অ্যাপের release gate।

## ৫. Scope-বহির্ভূত
Web/PWA; বাধ্যতামূলক Aethryon cloud; Provider-এর unsupported capability কে supported দেখানো; কৃত্রিম account সীমা।

## ৬. Acceptance principle
কোনো provider capability `FULL` বলা যাবে না যতক্ষণ না primary source ও ব্যবহারিক পরীক্ষা (Phase 2+) দুটোই আছে।
