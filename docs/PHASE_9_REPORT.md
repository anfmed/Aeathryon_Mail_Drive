# Phase 9 — Release-প্রস্তুতি (Android + Windows + ঐচ্ছিক Linux): প্রতিবেদন
**অবস্থা:** CI-কনফিগ ও নথি লেখা; release কিছুই প্রকাশিত নয়।
- **CI:** package-id `com.aethryon.*`; অ্যাপ-নাম (Android label, Windows window-title) — best-effort patch; `allowBackup=false`; `--build-number=run_number`; **Android signing** (`apksigner`, আপনার keystore secrets থাকলে; না থাকলে preview সতর্কবার্তা); draft release (SHA256 সহ)।
- **নথি:** `RELEASE_GUIDE`, `PRIVACY_POLICY_DRAFT`, `STORE_LISTING_DRAFT` (সৎ-সীমাসহ), `SECURITY_REVIEW_PHASE9`, accessibility-অবস্থা।
- **স্বয়ংক্রিয় a11y:** দুই অ্যাপে tap-target ও label গাইডলাইন-টেস্ট।
**আপনার ছাড়া হবে না:** keystore তৈরি ও secrets; Privacy Policy-র ইমেইল ও URL; আইকন; Play ফি-সিদ্ধান্ত; লাইসেন্স; আইনি পর্যালোচনা; ফোনে আসল পরীক্ষা (TalkBack সহ)।
**করা হয়নি:** Windows signing, MSIX, AAB, AppImage/deb, স্টোর-জমা, Apple।
