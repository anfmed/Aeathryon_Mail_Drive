# Phase 3 — Mail core: প্রতিবেদন
**অবস্থা:** লেখা সম্পন্ন; build-যাচাই বাকি।
**করা হয়েছে:** IMAP CAPABILITY parser (QRESYNC কেবল CONDSTORE থাকলে বিশ্বাসযোগ্য); sync-কৌশল (qresync > condstore > uidScan); UIDVALIDITY পরিবর্তনে full-resync নিয়ম; local threader (Message-ID/References/In-Reply-To, union-find; **subject দিয়ে merge নয়** — ভুল-মিলন এড়াতে); outbox state-machine (permanent/auth ব্যর্থতা terminal; crash-পরবর্তী `sending` স্বয়ংক্রিয় resend নয় — duplicate মেইল এড়াতে); provider profile — iCloud (app-password, S18), Proton (companion-only, mobile নেই, S17), অযাচাইকৃত host নীরবে autofill হয় না; Mail schema (আলাদা DB)।
**না করা:** IMAP/SMTP transport, OAuth flow, rendering, sanitizer — Phase 4 (কারণ: Dart ছাড়া অপরীক্ষিত নেটওয়ার্ক-কোড লেখা ঝুঁকিপূর্ণ; ADR-018 নিজে-লেখা sanitizer নিষিদ্ধ)।
**Exit gate:** CI সবুজ + `enough_mail` spike (IDLE ব্যাটারি, QRESYNC, ১ লক্ষ মেইল) + Gmail/iCloud live পরীক্ষা।
