# Aethryon Labs — Welcome, About & Support: চূড়ান্ত প্রতিবেদন (v6)

**সত্যিকারের অবস্থা:** সবকিছু লেখা হয়েছে; **কোনো Dart/Flutter টেস্ট আমি চালাতে পারিনি** (এই পরিবেশে Dart নেই) — সব টেস্ট প্রথমবার চলবে আপনার CI-তে। AUS-এর সঙ্গে **কোনো আসল সংযোগ পরীক্ষা হয়নি**।

## ১. যে ফাইল তৈরি/পরিবর্তিত
**নতুন package:** `packages/aethryon_brand_core/` (credits, links, feedback, app_info + ২টি টেস্ট-ফাইল), `packages/aethryon_brand/` (services, widgets, logo asset, widget-টেস্ট)।
**পরিবর্তিত:** দুই অ্যাপের `main.dart`, `services.dart`, `pubspec.yaml`, `test/helpers.dart`, `test/widget_test.dart`; `packages/aethryon_host_flutter/` (`FlutterAppInfo` — আসল version, `package_info_plus`); `tools/ci_core.sh`, `tools/ci_flutter.sh`; `.github/workflows/ci.yml` (`--dart-define`); `docs/`।
**আগে আবিষ্কৃত ও ঠিক করা CI-ত্রুটি:** `self_test.dart` (nullable `folderId` await-এর পরে), `memory_transport.dart` (অনর্থক `!`), `token_source.dart` (`whenComplete` নিজের future-ই ফেরত দিয়ে আটকে যেত), `drive_app/accounts.dart` (`DriveStore` import নেই)।

## ২. Welcome dialog
প্রথম চালুতে একবার; হুবহু আপনার লেখা: "Welcome!", "Thank You for Choosing Our App", অনুচ্ছেদ, তার নিচে logo, DEVELOPED BY / Aethryon Labs, DEVELOPER / Md. Shakil Hossain, বর্তমান version; একটিই বোতাম **Get Started** (বন্ধ হয়ে স্বাভাবিক হোম)। কোনো feedback-অনুরোধ/বোতাম নেই। অবস্থা বিদ্যমান preference-JSON-এ (`welcomeDone`) স্থায়ী; অন্য preference মুছে না।
## ৩. About
বিদ্যমান "Settings" ট্যাব থেকে (নতুন নেভিগেশন-আইকন নয়): logo (৯৬dp), credits (কোম্পানি ও developer আলাদা), **Version — `package_info_plus` থেকে গতিশীল** (hard-code নয়), বোতাম **Get In Touch** ও **Support**। Welcome-এর চেয়ে ছোট ও সংযত নকশা।
## ৪. আলাদা Support বোতাম
Files ও Inbox toolbar-এর **ডান কোণে** (আগে খালি; Mail-এ Refresh-এর বাঁয়ে, শিরোনামের সঙ্গে overlap নেই — টেস্টে `getRect` দিয়ে পরীক্ষা)। ছোট, আইকন+"Support", থিমের accent (tertiary) রঙ, ৪৮dp tap-target। About-এর Support-এর **একই** URL-উৎস।
## ৫. Logo
`packages/aethryon_brand/assets/branding/aethryon_labs_logo.png` (আপনার আপলোড করা ফাইল, ১:১ অনুপাত, ৬৪০px)। Welcome-এ ১২৮dp, About-এ ৯৬dp, সাদা গোলাকার টাইলে। কোনো বিকল্প logo বানানো হয়নি; ফাইল লোড ব্যর্থ হলে শুধু "Aethryon Labs" লেখা দেখায় (placeholder-ছবি নয়)।
## ৬. URL-এর কেন্দ্রীয় ব্যবস্থাপনা
`LinkConfigService` (`aethryon_brand_core/lib/src/links.dart`) — `getInTouchUrl`/`supportUrl`-এর একমাত্র উৎস; ডিফল্ট-literal শুধু সেখানেই। অগ্রাধিকার: বৈধ remote → বৈধ cache → ডিফল্ট। শুধু `https`; অবৈধ মান কখনো বৈধটি বদলায় না; খোলার সময় আবার যাচাই।
## ৭. AUS-সংযোগের অবস্থা — **"integration-point প্রস্তুত; AUS client/চুক্তি অনুপস্থিত"**
- এই প্রকল্পে কোনো বিদ্যমান AUS client ছিল না; তাই `GET {AUS_BASE_URL}/v1/links` ডাকা, ≥৬ঘ throttle, cache, অফলাইন-ফলব্যাক সহ নতুন সেবা বানানো হয়েছে।
- **AUS_BASE_URL কনফিগার করা নেই** (আপনাকে GitHub Variable বসাতে হবে)।
- **AUS-এর `/v1/links` response-আকার আমার অজানা** → সহনশীল parser (অনুমান)। `central-links.md` পেলে নিশ্চিত করব।
- Feedback আপনার দেওয়া চুক্তি অনুযায়ী (`POST /v1/feedback`)।
- AUS ড্যাশবোর্ড/ব্যাকএন্ডে কিছু পরিবর্তন করা হয়নি; AUS শুধু URL নিয়ন্ত্রণ করে, নকশা/স্থান/আচরণ নয়।
## ৮. টেস্ট
**লেখা:** `aethryon_brand_core` — ~২০টি (default fallback, https-তালিকা, remote বদল, per-field অবৈধ প্রত্যাখ্যান, cache+অফলাইন+restart, corrupted cache, throttle, AUS-খালি, openLink, credits; feedback: হুবহু চুক্তি, status-ম্যাপিং, validation-আগে-নেটওয়ার্ক-নয়, not-configured); `aethryon_brand` widget — ~৮টি; প্রতিটি অ্যাপে +৫টি (welcome একবার ও restart-এর পর আর নয়, flag-সংরক্ষণ, About, Support = About-এর URL ও overlap-নয়, Feedback-পথ)।
**চালানো হয়েছে:** শুধু Python-এ সমান-যুক্তির পরীক্ষা (URL-তালিকা, per-field মার্জ, feedback-সীমা) — সব মিলেছে। **Dart/Flutter টেস্ট: ০টি চালানো।**
## ৯. বাকি সীমা / ম্যানুয়াল ধাপ
`docs/KNOWN_LIMITATIONS.md` §১৪–১৯ ও `docs/USER_ACTION_CHECKLIST.md` "A+++"।
