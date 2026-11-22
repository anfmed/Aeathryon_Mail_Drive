# PHASE_PLAN_1_3 (সম্পাদিত পরিধি)
| Phase | লক্ষ্য | সম্পন্ন (কোড/নথি) | স্থগিত |
|---|---|---|---|
| 1 Foundation | monorepo, shared packages, CI, সিদ্ধান্ত | ৫টি shared package + টেস্ট; CI (core + ৫ platform × ২ অ্যাপ); schema-validator; dependency-gate; app shell | নেটিভ binding, signing, Flutter pin |
| 2 Drive core | adapter-সীমা, capability, transfer, WebDAV | `drive_core`: models, `StorageAdapter`, capability manifest (pooling=UNSUPPORTED), chunk planner (OneDrive 320 KiB), transfer scheduler (Wi-Fi/metered/battery/account-isolation), WebDAV parser+adapter, Drive schema | live-server test, resumable-upload বাস্তবায়ন, অন্য provider, sync engine, offline-cache |
| 3 Mail core | transport-সীমা, sync-কৌশল, threading, outbox | `mail_core`: CAPABILITY parser, sync-কৌশল নির্বাচন, UIDVALIDITY নিয়ম, local threader, outbox state-machine (duplicate-send প্রতিরোধ), provider profile (Proton=companion), Mail schema | IMAP/SMTP transport, OAuth, rendering, search-আসল ব্যবহার |

| 4 Integration ও UI | demo-ডেটায় চলমান UI, sync-সেবা, OAuth-মূল, isolated IMAP | docs/PHASE_4_REPORT.md | অ্যাপে আসল ডেটা-wiring |
| 5 Hardening ও release-প্রস্তুতি | বাস্তব SQLite-পরিমাপ, plain-text মেইল, draft release, গাইড | docs/PHASE_5_REPORT.md | signing, device-পরিমাপ, এনক্রিপশন |
