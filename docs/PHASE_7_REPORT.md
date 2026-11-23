# Phase 7 — আরও provider ও OAuth: প্রতিবেদন (আংশিক)
**অবস্থা:** core লেখা; UI-তে সংযোগ নেই; অনেক অংশ স্থানান্তরিত।
**করা হয়েছে (pure Dart, mock-tested):**
- `TransferRunner`: **resume-নিয়ম** (partial-ফাইল অফসেটের সঙ্গে না মিললে ফেলে দিয়ে শুরু থেকে — কখনো append নয়), cancellation, আকার-যাচাই; resumable upload (chunk-পরিকল্পনা, সার্ভার-নিশ্চিত অফসেট থেকে পুনরায়শুরু, শূন্য-বাইট ফাইল)।
- `DropboxAdapter` (list+pagination, `asciiJson` হেডার-escape, range download, upload-session start/append/finish, mkdir/move/delete/quota) — **blind**।
- `OneDriveAdapter` (Graph; ৩২০ KiB chunk S11; download-redirect-এ **bearer token ফরওয়ার্ড হয় না**; upload-URL-এ token নেই) — **blind**।
- `oauthSignIn` (loopback + PKCE + state-যাচাই; end-to-end টেস্টে URL-এর challenge = পাঠানো verifier-এর S256) ও `oauthProviders` (scope S01/S02/S04/S09/S11 সূত্রসহ; endpoint অযাচাইকৃত চিহ্নিত)।
**স্থানান্তরিত → Phase ৮:** OAuth "Sign in" UI (`url_launcher`), মোবাইল redirect, Box/pCloud/Google adapter, Dropbox/OneDrive account-UI ও live-যাচাই, স্থানীয় SQLite-সংরক্ষণ, ফাইল upload/download UI।
**Exit gate:** CI সবুজ + (আপনার টেস্ট-account থাকলে) Dropbox/OneDrive live-পরীক্ষা।
