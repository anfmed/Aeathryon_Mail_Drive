# USER_ACTION_CHECKLIST — আপনাকে যা যা করতে হবে (ক্রমানুসারে)

## A. এখনই (বাধ্যতামূলক, বিনামূল্যে)
1. ☐ GitHub-এ **public** repository খুলুন (ADR-010)। নাম যা খুশি।
2. ☐ এই ZIP unzip করুন; ভেতরের `aethryon-repo/` ফোল্ডারের **ভেতরের** ফাইলগুলো repo-র root-এ রাখুন (`.github/`, `apps/`, `packages/` …)। `.github` লুকানো ফোল্ডার — Windows Explorer-এ "Hidden items" চালু করুন।
3. ☐ Git দিয়ে একবার push করুন (VS Code → Source Control, বা `git add . && git commit -m "phase 1-5" && git push`)। কোনো key/secret ফাইল যোগ করবেন না (`.gitignore` ঠেকাবে)।
4. ☐ GitHub → **Actions** ট্যাব। প্রথমবার "I understand my workflows, go ahead and enable them" চাপুন।
5. ☐ **`ci-core`** workflow চালান (Run workflow)। চারটি job আসবে: `core`, `webdav-live`, `apps`, `isolated`।
6. ☐ লাল হলে: ব্যর্থ job-এ ক্লিক → লগের **শেষ ৪০ লাইন** + কোন job/step ব্যর্থ — কপি করে আমাকে পাঠান। (প্রথম রানে ব্যর্থ হওয়া প্রত্যাশিত; আমি ঠিক করে নতুন ZIP/প্যাচ দেব।)
7. ☐ `ci-core`-এর `core`, `webdav-live`, `apps` সবুজ হলে **`build-apps`** চালান (১০টি job; Android/Windows/Linux আগে সবুজ হওয়ার কথা)।
8. ☐ Artifacts থেকে Android APK ডাউনলোড করে নিজের ফোনে install করুন (Settings → "Install unknown apps")। অ্যাপ খুলে দেখুন; স্ক্রিনশট/মন্তব্য পাঠান।

## B. দ্রুত ফোন/PC পরিমাপ (প্রায় ৩০ মিনিট, বিনামূল্যে)
9. ☐ `docs/MEASUREMENT_PROTOCOL.md` অনুযায়ী আপনার সবচেয়ে দুর্বল Android ফোন ও ৪ GB Windows PC-তে: ঠান্ডা চালু হওয়ার সময়, idle RAM — লিখে পাঠান। এটাই Flutter-সিদ্ধান্তের (ADR-003) চূড়ান্ত পরীক্ষা।

## C. সিদ্ধান্ত যা আপনার (আমি অনুমান করিনি)
10. ☐ **সফটওয়্যার-লাইসেন্স** (ADR-021): open-source (MIT/Apache/GPL) নাকি source-available/proprietary। `paid advanced feature` মডেলের সঙ্গে সম্পর্কিত। বলুন, আমি `LICENSE` যোগ করব।
11. ☐ **Free বনাম paid** feature তালিকা (ADR-014) — এখনই দরকার নেই; Phase ৭+।
12. ☐ **Apple** (ADR-008): iOS/macOS-এ বাস্তবে বিতরণ চাইলে Apple Developer Program (~$99/বছর, সূত্র: সেকেন্ডারি) লাগবে। এখন কিনবেন না। কবে চান জানালে আমি পরিকল্পনা করব।
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
