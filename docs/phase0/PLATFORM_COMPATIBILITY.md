# PLATFORM_COMPATIBILITY

পর্যালোচনার তারিখ: ২০২৬-১১-১০ | Target: Android, iOS, Windows, Linux, macOS — **শুধু এই পাঁচটি**। Web/PWA বাদ।

## ১. Flutter-এর সমর্থিত সংস্করণ (S23 — PRIMARY)
| Platform | Flutter docs-এর সর্বনিম্ন (পৃষ্ঠা-সংস্করণ ৩.৪৪.x) | মন্তব্য |
|---|---|---|
| Android | API 24 (Android 7.0)+ | Android 5–6 বাদ পড়বে → PROPOSED সিদ্ধান্ত |
| iOS | iOS 13+ | |
| Windows | Windows 10/11 | আপনার Windows 10 dev মেশিনের সঙ্গে সঙ্গত |
| macOS | macOS Catalina+ | |
| Linux | Debian ১০–১৩, Ubuntu LTS ২০.০৪–২৪.০৪ | অন্য distro (Fedora, Arch) আনুষ্ঠানিক তালিকায় নেই → UNVERIFIED |

**সংস্করণ-বিভ্রান্তি:** একই ডকুমেন্টেশনে ভিন্ন সংস্করণের পাতায় (৩.৪৭) উচ্চতর ন্যূনতম (iOS 15+, macOS 12+) দেখা গেছে। কোনটি বর্তমান stable তা **UNVERIFIED**; Phase 1-এ pin করার সময় যাচাই করতে হবে।

## ২. Platform × সক্ষমতা
| বিষয় | Android | iOS | Windows | macOS | Linux |
|---|---|---|---|---|---|
| Secure credential storage | Android Keystore (UNVERIFIED ব্যবহারপদ্ধতি) | Keychain | Credential Manager/DPAPI | Keychain | Secret Service (libsecret); headless/অনুপস্থিতিতে fallback → ঝুঁকি R-12 |
| Background execution | WorkManager-ধরন; Doze সীমা (S25 সেকেন্ডারি) | খুব সীমিত; persistent connection নয় (S25 সেকেন্ডারি) | সিস্টেম-ট্রে/service সম্ভব | login item/agent সম্ভব | systemd user service সম্ভব |
| Mail push (server ছাড়া) | `PARTIAL` | `PARTIAL` | `FULL` (অ্যাপ চলমান) | `FULL` (অ্যাপ চলমান) | `FULL` (অ্যাপ চলমান) |
| File access | SAF (broad permission এড়ানো) | Document picker; File Provider extension scope-বহির্ভূত | সরাসরি | সরাসরি + sandbox (distribution-ভেদে) | সরাসরি; Flatpak/Snap হলে portal |
| OAuth redirect | Custom scheme/App Link | Custom scheme/Universal Link | Loopback (127.0.0.1) বা custom scheme | Loopback/custom scheme | Loopback |
| Packaging | AAB/APK | IPA (Apple সদস্যপদ) | MSIX/Inno/ZIP | DMG/PKG (notarization) | AppImage/deb/Flatpak |
| Proton Bridge | `UNSUPPORTED` | `UNSUPPORTED` | `REQUIRES_COMPANION` | `REQUIRES_COMPANION` | `REQUIRES_COMPANION` |
| MEGA native SDK | ARM/x86 বাইন্ডিং — UNVERIFIED | `UNVERIFIED` | `UNVERIFIED` | `UNVERIFIED` | `UNVERIFIED` |

## ৩. কম-resource বিবেচনা
- **৪ GB RAM desktop:** Flutter desktop-এর বাস্তব RAM/স্টার্টআপ আমরা মাপিনি — Phase 1 benchmark বাধ্যতামূলক (R-06)। বাজেট: `PERFORMANCE_REQUIREMENTS.md`।
- **Low-end Android:** ২ GB RAM / Cortex-A53 শ্রেণির রেফারেন্স ডিভাইস-প্রোফাইল (PROPOSED)। Release APK ABI-split (arm64-v8a ডিফল্ট)।
- হালকা fallback: Flutter বাজেট না মিললে বিকল্প স্ট্যাক ADR-003-এ।

## ৪. Platform-নির্দিষ্ট স্টোর/বিতরণ নীতি
Apple App Store ও Google Play-র নীতি (বিশেষত restricted scope ডেটা ও background services) প্রকাশের আগে আলাদা পর্যালোচনা লাগবে — **UNVERIFIED**।

## ৫. Web বাদ — নিশ্চিতকরণ
কোনো Flutter-web target, PWA, বা browser-ভিত্তিক বিল্ড পরিকল্পনায় নেই। OAuth-এ ব্রাউজার ব্যবহার হবে কেবল system browser (বাহ্যিক) হিসেবে।
