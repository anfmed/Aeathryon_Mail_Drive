# ROADMAP_REMAINING (হালনাগাদ — Phase ৬–৭ লেখার পর)

**সম্পন্ন (লেখা):** Phase ০–৭। প্রথম আসল CI-তে Phase ১–৫ সবুজ; Phase ৬–৭-এর নতুন কোড এখনো অচালিত।
**বাকি: ২টি আবশ্যিক phase (৮, ৯) — তবে Phase ৮ বড়; আমার অনুমানে দুই ধাপে (৮ক, ৮খ) ভাঙতে হতে পারে, অর্থাৎ বাস্তবে ২–৩টি। তারপর ২টি পরের/ঐচ্ছিক (১০, ১১)।**

| Phase | নাম | মূল কাজ |
|---|---|---|
| **৮ (ক)** | স্থায়িত্ব ও সংযোগ | এনক্রিপ্টেড স্থানীয় DB (spike-ফল অনুযায়ী) ও schema চালু; মেইল body ডাউনলোড; Drive upload/download UI (TransferRunner জোড়া); OAuth "Sign in" UI (`url_launcher`) → Outlook/Gmail (নিজস্ব client); `material_ui` migration (যাচাইসহ) |
| **৮ (খ)** | আরও provider, sync, background | Dropbox/OneDrive/Box/pCloud/Google live-যাচাই ও account-UI; CONDSTORE flag-sync; Drive change-feed sync; Android background (periodic) ও Windows ট্রে; offline ফাইল/ক্যাশ; search সংযোগ; মোবাইল OAuth redirect; ডিভাইসে P-01…P-14 মেপে টিউন; accessibility ও নিরাপত্তা পর্যালোচনা |
| **৯** | Release: Android + Windows (+ Linux) | Signing, Privacy Policy, স্টোর/সরাসরি বিতরণ, Linux build ও প্যাকেজিং |
| ১০ | Apple (iOS + macOS) — *আপনি চাইলে* | build, signing/notarization, TestFlight/App Store (Developer Program — paid) |
| ১১ | ঐচ্ছিক উন্নত feature | **ঐচ্ছিক AI, ঐচ্ছিক encrypted hybrid sync, paid advanced feature**, MEGA — *এটি নিয়েই আপনি আলোচনা করতে চেয়েছেন* |
