# PERFORMANCE_REQUIREMENTS

পর্যালোচনার তারিখ: ২০২৬-১১-১০ | অবস্থা: **PROPOSED** — নিচের সংখ্যাগুলো আমার প্রস্তাবিত লক্ষ্য; এগুলো কোনো পরিমাপ-করা ফলাফল নয় এবং আপনার অনুমোদন বাকি। Phase 1 spike-এ রেফারেন্স ডিভাইসে মেপে সংশোধিত হবে। কোনো সংখ্যা কারো সুপারিশ-উদ্ধৃতি নয়।

## ১. রেফারেন্স ডিভাইস (PROPOSED)
| কোড | বিবরণ |
|---|---|
| REF-A | low-end Android: ২ GB RAM, ৮-কোর কম-ক্ষমতার ARM (Cortex-A53 শ্রেণি), eMMC, Android 7–10 |
| REF-B | mid Android: ৪ GB RAM, Android 13+ |
| REF-W | Windows 10, ৪ GB RAM, HDD বা ধীর SSD (আপনার মেশিনের শ্রেণি) |
| REF-L | Linux (Ubuntu LTS), ৪ GB RAM |
| REF-M | Mac (Apple Silicon বা পুরোনো Intel) ৮ GB; iPhone: iOS 15+ পুরোনো মডেল |

## ২. বাজেট (লক্ষ্য মান; পরিমাপ-পদ্ধতি সহ)
| ID | মেট্রিক | লক্ষ্য | পদ্ধতি | ডিভাইস |
|---|---|---|---|---|
| P-01 | Cold start → interactive (cache-সহ) | ≤ ২.০ s (REF-A ≤ ৩.০ s) | startup trace, ১০ বার মধ্যমা | সব |
| P-02 | Idle RSS (অ্যাপ খোলা, কিছু করছে না) — desktop | ≤ ১৫০ MB Drive, ≤ ২০০ MB Mail | OS মনিটর, ৫ মিনিট নমুনা | REF-W/L |
| P-03 | Idle RAM — Android | ≤ ১২০ MB | `dumpsys meminfo` | REF-A |
| P-04 | ব্যাকগ্রাউন্ডে (অ্যাপ বন্ধ/ট্রে) ব্যাটারি | ≤ ১% /ঘণ্টা-এর কম অতিরিক্ত drain (৪ ঘণ্টা মাপে) | battery stats | REF-A/B, iPhone |
| P-05 | স্ক্রল ফ্রেম | ৯৫% ফ্রেম ≤ ১৬.৭ ms (৬০Hz) ১০,০০০-আইটেম তালিকায় | frame timing | সব |
| P-06 | নেভিগেশন (screen→screen) | ≤ ১০০ ms ইনপুট→ফ্রেম | trace | সব |
| P-07 | স্থানীয় search — ১ লক্ষ মেইল/৫ লক্ষ ফাইল-মেটাডাটা | ≤ ২০০ ms (প্রথম ফলাফল) | benchmark corpus | REF-W/A |
| P-08 | বড় inbox খোলা (৫০০,০০০ মেইল সিঙ্ক-করা) | প্রথম পৃষ্ঠা ≤ ৫০০ ms; RAM ≤ P-02 + ৫০ MB | synthetic DB | REF-W |
| P-09 | বড় ফাইল স্থানান্তর (২ GB) | RAM বৃদ্ধি ≤ ৫০ MB (streaming); resume সঠিক | লোড-টেস্ট | REF-W/A |
| P-10 | ডিস্ক footprint (install) — আকার | Android APK (arm64) ≤ ২৫ MB লক্ষ্য; desktop ≤ ৮০ MB | CI আকার-রিপোর্ট | সব |
| P-11 | ব্যাকগ্রাউন্ড প্রসেস সংখ্যা | desktop-এ ≤ ১ (+ঐচ্ছিক ট্রে); Android-এ ডিফল্টে কোনো persistent service নয় | process list | সব |
| P-12 | অপ্রয়োজনীয় নেটওয়ার্ক | ডিফল্টে idle অবস্থায় ০ ঘন-polling (ন্যূনতম ব্যবধান ≥ ১৫ মিনিট background-এ) | proxy লগ | সব |
| P-13 | Duplicate download/processing | ০ (কনটেন্ট-হ্যাশ/etag dedupe পরীক্ষা) | অটোমেটেড টেস্ট | সব |
| P-14 | UI rebuild | তালিকা-আইটেমে শুধু পরিবর্তিত আইটেম rebuild | widget-rebuild কাউন্টার | সব |

> সংখ্যাগুলোর যৌক্তিকতা: লক্ষ্য-নির্ধারণ (heuristic), কোনো বাহ্যিক সূত্রে সমর্থিত নয় — `UNVERIFIED` ভিত্তি; অর্থাৎ Phase 1 পরিমাপই চূড়ান্ত।

## ৩. স্থাপত্য-কৌশল (বাজেট পূরণের উপায়)
Lazy loading ও pagination; incremental indexing (নতুন আগে, চার্জিং/Wi-Fi-তে ভারী কাজ); একক shared isolate-pool সীমিত (CPU-কোর/RAM-অনুযায়ী ১–২ worker); resource-aware scheduler (ব্যাটারি < ২০% বা Battery Saver-এ ভারী কাজ স্থগিত); ছবি/থাম্বনেইল ডিকোড আকার-সীমিত; দীর্ঘ তালিকায় virtualized list; আইকন/ফন্ট সীমিত; ডিবাউন্সড search।

## ৪. Release gate
প্রতিটি ডিভাইস-প্রোফাইলে P-01…P-14 পরিমাপ; কোনো মেট্রিক ১০% এর বেশি regress হলে release আটকে; CI-তে binary-আকার ও startup trace নিয়মিত (সম্ভব হলে hosted runner-এ; ডিভাইস-পরিমাপ আংশিক ম্যানুয়াল — R-06)।

## ৪.১ Phase 1 spike-এর পরিমাপ-তালিকা
(১) "Hello" Flutter অ্যাপের idle RSS ও স্টার্টআপ — Windows/Linux (৪ GB); (২) ১ লক্ষ-সারির SQLCipher FTS query; (৩) IMAP IDLE ১০ account-এর ব্যাটারি; (৪) ২ GB ফাইল streaming।
