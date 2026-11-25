# ROADMAP_REMAINING (হালনাগাদ — Phase ৮–৯ লেখার পর)

**সম্পন্ন (লেখা):** Phase ০–৯। Phase ১–৫ আসল CI-তে সবুজ ছিল; **Phase ৬–৯-এর নতুন কোড এখনো CI-তে চালানো হয়নি**।
**বাকি কাজ — কিছুই "নতুন বড় phase" নয়, তিনটি ধারা:**

| ধারা | কাজ | কে |
|---|---|---|
| **A. সবুজ করা (সবচেয়ে জরুরি)** | `ci` চালানো → ব্যর্থতা-তালিকা (এখন সবগুলো একবারে দেখায়) → আমি ঠিক করব; `db-spike` ফলে `sqlite3mc`/`sqlcipher` নিশ্চিত | আপনি লগ পাঠাবেন, আমি ফিক্স |
| **B. আসল পরিবেশে যাচাই** | আপনার ফোন/PC-তে Diagnostics-মাপ (P-01..03); আপনার WebDAV/IMAP/Dropbox/OneDrive/Gmail account-এ self-test ও ব্যবহার; TalkBack/Narrator-পরীক্ষা | **শুধু আপনি** |
| **C. বাকি feature (B-র ফল দেখে)** | Google Drive/Box/pCloud adapter (docs পড়ে); mail: ফোল্ডার/পড়া-মোছা-archive/attachment/search-UI/স্থায়ী outbox; Wi-Fi-only/metered; background sync (plugin-মূল্যায়নসহ); `material_ui` migration; Windows signing/MSIX/AAB/AppImage | আমি (আপনার ফল পেয়ে) |

**তারপর (আপনি চাইলে):** Phase ১০ — Apple (iOS+macOS)। Phase ১১ — ঐচ্ছিক AI, ঐচ্ছিক encrypted hybrid sync, paid feature (আপনি আলোচনা করতে চেয়েছেন)।
**সংখ্যায়:** আবশ্যিক বাকি = **ধারা A ও B শেষ করা (১ চক্র) + ধারা C (আনুমানিক ১–২ চক্র)**; আগের "Phase ৮ ও ৯" এখন লেখা হয়ে গেছে।
