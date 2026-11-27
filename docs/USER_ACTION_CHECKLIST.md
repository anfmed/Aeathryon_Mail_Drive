# USER_ACTION_CHECKLIST — আপনাকে যা যা করতে হবে (ক্রমানুসারে)

## 0. ⚠ নতুন ZIP বসানোর নিরাপদ নিয়ম (merge কখনো লাগবে না)
`format` workflow প্রতি push-এর পর নিজে একটি commit পাঠায়। তাই **ক্রম গুরুত্বপূর্ণ** — আগে `pull`, তারপর ZIP-এর ফাইল বসানো:
```
git pull                      # ১) আগে সবচেয়ে নতুন অবস্থা নিন (কোনো বদল তখনো করেননি, তাই conflict অসম্ভব)
# ২) ZIP থেকে ফাইলগুলো repo-র ফোল্ডারে কপি করে overwrite করুন
git add -A
git commit -m "v7"
git push                      # ৩) কোনো "rejected" এলে নিচের "যদি rejected আসে" দেখুন
```
**যদি `rejected (fetch first)` আসে** (মানে আপনি কাজ করার সময় `format` নতুন commit পাঠিয়েছিল): merge করবেন না — নিজের বদলগুলো ZIP থেকে আবার বসান:
```
git reset --hard origin/main  # ⚠ আপনার স্থানীয় অ-push বদল মুছে যায় (ZIP-এ সবই আছে)
git pull
# ZIP থেকে আবার overwrite → git add -A → git commit -m "v7" → git push
```
**`git pull -X ours` আর কখনো নয়** — এটি `format`-এর বদল ও আমার বদল মিশিয়ে ভাঙা কোড বানিয়েছিল (v6-এ `main.dart` ভেঙেছে এভাবেই)।
**আজকের ভাঙা অবস্থা ঠিক করতে:** উপরের "rejected" নিয়মই (reset → pull → ZIP v7 overwrite → commit → push)।

## A. এখনই (বাধ্যতামূলক, বিনামূল্যে)
এখন মাত্র **২টি workflow**: `format` (নিজে চলে) ও `ci` (আপনি হাতে চালান)।
1. ☐ GitHub-এ **public** repository (ADR-010)।
2. ☐ ZIP unzip করুন; `aethryon-repo/`-এর **ভেতরের** ফাইলগুলো repo-র root-এ রাখুন, আগের ফাইল overwrite করুন। **পুরোনো workflow ফাইল মুছে দিন:** `.github/workflows/ci-core.yml`, `build-apps.yml`, `release.yml` (এগুলো এখন `ci.yml`-এর ভেতরে)। `.github` লুকানো ফোল্ডার — "Hidden items" চালু করুন।
3. ☐ একবার push করুন। কোনো key/secret ফাইল যোগ করবেন না।
4. ☐ push করার সঙ্গে সঙ্গে Actions-এ **`format`** নিজে চলবে (এখন প্রতিটি push-এ, কোনো ফিল্টার ছাড়া)। শেষ হলে বদল থাকলে সে একটি commit ফেরত পাঠায় → নিজের কম্পিউটারে `git pull` করুন।
   - `format` যদি push ধাপে `403` দিয়ে ব্যর্থ হয়: GitHub → Settings → Actions → General → **Workflow permissions → "Read and write permissions"** → Save।
5. ☐ Actions → **`ci`** → *Run workflow*। এটি প্রথমে **check** (analyze + test) চালায়:
   - check-এ **ত্রুটি থাকলে build চলবে না**। তখন ব্যর্থ job-এর নাম ও লগের শেষ ~৪০ লাইন (ত্রুটির লাইনগুলোসহ) আমাকে পাঠান।
   - সফল হলে Android + Windows build (দুই অ্যাপ × ২ = ৪ job)।
   - Run workflow-এর সময় ঐচ্ছিক টিক: **Linux-ও build** · **অতিরিক্ত পরীক্ষা** (WebDAV live, mail_imap — ব্যর্থ হলেও build আটকায় না) · **draft release**। iOS/macOS নেই।
6. ☐ build সফল হলে Artifacts থেকে `*-android` (APK) ও `*-windows` (ZIP) নামিয়ে পরীক্ষা করুন; মন্তব্য/স্ক্রিনশট পাঠান।

## A+. Phase ৬–৭ পরীক্ষা (v4 push-এর পর)
- ☐ `ci` → Run workflow; এবার **"অতিরিক্ত পরীক্ষা"-ও টিক দিন**। এতে দুটি জিনিস আসবে যা আমি দেখতে চাই: (১) `webdav-live` (ফিক্স কাজ করল কি না), (২) `db-spike` ×৪ (এনক্রিপ্টেড DB: Ubuntu+Windows × sqlite3mc/sqlcipher; ধাপের Summary-তে লাইব্রেরির আকারও থাকবে)।
- ☐ ফল পাঠান: প্রতিটি ব্যর্থ job-এর নাম + ত্রুটির লাইন; সবুজ হলে শুধু "সবুজ"। `db-spike` Summary-র আকার-তালিকাটি কপি করে দিলে ভালো।
- ☐ (ঐচ্ছিক, আমার জন্য বেশ কাজের) আসল account দিয়ে পরীক্ষা — **চ্যাটে কিছু পাঠাবেন না, অ্যাপে নিজে বসান**:
  - Drive অ্যাপ → Accounts → Add account → আপনার Nextcloud/WebDAV (https, app-password) → "Test connection" → ফাইল দেখা যায় কি?
  - Mail অ্যাপ → Accounts → Add → iCloud (app-specific password) বা অন্য IMAP → ইনবক্সের subject-তালিকা আসে কি? (এটাই `mail_imap`-এর প্রথম আসল পরীক্ষা)
  - ফল জানান: কাজ করেছে / কোন ত্রুটি-বার্তা এসেছে (বার্তা অক্ষরে অক্ষরে)। password/ঠিকানা পাঠাবেন না।

## A++. Phase ৮–৯ (v5): ধাপে ধাপে
1. ☐ ZIP-এর ফাইল দিয়ে overwrite → push → `format` শেষে `git pull`।
2. ☐ `ci` চালান — **"অতিরিক্ত পরীক্ষা"-ও টিক দিন**। এখন চেক-ধাপ **সব ব্যর্থতা একসাথে** দেখায় (`FAILED PACKAGES: …` / `FAILED: …` লাইন)। লাল হলে: ওই লাইনটি + প্রতিটি ব্যর্থ package-এর ত্রুটির লাইন পাঠান। ⚠ সবচেয়ে সম্ভাব্য লাল: Android/Windows **Build** ধাপে `sqlite3` hook বা plugin — সেই ধাপের লগের শেষ ৫০ লাইন পাঠান।
3. ☐ `db-spike` Summary (৪টি job) পাঠান — এনক্রিপশন সত্যিই কাজ করছে কি, লাইব্রেরির আকার কত।
4. ☐ build সবুজ হলে APK ফোনে ও Windows zip PC-তে চালান: **Settings → Diagnostics → Copy** করে পেস্ট করুন (P-01..03)।
5. ☐ আসল account-এ (অ্যাপের ভেতরে বসান): Drive → WebDAV/Nextcloud ➜ **Accounts → 🧪 "Run self-test"** → ফলাফল **Copy** করে পাঠান; ডাউনলোড/আপলোড করে দেখুন। Dropbox/OneDrive চাইলে Settings-এ "experimental" চালু করে নিজের client ID দিয়ে sign-in + self-test। Mail → iCloud/IMAP → ইনবক্স, বার্তা খোলা, পাঠানো।
6. ☐ (Release চাইলে) `docs/RELEASE_GUIDE.md` §১: keystore + ৪টি secret। না চাইলে বাদ।
7. ☐ আপনার সিদ্ধান্ত: লাইসেন্স (ADR-021) · Privacy Policy-র ইমেইল (`[CONTACT-EMAIL]`) · লোগো/আইকন · Play-ফি নেবেন কি না।

## A+++. v6 — Welcome / About / Support / Feedback + CI-ফিক্স
1. ☐ ZIP-এর ফাইল দিয়ে overwrite → push → `format` শেষে `git pull` → `ci` চালান (অতিরিক্ত পরীক্ষা-সহ)।
2. ☐ **AUS চালু করতে (একবার):** GitHub → Settings → Secrets and variables → Actions → **Variables** ট্যাব → *New repository variable* → নাম `AUS_BASE_URL`, মান আপনার AUS Worker-এর https ঠিকানা (যে URL-এ Dashboard খোলেন; শেষে `/` না দিলেও চলবে)। এটি secret নয়। না দিলে: link ডিফল্ট/cache থেকে চলবে, Feedback "not set up" বলবে।
3. ☐ **আমাকে পাঠান:** আপনার `docs/central-links.md`-এর লেখা (বা `GET /v1/links`-এর একটি নমুনা response) — যাতে parser হুবহু মিলিয়ে নিতে পারি। ⚠ AUS-এর আসল গঠন আমি জানি না; এখন অনুমান-ভিত্তিক।
4. ☐ অ্যাপ-id: Feedback-এর `source` ডিফল্টে `com.aethryon.drive_app` / `com.aethryon.mail_app`। আপনার AUS-এ অন্য id নিবন্ধিত থাকলে বলুন।
5. ☐ build-এর পর ফোনে: নতুন install → **Welcome** একবার দেখাচ্ছে? Get Started → হোম; অ্যাপ বন্ধ করে আবার খুললে আর আসে না? Settings → **About** (logo, DEVELOPED BY Aethryon Labs, DEVELOPER Md. Shakil Hossain, সঠিক version) → Get In Touch / Support ব্রাউজারে খোলে? toolbar-এর ডানে ছোট **Support** বোতাম একই পাতা খোলে?
6. ☐ Settings → **Send feedback** → একটি টেস্ট বার্তা পাঠিয়ে AUS Dashboard-এর Feedback পাতায় এল কি না দেখুন।
7. ☐ AUS Dashboard থেকে link বদলে ≥৬ ঘণ্টা পরে (বা অ্যাপ পুনরায় চালু) নতুন link খোলে কি না দেখুন — **এটাই "remote update" এর আসল পরীক্ষা, আমি করতে পারিনি।**
8. ☐ CI-র লাল হলে: এবার `loading test/store_test.dart` এর **পূর্ণ ত্রুটি-বার্তা** (expanded রিপোর্টারে আসবে) পাঠান।

## B. দ্রুত ফোন/PC পরিমাপ (প্রায় ৩০ মিনিট, বিনামূল্যে)
9. ☐ `docs/MEASUREMENT_PROTOCOL.md` অনুযায়ী আপনার সবচেয়ে দুর্বল Android ফোন ও ৪ GB Windows PC-তে: ঠান্ডা চালু হওয়ার সময়, idle RAM — লিখে পাঠান। এটাই Flutter-সিদ্ধান্তের (ADR-003) চূড়ান্ত পরীক্ষা।

## C. সিদ্ধান্ত যা আপনার (আমি অনুমান করিনি)
10. ☐ **সফটওয়্যার-লাইসেন্স** (ADR-021): open-source (MIT/Apache/GPL) নাকি source-available/proprietary। `paid advanced feature` মডেলের সঙ্গে সম্পর্কিত। বলুন, আমি `LICENSE` যোগ করব।
11. ☐ **Free বনাম paid** feature তালিকা (ADR-014) — এখনই দরকার নেই; Phase ৭+।
12. ☐ **Apple** (ADR-008, ADR-029): এখন সম্পূর্ণ বাদ। পরে (Phase ১০) iOS/macOS-এ বিতরণ চাইলে Apple Developer Program (~$99/বছর, সূত্র: সেকেন্ডারি) লাগবে। এখন কিনবেন না। কবে চান জানালে আমি পরিকল্পনা করব।
13. ☐ **অ্যাপের আইকন/ব্র্যান্ড**: লোগো আছে? না থাকলে বলুন, সরল placeholder বানাব।
14. ☐ **ডেভেলপার ইমেইল/গোপনীয়তা যোগাযোগ** (Privacy Policy-র জন্য) — কোন ইমেইল ব্যবহার করবেন?

## D. যখন Google (Gmail/Drive) চান (ঐচ্ছিক, বিনামূল্যে)
15. ☐ `docs/GOOGLE_BYO_CLIENT_GUIDE.md` অনুসরণ করে নিজের Google Cloud OAuth client বানান, publishing status **"In production"** করুন। Client ID পাঠাবেন না প্রকাশ্যে (secret হলে আরও না); অ্যাপে বসানোর পদ্ধতি Phase ৬-এ।

## E. পরীক্ষার জন্য (ঐচ্ছিক, বিনামূল্যে)
16. ☐ একটি **iCloud app-specific password** (appleid.apple.com → Sign-In and Security → App-Specific Passwords) বা একটি টেস্ট IMAP অ্যাকাউন্ট — Phase ৬ এ আসল IMAP পরীক্ষার জন্য। **এখন পাঠাবেন না**; অ্যাপে নিজেই বসাবেন।
17. ☐ ঐচ্ছিক: নিজস্ব Nextcloud/WebDAV সার্ভার থাকলে URL ও একটি টেস্ট ফোল্ডার।

## F. যা আপনাকে করতে হবে না
- Android Studio ইনস্টল, Flutter লোকালে ইনস্টল, লোকাল build — প্রয়োজন নেই (CI করে)।
- কোনো paid সাবস্ক্রিপশন, ক্রেডিট কার্ড — এই ধাপে প্রয়োজন নেই।
