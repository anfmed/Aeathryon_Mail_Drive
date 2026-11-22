# PROVIDER_COMPATIBILITY_MATRIX

পর্যালোচনার তারিখ: ২০২৬-১১-১০ | সব status **provisional** — Phase 1/2-এ ব্যবহারিক পরীক্ষা ছাড়া কোনোটি `FULL` চূড়ান্ত নয়।

**নিয়ম:** (১) `FULL` কেবল তখনই যখন primary source আছে। (২) শুধু training-স্মৃতি বা সেকেন্ডারি সূত্র থাকলে `UNVERIFIED`। (৩) Provider-সামগ্রিক status ও feature status আলাদা। Source ID → `API_AND_LICENSING_RESEARCH.md`।

## ১. Aethryon Drive

### ১.১ সামগ্রিক
| Provider | সামগ্রিক (provisional) | Evidence | মূল কারণ |
|---|---|---|---|
| Google Drive | `REQUIRES_PERMISSION` | PRIMARY | Restricted scope-এ verification/সম্ভাব্য security assessment (S01–S03) |
| MEGA | `PARTIAL` | PRIMARY (লাইসেন্স), SECONDARY (শর্ত) | SDK BSD-2 (S07); application key ও ToS (S07); বর্তমান অনুমোদন UNVERIFIED (S08) |
| OneDrive | `PARTIAL` | PRIMARY (আংশিক) | Graph upload session যাচাইকৃত (S11); বাকি UNVERIFIED |
| Dropbox | `PARTIAL` | SECONDARY+ | Upload session (S13); production approval/রেট-লিমিট UNVERIFIED |
| Box | `PARTIAL` | PRIMARY | OAuth/rate-limit/chunked যাচাইকৃত (S14); app-approval UNVERIFIED |
| WebDAV | `UNVERIFIED` | NONE | RFC এই session-এ যাচাই হয়নি; server-ভেদে ক্ষমতা ভিন্ন |
| Nextcloud | `PARTIAL` | PRIMARY (অস্তিত্ব) | Chunked upload, Login Flow v2, trashbin, versions, search, OCS share manual-এ আছে (S16); বিবরণ UNVERIFIED |
| pCloud | `PARTIAL` | PRIMARY (আংশিক) | OAuth2, দুই region host (S15); রেট-লিমিট/resumable UNVERIFIED |

### ১.২ Feature-ভিত্তিক
| Feature | Google | MEGA | OneDrive | Dropbox | Box | WebDAV | Nextcloud | pCloud |
|---|---|---|---|---|---|---|---|---|
| OAuth2/PKCE auth | `REQUIRES_PERMISSION` | `UNVERIFIED` (SDK-নিজস্ব login) | `UNVERIFIED` | `UNVERIFIED` | `PARTIAL` (OAuth2 যাচাইকৃত; PKCE UNVERIFIED) | n/a (Basic/app-password) `UNVERIFIED` | `PARTIAL` (Login Flow v2 আছে) | `PARTIAL` (OAuth2 আছে) |
| পূর্ণ drive browse | `REQUIRES_PERMISSION` (restricted scope) | `UNVERIFIED` | `UNVERIFIED` | `UNVERIFIED` | `UNVERIFIED` | `UNVERIFIED` | `UNVERIFIED` | `UNVERIFIED` |
| Resumable/chunked upload | `UNVERIFIED` | `UNVERIFIED` | `FULL` (S11) | `PARTIAL` (S13 সেকেন্ডারি+; Dropbox-এর নিজস্ব পাতা যাচাই বাকি) | `PARTIAL` (chunked আছে, S14) | `UNVERIFIED` | `PARTIAL` (chunked আছে, S16) | `UNVERIFIED` |
| সর্বোচ্চ ফাইল | `UNVERIFIED` | `UNVERIFIED` | ২৫০ GB (S12 সেকেন্ডারি) | ৩৫০ GB (S13) | `UNVERIFIED` | server-নির্ভর | server-নির্ভর | `UNVERIFIED` |
| Sharing/permission | `UNVERIFIED` | `UNVERIFIED` | `UNVERIFIED` | `UNVERIFIED` | `UNVERIFIED` | `UNSUPPORTED` (প্রোটোকল স্তরে — UNVERIFIED) | `PARTIAL` (OCS share, S16) | `PARTIAL` (public link method তালিকায় আছে, S15) |
| Server-side search | `UNVERIFIED` | `UNSUPPORTED`-প্রবণ (E2EE; UNVERIFIED) | `UNVERIFIED` | `UNVERIFIED` | `UNVERIFIED` | `UNVERIFIED` | `PARTIAL` (search API আছে, S16) | `UNVERIFIED` |
| Change feed/cursor | `UNVERIFIED` | `UNVERIFIED` | `UNVERIFIED` (delta) | `PARTIAL` (cursor/long-poll — সেকেন্ডারি) | `UNVERIFIED` | `UNVERIFIED` | `UNVERIFIED` | `UNVERIFIED` |
| Webhook/push (client-only নীতিতে) | `UNVERIFIED`; server লাগবে | `UNVERIFIED` | `UNVERIFIED`; server লাগবে | server লাগবে (সেকেন্ডারি) | `UNVERIFIED` | `UNSUPPORTED` | `UNVERIFIED` | `UNVERIFIED` |
| Trash/recoverability | `UNVERIFIED` | `UNVERIFIED` | `UNVERIFIED` | `UNVERIFIED` | `UNVERIFIED` | `UNVERIFIED` | `PARTIAL` (trashbin, S16) | `UNVERIFIED` |
| Storage pooling | `UNSUPPORTED` (S03 নিষিদ্ধ) | — | — | — | — | — | — | — |
| Android / iOS / Desktop | Flutter-ভিত্তিক REST: সম্ভব (UNVERIFIED) | native SDK bridge প্রয়োজন, তিন স্তরের বাইন্ডিং `UNVERIFIED` | REST: সম্ভব (UNVERIFIED) | REST: সম্ভব (UNVERIFIED) | REST: সম্ভব (UNVERIFIED) | সম্ভব (UNVERIFIED) | সম্ভব (UNVERIFIED) | সম্ভব (UNVERIFIED) |

> সতর্কতা: সারণির অনেক ঘর `UNVERIFIED` — এটি ইচ্ছাকৃত সততা; খালি ঘর ভরতে অনুমান করা হয়নি।

## ২. Aethryon Mail

### ২.১ সামগ্রিক
| Provider | সামগ্রিক | Evidence | মূল কারণ |
|---|---|---|---|
| Gmail | `REQUIRES_PERMISSION` | PRIMARY | Restricted scope `mail.google.com` (S04); CASA (S06 সেকেন্ডারি) |
| Yahoo Mail | `REQUIRES_PERMISSION` | SECONDARY | OAuth-এর জন্য ফর্ম+চুক্তি (S19); app password বিকল্প |
| Outlook/M365 | `PARTIAL` | PRIMARY (OAuth) / SECONDARY (basic-auth সময়সূচি) | IMAP/SMTP OAuth (S09); tenant admin নীতি UNVERIFIED |
| iCloud Mail | `PARTIAL` | PRIMARY | IMAP/SMTP + app-specific password (S18); OAuth/API/push নেই-প্রবণ (UNVERIFIED) |
| Zoho Mail | `PARTIAL` | PRIMARY (REST) | REST+OAuth2 (S20); IMAP UNVERIFIED |
| Proton Mail | `REQUIRES_COMPANION` | PRIMARY | Bridge: শুধু desktop, paid (S17) |
| Generic IMAP/SMTP | `PARTIAL` | NONE (RFC) | প্রোটোকল-স্তরে সম্ভব; capability সার্ভার-ভেদে ভিন্ন; RFC যাচাই বাকি |

### ২.২ Feature-ভিত্তিক
| Feature | Gmail | Yahoo | Outlook/M365 | iCloud | Zoho | Proton | Generic |
|---|---|---|---|---|---|---|---|
| IMAP/SMTP availability | `FULL` (S04) | `PARTIAL` (S19 সেকেন্ডারি) | `FULL` (S09) | `FULL` (S18) | `UNVERIFIED` | `REQUIRES_COMPANION` (Bridge, S17) | `PARTIAL` |
| OAuth2 | `REQUIRES_PERMISSION` | `REQUIRES_PERMISSION` | `FULL`-প্রবণ (S09; admin consent UNVERIFIED) → `PARTIAL` | `UNSUPPORTED` (UNVERIFIED) | `PARTIAL` (REST, S20) | `UNSUPPORTED` (Bridge credential) | `PARTIAL` |
| App password | `UNVERIFIED` | `PARTIAL` (S19) | `UNVERIFIED` | `FULL` (S18; আবশ্যক) | `UNVERIFIED` | n/a | `PARTIAL` |
| Native REST API | `PARTIAL` (S06) | `UNVERIFIED` | `UNVERIFIED` (Graph) | `UNSUPPORTED` (UNVERIFIED) | `PARTIAL` (S20) | `UNSUPPORTED` | `UNSUPPORTED` |
| Folder/label | `UNVERIFIED` | `UNVERIFIED` | `UNVERIFIED` | `UNVERIFIED` | `UNVERIFIED` | `UNVERIFIED` | `PARTIAL` |
| Native thread | `UNVERIFIED` | `UNVERIFIED` | `UNVERIFIED` | `UNVERIFIED` | `UNVERIFIED` | `UNVERIFIED` | local threading |
| Push — desktop (অ্যাপ চলমান) | `PARTIAL` (IDLE UNVERIFIED) | `UNVERIFIED` | `UNVERIFIED` | `UNVERIFIED` | `UNVERIFIED` | `REQUIRES_COMPANION` | `PARTIAL` |
| Push — mobile (server ছাড়া) | `PARTIAL` (S05: server লাগে) | `UNVERIFIED` | `UNVERIFIED` | `PARTIAL`-প্রবণ | `UNVERIFIED` | `UNSUPPORTED` | `PARTIAL` (S25) |
| Offline | অ্যাপ-নির্ভর: `FULL` (স্থানীয় ক্যাশ) | একই | একই | একই | একই | `REQUIRES_COMPANION` | একই |
| Android | `REQUIRES_PERMISSION` | `REQUIRES_PERMISSION` | `PARTIAL` | `PARTIAL` | `PARTIAL` | **`UNSUPPORTED`** (S17) | `PARTIAL` |
| iOS | `REQUIRES_PERMISSION` | `REQUIRES_PERMISSION` | `PARTIAL` | `PARTIAL` | `PARTIAL` | **`UNSUPPORTED`** (S17) | `PARTIAL` |
| Windows/macOS/Linux | `REQUIRES_PERMISSION` | `REQUIRES_PERMISSION` | `PARTIAL` | `PARTIAL` | `PARTIAL` | `REQUIRES_COMPANION` | `PARTIAL` |
| Quota/sending limit | `UNVERIFIED` | `UNVERIFIED` | `UNVERIFIED` | `UNVERIFIED` | `UNVERIFIED` | Proton-নির্ধারিত (UNVERIFIED) | server-নির্ভর |
| Attachment সীমা | `UNVERIFIED` | `UNVERIFIED` | `UNVERIFIED` | `UNVERIFIED` | `UNVERIFIED` | `UNVERIFIED` | server-নির্ভর |

## ৩. নকশা-প্রভাব
- UI-তে `UNVERIFIED` ও `UNSUPPORTED` feature সক্রিয় দেখানো যাবে না।
- Proton Mail mobile-এ যোগ করার চেষ্টায় স্পষ্ট ব্যাখ্যা-বার্তা (কেন সম্ভব নয়) দেখাতে হবে।
- Matrix মেশিন-পাঠযোগ্য manifest-এ রূপান্তরিত হবে (Phase 1) এবং প্রতিটি ঘরের source ID ধরে রাখবে।
