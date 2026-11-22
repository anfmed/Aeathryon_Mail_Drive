# BUILD_AND_RELEASE_STRATEGY

পর্যালোচনার তারিখ: ২০২৬-১১-১০ | অবস্থা: PROPOSED

## ১. বাধ্যবাধকতা
Windows 10, ৪ GB RAM, VS Code, Android Studio নয়; local ভারী Flutter build/run নয়। অতএব: **সব build GitHub Actions-এ**; লোকালে শুধু সম্পাদনা, লিন্ট-লাইট কাজ ও git।

## ২. স্থানীয় development সুপারিশ (৪ GB)
VS Code + Dart/Flutter এক্সটেনশন চালালে analysis server RAM খায় — **UNVERIFIED পরিমাপ**; প্রস্তাব: লোকালে কেবল ফাইল সম্পাদনা ও সীমিত analyzer; পূর্ণ analyze/test CI-তে। Emulator/Android Studio নয়। পরীক্ষা: CI-তে তৈরি APK সরাসরি ফোনে install। GitHub Codespaces ইত্যাদির ফ্রি কোটা/মূল্য UNVERIFIED — নির্ভরতা নয়।

## ৩. GitHub Actions খরচ ও runner (S21)
- Public repo-তে standard runner বিনামূল্যে (S21 — PRIMARY)।
- Private repo-তে বিনামূল্যের মিনিট-কোটা আছে (সংখ্যা SECONDARY: cicdpipelinecost.com — চূড়ান্ত নয়) এবং মিনিট-multiplier প্রযোজ্য: Linux ×১, Windows ×২, macOS ×১০ (S21 অনুযায়ী প্রচলিত গুণক; সঠিক বর্তমান মান Phase 1-এ পুনরায় যাচাই)। অর্থাৎ private repo-তে macOS বিল্ড দ্রুত কোটা শেষ করবে।
- ২০২৬-এ Actions মূল্য-পরিবর্তন সংক্রান্ত সংবাদ (itbrief) পাওয়া গেছে — **UNVERIFIED**; Phase 1-এ docs.github.com পুনরায় দেখতে হবে।
- **OPEN সিদ্ধান্ত:** repo public (CI ফ্রি, সোর্স উন্মুক্ত — ব্যবসায়িক প্রভাব) নাকি private (সীমিত CI)।

## ৪. Platform-ভিত্তিক workflow
| Platform | Runner | আউটপুট | Signing/secrets | সীমাবদ্ধতা |
|---|---|---|---|---|
| Android | `ubuntu-latest` | AAB (Play), APK (সরাসরি) | Release keystore + passwords → GitHub encrypted secrets; Play-তে প্রকাশে Google Play Console (একবারের ফি — মান UNVERIFIED) | Android SDK ক্যাশ; ABI-split |
| iOS | **macOS runner (বাধ্যতামূলক; Xcode শুধু macOS-এ)** | `--no-codesign` কম্পাইল-যাচাই (Apple সদস্যপদ ছাড়া সম্ভব — UNVERIFIED); স্বাক্ষরিত IPA/TestFlight | Distribution certificate + provisioning profile + App Store Connect API key → secrets; **Apple Developer Program লাগে** (বিনামূল্যের provisioning ৭ দিনের — S22; ফি $৯৯ SECONDARY) | Hosted macOS runner (GitHub) ছাড়া অন্য বিকল্প = নিজস্ব Mac |
| macOS | macOS runner | `.app`/DMG | Developer ID + notarization (Apple সদস্যপদ) | Notarization ছাড়া Gatekeeper সতর্কতা |
| Windows | `windows-latest` | ZIP/MSIX/ইনস্টলার | কোড-সাইনিং সার্টিফিকেট ঐচ্ছিক (খরচ; SmartScreen সতর্কতা কমায় — UNVERIFIED) | সাইন ছাড়া SmartScreen সতর্কতা |
| Linux | `ubuntu-latest` | AppImage/`.deb`/(Flatpak পরে) | GPG স্বাক্ষর ঐচ্ছিক | Flutter-এর অফিসিয়াল distro তালিকা সীমিত (S23) |

## ৫. iOS/macOS সীমাবদ্ধতা — স্পষ্টীকরণ
(ক) iOS/macOS বিল্ড Apple হার্ডওয়্যার বা hosted macOS runner ছাড়া সম্ভব নয়। আপনার Windows 10 মেশিনে স্থানীয় বিল্ড অসম্ভব। (খ) অনিবার্য শর্ত: অর্থপূর্ণ বিতরণ (TestFlight/App Store/notarized macOS) Apple Developer Program-এর paid সদস্যপদ চায় (S22 PRIMARY — বিনামূল্যে সীমিত; $৯৯ সংখ্যা SECONDARY)। এটি "paid service বাধ্যতামূলক নয়" নীতির **অনিবার্য ব্যতিক্রম** (আপনার নির্দেশনার শর্ত অনুযায়ী) এবং ADR-008-এ OPEN। (গ) কাঁচা কম্পাইল-যাচাই paid ছাড়াই CI-তে করার সম্ভাবনা আছে (UNVERIFIED)।

## ৬. Workflow কাঠামো (প্রস্তাব; এখনো কোনো YAML নয়)
- Path-filter: `apps/drive/**`, `apps/mail/**`, `packages/**`।
- Pipeline: lint/analyze → unit test → build (matrix) → আকার-রিপোর্ট (P-10) → artifact আপলোড (Actions artifact)।
- Release: tag-ট্রিগার্ড; environment protection; secrets কেবল protected branch/environment-এ।
- ক্যাশ: pub, Gradle, CocoaPods (CI মিনিট কমাতে)।
- Dependency নীতি: নতুন-প্রকাশিত সংস্করণে কুলিং-পিরিয়ড; লকফাইল; সংস্করণ pin।

## ৭. Signing key ব্যবস্থাপনা
Android keystore ও Apple সার্টিফিকেট অফলাইন ব্যাকআপ; GitHub secrets-এ শুধু রানটাইম কপি; রোটেশন-পরিকল্পনা; কখনো repo-তে নয় (T7)।

## ৮. বিতরণ-মাধ্যম (পরিকল্পনা)
Play Store/সরাসরি APK; App Store/TestFlight; Microsoft Store বা সরাসরি; Linux: AppImage/deb/Flatpak; macOS: DMG। প্রতিটি স্টোরের নীতি (বিশেষত OAuth restricted-scope ও background service) আলাদা পর্যালোচনা — UNVERIFIED।
