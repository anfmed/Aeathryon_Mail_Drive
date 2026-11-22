# ARCHITECTURE_DECISIONS

পর্যালোচনার তারিখ: ২০২৬-১১-১০

**Status অর্থ:** `ACCEPTED` = আপনার নির্দেশনায় স্পষ্ট অনুমোদিত। `PROPOSED` = আমার প্রস্তাব, আপনার অনুমোদন বাকি। `OPEN` = আপনার সিদ্ধান্ত ছাড়া এগোনো যায় না। **কোনো PROPOSED/OPEN সিদ্ধান্ত অনুমোদিত হিসেবে গণ্য নয়।**

| ADR | সিদ্ধান্ত | Status | ভিত্তি | নির্ভরতা/মন্তব্য |
|---|---|---|---|---|
| 001 | Drive ও Mail দুটি স্বতন্ত্র অ্যাপ; reusable shared foundation অনুমোদিত | ACCEPTED | ব্যবহারকারীর নির্দেশ | `SHARED_FOUNDATION.md` |
| 002 | Target: Android, iOS, Windows, Linux, macOS; Web/PWA নয় | ACCEPTED | নির্দেশ | — |
| 003 | UI/অ্যাপ ফাউন্ডেশন: Flutter/Dart | **PROPOSED** | S23; কিন্তু RAM/স্টার্টআপ অপরিমিত | Phase 1 spike; ব্যর্থ হলে বিকল্প (TECH_STACK §১) |
| 004 | Provider-code UI-তে নয়; adapter/interface + capability registry | ACCEPTED (নীতি) / PROPOSED (বিস্তারিত নকশা) | নির্দেশ §৭ | Drive/Mail ARCHITECTURE |
| 005 | Local-first; বাধ্যতামূলক Aethryon cloud নয়; AI ঐচ্ছিক | ACCEPTED | নির্দেশ | ADR-007 এর সঙ্গে টান |
| 006 | Drive ও Mail-এর আলাদা DB/cache/key; encryption at rest | ACCEPTED (আলাদা রাখা) / PROPOSED (SQLCipher-ধরন সমাধান) | নির্দেশ §৭,৯; S24 | `sqlcipher_flutter_libs` EOL → পথ নির্বাচন Phase 1 |
| 007 | মোবাইল mail push-এর ঐচ্ছিক privacy-preserving relay | **OPEN** | S05 (Gmail push-এ backend), S25 | বিকল্প: (ক) relay নয়, PARTIAL; (খ) ঐচ্ছিক relay (Aethryon/self-host) |
| 008 | Apple Developer Program সদস্যপদ গ্রহণ (iOS/macOS বিতরণ) | **OPEN** | S22 | অনিবার্য শর্ত, কিন্তু খরচ আপনার সিদ্ধান্ত |
| 009 | Google restricted-scope পথ: (ক) verification+সম্ভাব্য CASA, (খ) ব্যবহারকারী-নিজস্ব OAuth client/সীমিত মোড | **OPEN** | S01–S04, S06 | local-only ছাড় UNVERIFIED |
| 010 | Repository public বনাম private | **OPEN** | S21 | CI খরচ ও ব্যবসায়িক মডেল |
| 011 | Monorepo | PROPOSED | ৪ GB dev মেশিনের বাস্তবতা | — |
| 012 | Mail: generic IMAP/SMTP-first; ঐচ্ছিক provider REST transport পরে | PROPOSED | binary আকার, রক্ষণাবেক্ষণ | S04, S09, S18 |
| 013 | কোনো multi-account storage pooling/sharding নয় | PROPOSED (বাধ্যবাধকতা-ভিত্তিক) | S03 | আপনার পূর্ণ-feature তালিকায় ছিল না; নতুন সীমা হিসেবে জানানো হচ্ছে |
| 014 | Free বনাম paid feature বিভাজন | **OPEN** | নির্দেশ: ভবিষ্যতে অনুমোদন | Core কখনো paywall-এ নয় (ACCEPTED নীতি) |
| 015 | সর্বনিম্ন OS: Android 7.0 (API 24) প্রভৃতি | PROPOSED | S23 (সংস্করণ-বিভ্রান্তি) | Phase 1-এ pin |
| 016 | MEGA ঐচ্ছিক build flavor; ToS যাচাই-নির্ভর | PROPOSED, **blocked** | S07, S08 | বর্তমান ToS ও key-নীতি জানা আবশ্যক |
| 017 | Proton: desktop-only via official Bridge; Bridge bundle নয়; mobile `UNSUPPORTED` | PROPOSED (যাচাইকৃত তথ্য-নির্ভর) | S17 | Bridge লাইসেন্স UNVERIFIED |
| 018 | HTML-mail রেন্ডারিং: sanitizer+হালকা renderer, জটিল ক্ষেত্রে lazy WebView | **OPEN** | RAM-সংবেদনশীলতা | Phase 2 spike |
| 019 | Sync সংস্করণ-প্রবাহ: প্রথমে browse/transfer/offline; two-way folder-sync পরে | PROPOSED | জটিলতা-ঝুঁকি | Roadmap |
| 020 | OAuth: system browser + PKCE; embedded WebView নয় | PROPOSED | নিরাপত্তা-নীতি (S04 প্রেক্ষিত) | embedded-WebView-সীমা যাচাই UNVERIFIED |

## অনুমোদনের অনুরোধ
Phase 1 শুরুর আগে অন্তত **ADR-003, 007, 008, 009, 010** এ আপনার সিদ্ধান্ত চাই। বাকি PROPOSED সিদ্ধান্ত "সম্মত/পরিবর্তন" হিসেবে একসাথে নিশ্চিত করলেই চলবে।
