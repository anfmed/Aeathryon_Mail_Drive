# Phase 2 — Drive core: প্রতিবেদন
**অবস্থা:** লেখা সম্পন্ন; build-যাচাই বাকি।
**করা হয়েছে:** `StorageAdapter` (provider-কোড UI-তে নয়); capability manifest — Google Drive `REQUIRES_PERMISSION`, pooling `UNSUPPORTED` (S03), WebDAV-এর অযাচাইকৃত feature `UNVERIFIED` (UI-তে নিষ্ক্রিয়); chunk planner (OneDrive ৩২০ KiB গুণিতক — S11; resume-offset); transfer scheduler (Wi-Fi-only, metered, ব্যাটারি, account-isolation round-robin); WebDAV PROPFIND parser + adapter (retry/Retry-After সহ); Drive schema (আলাদা DB, token-কলাম নেই, cascade-delete)।
**আবিষ্কৃত bug (ঠিক করা):** percent-encoded path বনাম decoded href অমিল (নামে space থাকলে self-entry বাদ পড়ত)।
**পরিচিত সীমা:** upload stream রি-প্লে করা যায় না, তাই upload-retry transfer-manager স্তরে হবে। Live-server test নেই। Trash/quota/search WebDAV-এ নেই।
**Exit gate:** CI-তে parser/planner/scheduler test সবুজ + Nextcloud container-এ integration test (Phase 4)।
