# UI_UX_ARCHITECTURE

পর্যালোচনার তারিখ: ২০২৬-১১-১০ | অবস্থা: PROPOSED (ওয়্যারফ্রেম নয়, তথ্য-কাঠামো)

## ১. Shared design language (`aethryon_design`)
- **Tokens:** রঙ (semantic: surface, onSurface, accent, danger, warning, success), টাইপ-স্কেল, spacing (৪-pt গ্রিড), radius, elevation (সংযত), motion (১২০–২২০ ms, `prefers-reduced-motion` মান্য)।
- **Theme:** Light/Dark (সিস্টেম-অনুসারী + ম্যানুয়াল); high-contrast বিকল্প।
- **Typography:** system font-stack (অতিরিক্ত ফন্ট ফাইল নয় — আকার ও লোড কম); বাংলাসহ জটিল স্ক্রিপ্ট ভালো রেন্ডার হয় কি না পরীক্ষা (Phase 1)।
- **Accessibility:** ন্যূনতম ৪৮dp/৪৪pt স্পর্শ-লক্ষ্য; screen-reader লেবেল; focus order; কীবোর্ড শর্টকাট (desktop); ফন্ট স্কেল ২০০% পর্যন্ত; রঙ-নির্ভর নয় এমন স্থিতি-নির্দেশ।
- **Platform-appropriate:** Android — Material-ঘেঁষা, system back; iOS — swipe-back, native-সদৃশ শীট; Desktop — sidebar, multi-pane, context menu, drag & drop, কীবোর্ড-প্রথম; একই UI জোর করে নয়।
- **Responsive breakpoints (PROPOSED):** compact < ৬০০dp (নিচে bottom-nav), medium ৬০০–১০২৩dp (rail), expanded ≥ ১০২৪dp (sidebar + list + detail)।
- **Capability-driven UI:** `UNSUPPORTED/UNVERIFIED` action অনুপস্থিত বা নিষ্ক্রিয় + কারণ-ব্যাখ্যা।

## ২. অবস্থার সাধারণ নিয়ম
- **Loading:** skeleton (ছোট), spinner শুধু ছোট ক্রিয়ায়; বাতিল-যোগ্য।
- **Error:** মানবপাঠ্য কারণ + পরবর্তী পদক্ষেপ (পুনরায় চেষ্টা/পুনরায় সাইন-ইন); প্রযুক্তিগত কোড বিস্তারিত অংশে।
- **Offline:** পাতার শীর্ষে স্পষ্ট ব্যানার; স্থানীয় ডেটা দেখানো; ক্রিয়া কিউ-বদ্ধ বা নিষ্ক্রিয়।
- **Empty:** ব্যাখ্যা + একটি প্রাথমিক ক্রিয়া।

## ৩. Aethryon Drive — স্ক্রিন
Navigation: compact — নিচের ট্যাব (Home, Files, Transfers, Search, More); expanded — বামে sidebar (Accounts, Recent, Favorites, Offline, Transfers, Storage, Settings)।

| স্ক্রিন | উদ্দেশ্য | প্রধান উপাদান | নেভিগেশন | Empty | Loading | Error | Offline | Responsive |
|---|---|---|---|---|---|---|---|---|
| Unified account dashboard | সব account-এর অবস্থা এক নজরে | account কার্ড (নাম, provider, ব্যবহৃত/মোট, sync অবস্থা), "Account যোগ" | Home ট্যাব → account → File browser | "প্রথম account যোগ করুন" + provider তালিকা | কার্ড skeleton | account-ভিত্তিক ত্রুটি-ব্যাজ; একটির ত্রুটি অন্যটিকে আটকায় না | শেষ-জানা কোটা + "পুরোনো" ট্যাগ | ১ কলাম → ২–৩ কলাম গ্রিড |
| File browser | ফোল্ডার-ব্রাউজ ও ফাইল-ক্রিয়া | breadcrumb, তালিকা/গ্রিড, বাছাই/ফিল্টার, মাল্টি-সিলেক্ট, ক্রিয়া-মেনু (capability-gated) | account → ফোল্ডার → ফাইল-বিবরণ | "ফোল্ডারটি খালি" + আপলোড | পৃষ্ঠা-ভিত্তিক skeleton + incremental | ফোল্ডার লোড ব্যর্থ + পুনরায় চেষ্টা | cache/offline-pinned দেখায়; অন্যরা ধূসর | mobile: একক-পেন; tablet/desktop: sidebar + তালিকা + বিবরণ-পেন |
| Recent files | সাম্প্রতিক ফাইল (স্থানীয় অ্যাক্সেস-লগ + provider যেখানে দেয়) | সময়-গ্রুপ তালিকা | → File detail | "এখনো কিছু খোলা হয়নি" | skeleton | আংশিক ফল + ব্যর্থ account-এর তালিকা | স্থানীয় ইতিহাস | তালিকা → মাল্টি-কলাম |
| Favorites | ব্যবহারকারী-চিহ্নিত ফাইল/ফোল্ডার (স্থানীয়) | তালিকা, reorder | → File/Folder | "তারা-চিহ্নিত আইটেম নেই" | — | মুছে-যাওয়া আইটেমের ব্যাখ্যা | স্থানীয় তালিকা | সাধারণ |
| Search | account জুড়ে অনুসন্ধান | অনুসন্ধান বার, ফিল্টার (account/ধরন/তারিখ), স্থানীয় ও দূরবর্তী ফল আলাদা লেবেল | → File detail | "কিছু পাওয়া যায়নি" + পরামর্শ | স্থানীয় ফল তাৎক্ষণিক; দূরবর্তী ধীরে | provider-ভিত্তিক "অনুসন্ধান সমর্থিত নয়/ব্যর্থ" নোট | শুধু স্থানীয় index | desktop: কীবোর্ড ফোকাস `Ctrl/⌘+K` |
| Transfers | আপলোড/ডাউনলোড কিউ | সারি (অগ্রগতি, গতি, ETA), বিরতি/বাতিল/পুনঃচেষ্টা, নিয়ম (Wi-Fi-only) | → File | "কোনো স্থানান্তর নেই" | — | সারি-ভিত্তিক ত্রুটি + পুনঃচেষ্টা | কিউ-বদ্ধ, নেটওয়ার্ক ফিরলে resume | পূর্ণ-পাতা/পেন |
| Offline files | pin-করা ফাইল ও জায়গা | তালিকা, সঞ্চয়-ব্যবহার, "মুক্ত করুন" | → File | "কিছু অফলাইনে রাখা হয়নি" | ডাউনলোড-অগ্রগতি | ডাউনলোড ব্যর্থ আইটেম | সর্বদা-উপলব্ধ | সাধারণ |
| Storage intelligence | ব্যবহার-বিশ্লেষণ (বড় ফাইল, duplicate, পুরোনো) — **শুধু বিশ্লেষণ/পরামর্শ**, pooling নয় (S03) | চার্ট, তালিকা, নিরাপদ "ট্র্যাশে পাঠান" (নিশ্চিতকরণ) | → File | "বিশ্লেষণের জন্য ডেটা অপর্যাপ্ত" | ধাপে-ধাপে index-অগ্রগতি | আংশিক ফল | শেষ-বিশ্লেষণ | ছোট স্ক্রিনে কার্ড-স্ট্যাক |
| Settings | account/সিঙ্ক/ক্যাশ/নিরাপত্তা/AI/থিম | বিভাগ-তালিকা; sync mode, Wi-Fi-only, metered, cache-সীমা, AI-consent, encrypted export | — | n/a | — | সংরক্ষণ-ব্যর্থ বার্তা | সম্পাদনাযোগ্য (স্থানীয়) | mobile: তালিকা; desktop: দ্বিপেন |

## ৪. Aethryon Mail — স্ক্রিন
Navigation: compact — নিচে (Inbox, Search, Compose, Accounts/More) + drawer (folders); expanded — তিন-পেন (account/folder | তালিকা | পাঠ)।

| স্ক্রিন | উদ্দেশ্য | প্রধান উপাদান | নেভিগেশন | Empty | Loading | Error | Offline | Responsive |
|---|---|---|---|---|---|---|---|---|
| Unified inbox | সব account-এর ইনবক্স একত্রে | তালিকা (প্রেরক, বিষয়, প্রিভিউ, account-রঙ), swipe/কীবোর্ড-ক্রিয়া, ফিল্টার (অপঠিত/ফ্ল্যাগ) | → Thread; account switcher | "ইনবক্স খালি" | header-only skeleton, lazy | account-ভিত্তিক ব্যানার (auth/সার্ভার) | স্থানীয় cache দেখায় | ১-পেন → ২/৩-পেন |
| Account switcher | সব/একটি account নির্বাচন | account তালিকা (অপঠিত সংখ্যা, অবস্থা), "Account যোগ" | ইনবক্স-শীর্ষ/drawer | "প্রথম account যোগ করুন" | — | "সাইন-ইন প্রয়োজন" ব্যাজ | শেষ অবস্থা | sheet ↔ sidebar |
| Mail folders/labels | ফোল্ডার/লেবেল ব্রাউজ | সিস্টেম ফোল্ডার + ব্যবহারকারী লেবেল; provider-ভেদে ম্যাপ-করা | → তালিকা | "ফোল্ডার খালি" | skeleton | ফোল্ডার-সিঙ্ক ব্যর্থ নোট | স্থানীয় সংখ্যা | drawer ↔ pane |
| Thread/Message view | পাঠ | নিরাপদ HTML রেন্ডার (JS নেই, রিমোট ছবি ঐচ্ছিক-বাটন), attachment তালিকা, ক্রিয়া (উত্তর/archive/মুছুন) | → Compose/Attachments | — | body lazy লোড | "বার্তা লোড ব্যর্থ" + পুনঃচেষ্টা | cache-করা না থাকলে "অফলাইনে নেই" | একক-পেন ↔ বিস্তৃত পাঠ-পেন |
| Compose | লেখা/উত্তর/ফরওয়ার্ড | প্রাপক, বিষয়, rich/plain, attachment, draft-অটো-সেভ, from-account নির্বাচন | → Sent/Outbox | নতুন খালি ফর্ম | — | পাঠানো ব্যর্থ → Outbox + কারণ | Outbox-এ রাখে (স্থানীয়) | sheet ↔ উইন্ডো/পেন |
| Search | স্থানীয় FTS + সার্ভার-অনুসন্ধান | বার, ফিল্টার (account/ফোল্ডার/তারিখ/attachment) | → Thread | "কিছু পাওয়া যায়নি" | স্থানীয় তাৎক্ষণিক | সার্ভার-অনুসন্ধান ব্যর্থ নোট | স্থানীয় শুধু | কীবোর্ড-ফোকাস |
| Attachments | সব attachment ব্রাউজ/খোলা/সংরক্ষণ | তালিকা (ধরন, আকার), ঝুঁকি-সতর্কতা, "Drive-এ সংরক্ষণ" (OS share — OPEN) | → Thread | "কোনো attachment নেই" | থাম্বনেইল lazy | ডাউনলোড ব্যর্থ | ডাউনলোড-করাগুলো | গ্রিড স্কেলযোগ্য |
| Drafts | অসমাপ্ত খসড়া | তালিকা, ডিলিট-নিশ্চিতকরণ | → Compose | "খসড়া নেই" | skeleton | সিঙ্ক-ব্যর্থ নোট | স্থানীয় খসড়া | সাধারণ |
| Sent | পাঠানো মেইল + Outbox | তালিকা; Outbox-এর অবস্থা | → Thread | "কিছু পাঠানো হয়নি" | skeleton | পাঠানো-ব্যর্থ + পুনঃচেষ্টা | Outbox কিউ | সাধারণ |
| Archive | আর্কাইভ-করা | তালিকা, ইনবক্সে ফেরত | → Thread | "আর্কাইভ খালি" | skeleton | — | স্থানীয় | সাধারণ |
| Settings | account, sync, notification, নিরাপত্তা, রেন্ডার, AI, থিম | account-প্রতি sync মোড; push-বিকল্প (relay OPEN); remote-content; encrypted export | — | n/a | — | — | স্থানীয় | mobile তালিকা / desktop দ্বিপেন |

## ৫. Mail-নির্দিষ্ট স্বচ্ছতা
- Proton: mobile-এ Add-account-এ "Proton Mail-এর অফিসিয়াল Bridge শুধু ডেস্কটপে চলে; এই ডিভাইসে সংযোগ সম্ভব নয়" (S17)।
- iOS/Android push: "রিয়েল-টাইম সীমিত; কতক্ষণ পরপর যাচাই হয়" ব্যাখ্যা।
- Gmail: কেন অনুমতি চাওয়া হচ্ছে তার সহজ ব্যাখ্যা (restricted scope)।

## ৬. নিশ্চিতকরণ নকশা-প্যাটার্ন
Destructive ক্রিয়া: প্রভাবের সারাংশ + (সম্ভব হলে) undo snackbar; permanent delete: লিখিত নিশ্চিতকরণ; সব সময় "কী মুছবে/কোথায় থাকবে" স্পষ্ট।
