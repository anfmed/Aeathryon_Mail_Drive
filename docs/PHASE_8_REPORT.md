# Phase 8 — স্থায়িত্ব, সংযোগ, sync: প্রতিবেদন
**অবস্থা:** লেখা সম্পন্ন; নতুন কোড CI-তে অচালিত। (প্রথমে লাল ফিক্স: loopback port।)
**৮ক**
- `aethryon_store`: এনক্রিপ্টেড SQLite (`sqlite3mc` — ADR-042), **নীরব-plaintext-নিষিদ্ধ** নিয়ম (043), key ২৫৬-বিট secure store-এ, নষ্ট/হারানো key ⇒ cache নতুন, `DriveStore` (নাম-cache + FTS-search, upsert-diff, favorites নিরাপদ), `SqliteMailStore` (header + flags + FTS; body নয়), নিরাপদ FTS-query।
- **Mail:** বার্তার body (`fetchBody`, plain text), OAuth sign-in UI (Gmail/Outlook, নিজস্ব client), token-refresh (`OAuthTokenSource`, একসঙ্গে একটিই refresh), অফলাইনে সংরক্ষিত header + ব্যানার, স্থানীয় ক্যাশ-সহ চালু।
- **Drive:** ডাউনলোড/আপলোড UI + Transfers (অগ্রগতি, বাতিল, অর্ধেক ফাইল মুছে ফেলা, নাম sanitize, overwrite নয়), অফলাইন-তালিকা, Search (cache-এ), Dropbox/OneDrive sign-in (experimental টগল), **account self-test**।
**৮খ (যা সম্ভব ছিল)**
- **flag-sync ও deletion-শনাক্তকরণ** (`CONDSTORE changed-since` / uid-scan fallback / `fetchUids` তুলনা) — Memory ও SQLite দুই store-এ টেস্টসহ।
- **Foreground auto-refresh** (`PollScheduler`; backoff; অ্যাপ-ব্যাকগ্রাউন্ডে বন্ধ) + Settings।
- **ডিভাইস-পরিমাপের সরঞ্জাম:** Diagnostics-কার্ড (first-frame, RSS now/peak, Copy)।
**স্থগিত (কারণসহ):** Google Drive/Box/pCloud adapter (আসল docs না পড়ে blind নয়); live-provider-যাচাই (আপনার account লাগে — self-test দেওয়া); background sync (ADR-045); ডিভাইস-performance (ডিভাইস লাগে); Wi-Fi-only/metered; mail-search UI; attachment।
**Exit gate:** `ci` সবুজ + `db-spike` ফল + আপনার ডিভাইস-পরিমাপ।
