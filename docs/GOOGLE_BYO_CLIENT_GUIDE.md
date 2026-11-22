# Google-এর জন্য নিজস্ব OAuth client (ADR-009) — গাইড
লক্ষ্য: Aethryon-এর কোনো কেন্দ্রীয় Google verification ছাড়াই আপনার নিজের Gmail/Drive সংযোগ। খরচ: শূন্য।
সূত্র: S26 (Google production-readiness পাতা): "Testing" অবস্থায় refresh token ৭ দিনে মেয়াদ-শেষ হয় ও ১০০ test-user সীমা; তাই **"In production"** দরকার; unverified অ্যাপে সতর্কতা-স্ক্রিন আসে (আপনি নিজের অ্যাপকে অনুমতি দিচ্ছেন বলে সেটা গ্রহণযোগ্য)।
1. console.cloud.google.com → নতুন Project (যেকোনো নাম)।
2. APIs & Services → **Library** → "Gmail API" ও/অথবা "Google Drive API" Enable।
3. **OAuth consent screen** → External → অ্যাপের নাম, আপনার ইমেইল → Scopes: Gmail-এর জন্য `https://mail.google.com/` (IMAP/SMTP, S04); Drive-এর জন্য `drive`/`drive.readonly` (S01/S02)।
4. **Publishing status → "Publish app" (In production)**। (Testing রাখলে ৭ দিনে লগআউট হবে।)
5. Credentials → Create → **OAuth client ID → Desktop app** (মোবাইলের জন্য redirect পদ্ধতি Phase ৬-এ)। Client ID (ও দেওয়া থাকলে secret) নোট করুন।
6. অ্যাপে (Phase ৬) Settings → Account যোগ → "Use my own Google client" → Client ID বসান।
সীমা: অনুমোদন-স্ক্রিনে "Google hasn't verified this app" দেখাবে — "Advanced → Continue" চাপতে হবে। Google-এর নীতি বদলাতে পারে (UNVERIFIED স্থায়িত্ব)।
