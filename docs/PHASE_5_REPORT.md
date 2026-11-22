# Phase 5 — Hardening, পরিমাপ-সরঞ্জাম, release-প্রস্তুতি: প্রতিবেদন
**অবস্থা:** লেখা ও চালানো-যায়-এমন অংশ চালানো হয়েছে; বাকি build-যাচাই বাকি।
**করা হয়েছে**
- **বাস্তব পরিমাপ (চালানো হয়েছে):** `tools/bench_sqlite.py` — ৫ লক্ষ মেইল-header + ১ লক্ষ FTS, ৫ লক্ষ ফাইল-node। ফল (`docs/bench_sqlite_result.json`, SQLite 3.45.1): ইনবক্স প্রথম পৃষ্ঠা p95 ≈ ০.০৪ ms; মেইল-FTS prefix p95 ≈ ০.১০ ms; Drive-FTS (৫ লক্ষ) p95 ≈ ০.১৪ ms; ফোল্ডার-তালিকা p95 ≈ ০.২৭ ms; FTS-বিল্ড ১ লক্ষ মেইল ≈ ০.৩ s, ৫ লক্ষ node ≈ ১.২ s। **ব্যাখ্যা:** in-memory, warm cache, desktop CPU, SQLCipher ছাড়া → স্টোরেজ-স্তর ডেস্কটপে বাধা নয়, এটুকুই বলা যায়; low-end ফোনে/ডিস্কে/এনক্রিপশনসহ মান **UNVERIFIED**।
- **নিরাপদ মেইল-প্রদর্শন:** `htmlToPlainText` (script/style/comment/ট্যাগ বাদ, entity decode, আউটপুট শুধু টেক্সট; tracking-pixel কখনো লোড হয় না) — **sanitizer নয়, এড়িয়ে যাওয়ার নকশা** (ADR-023)।
- **Release:** `release.yml` — unsigned APK/ZIP/tar.gz + SHA256 + **draft** release।
- **নথি:** USER_ACTION_CHECKLIST, GOOGLE_BYO_CLIENT_GUIDE, MEASUREMENT_PROTOCOL, STORE_READINESS, আপডেটেড DECISIONS/LIMITATIONS/DEPENDENCY_GATE।
**না করা:** signing; macOS/iOS release; device-পরিমাপ; SQLCipher সমাধান; নিরাপত্তা/accessibility নিরীক্ষা; Privacy Policy-র আসল পাঠ।
**Exit gate:** CI সবুজ + আপনার ডিভাইস-পরিমাপ (Checklist #9) + লাইসেন্স-সিদ্ধান্ত।
