# Phase 6 — সবুজ CI + আসল ডেটা: প্রতিবেদন
**অবস্থা:** লেখা সম্পন্ন; নতুন কোড CI-তে অচালিত।
**CI-র আসল ফিডব্যাক থেকে ফিক্স:** WebDAV adapter — body এখন **bytes** হিসেবে, প্রতি retry-তে নতুন stream; body-ছাড়া request-এ স্পষ্ট `Content-Length: 0`; ত্রুটি-response drain (সংযোগ নষ্ট হয় না); upload কখনো স্বয়ংক্রিয় retry নয়। ৮টি MockClient-টেস্ট (retry-এ একই body, 404/401 retry নয়, persistent 503 → RetryExhausted, upload একবারই, Range হেডার, URL-নিয়ম)।
**আসল account:**
- `AccountVault` — account ও password OS secure store-এ; Drive/Mail namespace আলাদা; non-secret settings-এ password/token/secret key নিষিদ্ধ।
- **Drive:** "Add WebDAV/Nextcloud" (নাম, https-URL, user, password; `Test connection`; Save), account-তালিকা/নির্বাচন/অপসারণ (নিশ্চিতকরণসহ), আসল সার্ভার ব্রাউজ, মোছা (trash নেই ⇒ "চিরতরে" নিশ্চিতকরণ), ত্রুটির মানবপাঠ্য ব্যাখ্যা (৪০১ ⇒ "লগইন প্রত্যাখ্যাত")।
- **Mail:** "Add mail account" (provider-তালিকা; iCloud-এর যাচাইকৃত host স্বয়ংক্রিয়; অন্যগুলো "সম্ভাব্য, নিশ্চিত করুন"); IMAP inbox sync (`mail_imap` দিয়ে); Compose আসল SMTP-তে। **Gmail/Outlook/Proton সৎ ব্যাখ্যাসহ আটকানো।**
- **Gate:** `mail_imap` ও secure-store wrapper এখন check-এর অংশ।
- **এনক্রিপ্টেড DB spike:** `sqlite3mc` ও `sqlcipher` (Ubuntu+Windows), এক্সট্রা-চেকে: ফাইল plaintext নয়, ভুল/কোনো key ব্যর্থ, সঠিক key কাজ করে, **FTS5 কাজ করে**, native-লাইব্রেরির আকার।
**না করা:** body ডাউনলোড, স্থানীয় ডিস্ক-সংরক্ষণ, upload/download UI, material_ui migration।
**Exit gate:** `ci` check ও build সবুজ; `webdav-live` সবুজ; spike-ফল থেকে ADR-035 নিষ্পত্তি।
