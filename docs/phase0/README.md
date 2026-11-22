# Aethryon Phase 0 — Architecture ও Feasibility প্যাকেজ

- **প্রকল্প:** Aethryon Drive + Aethryon Mail (Aethryon Labs)
- **Phase:** ০ (শুধু গবেষণা, architecture ও documentation)
- **গবেষণা/পর্যালোচনার তারিখ:** ২০২৬-১১-১০
- **অবস্থা:** `COMPLETE_WITH_PARTIALS` — কোনো critical FAIL নেই, তবে কয়েকটি critical বিষয় PARTIAL/UNVERIFIED (বিস্তারিত `PHASE_0_VERIFICATION.md`)। Phase 1 শুরুর আগে ব্যবহারকারীর অনুমোদন প্রয়োজন।
- **ইনপুট:** Greenfield প্রকল্প। কোনো আগের repository, ZIP বা সিদ্ধান্ত ছিল না (ব্যবহারকারী নিশ্চিত করেছেন)।

## এই Phase-এ যা করা হয়নি (ইচ্ছাকৃত)
কোনো production code, database schema/migration, provider integration, OAuth credential সংগ্রহ বা paid account তৈরি করা হয়নি।

## ফাইল তালিকা
| # | ফাইল | বিষয় |
|---|------|-------|
| 1 | PRODUCT_REQUIREMENTS.md | অনুমোদিত সিদ্ধান্ত, requirement, অনুমোদনহীন বিষয় |
| 2 | DRIVE_ARCHITECTURE.md | Aethryon Drive architecture |
| 3 | MAIL_ARCHITECTURE.md | Aethryon Mail architecture |
| 4 | SHARED_FOUNDATION.md | পুনর্ব্যবহারযোগ্য shared foundation ও তার সীমা |
| 5 | PROVIDER_COMPATIBILITY_MATRIX.md | Provider × feature status |
| 6 | PLATFORM_COMPATIBILITY.md | ৫টি platform-এর সামঞ্জস্য |
| 7 | TECH_STACK_EVALUATION.md | Technology ও dependency মূল্যায়ন |
| 8 | SECURITY_THREAT_MODEL.md | Threat model |
| 9 | PERFORMANCE_REQUIREMENTS.md | পরিমাপযোগ্য performance বাজেট (PROPOSED) |
| 10 | UI_UX_ARCHITECTURE.md | দুই অ্যাপের UI information architecture |
| 11 | BUILD_AND_RELEASE_STRATEGY.md | GitHub Actions ভিত্তিক cloud build |
| 12 | API_AND_LICENSING_RESEARCH.md | Source register (URL + তারিখ) ও গবেষণার ফল |
| 13 | ARCHITECTURE_DECISIONS.md | ADR তালিকা (ACCEPTED/PROPOSED/OPEN আলাদা) |
| 14 | RISK_REGISTER.md | ঝুঁকির তালিকা |
| 15 | PHASE_0_VERIFICATION.md | যাচাই প্রতিবেদন |
| 16 | README.md | এই ফাইল |

## পাঠের ক্রম (প্রস্তাবিত)
`PHASE_0_VERIFICATION.md` → `ARCHITECTURE_DECISIONS.md` (OPEN অংশ) → `RISK_REGISTER.md` → বাকিগুলো।

## Status শব্দভাণ্ডার
`FULL`, `PARTIAL`, `UNSUPPORTED`, `REQUIRES_PERMISSION`, `REQUIRES_COMPANION`, `TEMPORARILY_UNAVAILABLE`, `UNVERIFIED`।
Decision status: `ACCEPTED` (আপনার অনুমোদিত), `PROPOSED` (আমার প্রস্তাব, অনুমোদন বাকি), `OPEN` (সিদ্ধান্ত প্রয়োজন)।
Evidence level: `PRIMARY` (official), `SECONDARY` (তৃতীয় পক্ষ), `NONE` (এই session-এ যাচাই হয়নি)।
