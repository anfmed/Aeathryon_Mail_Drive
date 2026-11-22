# ROADMAP_REMAINING — আর কয়টি phase বাকি

**সম্পন্ন (লেখা):** Phase ০–৫। **কিন্তু** Phase ১–৫-এর কোড এখনো CI-তে সবুজ প্রমাণিত নয়।
**বাকি: ৪টি আবশ্যিক phase (৬–৯) + ২টি পরের/ঐচ্ছিক (১০–১১)।** এটি আমার অনুমান-ভিত্তিক পরিকল্পনা; CI-র ফিডব্যাক-চক্র কত লাগে তার ওপর প্রতিটির দৈর্ঘ্য নির্ভর করবে।

| Phase | নাম | মূল কাজ | আপনার ইনপুট |
|---|---|---|---|
| **৬** | সবুজ CI + আসল ডেটা | CI-র সব compile/analyze/test ত্রুটি সারানো; `material.dart` → `material_ui` migration (যাচাইসহ); `mail_imap` `UNVERIFIED-API` নিষ্পত্তি; অ্যাপে আসল সংযোগ: Drive-এ WebDAV/Nextcloud account-যোগ, Mail-এ IMAP (iCloud/generic, app-password); secure-store wiring; **এনক্রিপ্টেড স্থানীয় DB-র সমাধান** (SQLCipher spike); Android+Windows-এর signing-প্রস্তুতি | CI লগ; ডিভাইস-পরিমাপ (P-01..03); টেস্ট WebDAV/IMAP অ্যাকাউন্ট |
| **৭** | আরও provider ও OAuth | Drive: OneDrive, Dropbox, Box, pCloud, Google (নিজস্ব client); Mail: Outlook OAuth, Gmail (নিজস্ব client), Yahoo, Zoho, Proton Bridge (desktop); মোবাইল OAuth redirect; resumable transfer ও Transfers স্ক্রিন; offline ফাইল/ক্যাশ; search সংযোগ | প্রতি provider-এ ১টি টেস্ট অ্যাকাউন্ট (আপনি নিজে অ্যাপে বসাবেন) |
| **৮** | Sync, background, performance | CONDSTORE/QRESYNC flag-sync; Drive change-feed sync; Android background (periodic) ও Windows ট্রে; conflict নীতি; ডিভাইসে P-01…P-14 মেপে টিউন; accessibility ও নিরাপত্তা পর্যালোচনা | ডিভাইসে পরিমাপ, accessibility-পরীক্ষায় সাহায্য |
| **৯** | Release: Android + Windows (+ Linux) | Signing (Android keystore, Windows ঐচ্ছিক), Privacy Policy, স্টোর/সরাসরি বিতরণ, Linux build ও প্যাকেজিং (AppImage/deb) | লাইসেন্স-সিদ্ধান্ত, ইমেইল, স্টোর-অ্যাকাউন্ট (খরচ আপনার সিদ্ধান্ত) |
| ১০ | Apple (iOS + macOS) — *আপনি চাইলে* | iOS/macOS build, signing/notarization, TestFlight/App Store | Apple Developer Program (paid) সিদ্ধান্ত |
| ১১ | ঐচ্ছিক উন্নত feature | ঐচ্ছিক AI, ঐচ্ছিক encrypted hybrid sync, paid advanced feature, MEGA | feature-বিভাজন ও মূল্য-সিদ্ধান্ত |

**ক্রম-নীতি (আপনার নির্দেশ অনুযায়ী):** Android → Windows → Linux; Apple সবশেষ। Phase ৬-এর আগে কিছুই "সম্পন্ন" ঘোষণা হবে না — CI সবুজ হওয়াই প্রথম শর্ত।
