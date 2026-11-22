# Phase 4 — Integration ও UI ভিত্তি: প্রতিবেদন
**অবস্থা:** লেখা সম্পন্ন; build-যাচাই বাকি।
**করা হয়েছে**
- **Mail:** `MemoryMailTransport`; `MailSyncService` (নতুন-মেইল আবিষ্কার, পৃষ্ঠা-ভিত্তিক fetch, UIDVALIDITY রিসেট, account-আলাদা store); `MailStore` ইন্টারফেস + memory impl; `threadHeaders`; transport-ইন্টারফেসে `sendPlain`।
- **`mail_imap` (isolated, blind):** `ImapSmtpTransport` (enough_mail)। `UNVERIFIED-API` চিহ্নিত।
- **Drive:** `MemoryStorageAdapter` (trash পুনরুদ্ধারযোগ্য, move কখনো নীরবে overwrite করে না), `sortNodes` (ফোল্ডার আগে), `BrowseState`, `formatBytes`; WebDAV `Authorization` ঐচ্ছিক (null = নেই)।
- **Auth:** `buildAuthorizationUrl` (PKCE S256), `verifyState` (constant-time), `exchangeCode`/`refreshTokens` (error-এ response-body ফাঁস হয় না; refresh-token অনুপস্থিত হলে পুরোনোটি রাখে), desktop `LoopbackReceiver`, `SecureTokenStore` (namespace দিয়ে Drive/Mail আলাদা), `MemorySecureStore`।
- **Isolated wrappers:** `aethryon_secure_store_flutter` (flutter_secure_storage)।
- **Design:** `aethryon_design` (token, light/dark theme, `StatusBadge` — রঙ ছাড়াও টেক্সট+আইকন, Semantics)।
- **UI (দুই অ্যাপ):** responsive shell (বড় স্ক্রিনে NavigationRail, ছোটতে NavigationBar); Drive: ফাইল-ব্রাউজার (loading/empty/error), ট্র্যাশ-এ **নিশ্চিতকরণ + Undo**, Providers স্ক্রিন (unverified কখনো supported দেখায় না); Mail: ইনবক্স (sync, "Conversation" চিহ্ন), বার্তা-পাঠ (plain text), Compose (যাচাই + ত্রুটি-বার্তা), Providers (Proton = requiresCompanion)। Widget test ৭টি।
- **CI:** `ci-core` এখন ৪ job (core, webdav-live, apps, isolated)।
**না করা:** IMAP/secure-store/OAuth অ্যাপে wiring (ADR-024); মোবাইল OAuth redirect; CONDSTORE flag-sync; আসল provider endpoint; স্থানীয় ডেটা-এনক্রিপশন; offline-state UI (demo-তে অপ্রযোজ্য)।
**Exit gate:** `ci-core`-এর `core`+`apps`+`webdav-live` সবুজ; `isolated`-এর ব্যর্থতা-তালিকা নিষ্পত্তি।
