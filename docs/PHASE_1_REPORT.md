# Phase 1 — Foundation: প্রতিবেদন
**অবস্থা:** লেখা সম্পন্ন; build-যাচাই বাকি।
**করা হয়েছে:** monorepo; `aethryon_capability` (FULL-এ source বাধ্যতামূলক), `aethryon_net` (backoff+jitter, Retry-After, token-bucket), `aethryon_log` (token/email/opaque redaction), `aethryon_auth` (PKCE S256, TokenSet, TokenStore interface — secret লগে যায় না), `aethryon_platform` (interface); CI: `ci-core` ও `build-apps` (৫ platform × ২ অ্যাপ, unsigned); dependency-gate রিপোর্ট; app shell ×২; সব OPEN ADR নিষ্পত্তি।
**না করা:** নেটিভ binding, signing, Flutter-ট্যাগ pin।
**ঝুঁকি:** R-06 (Flutter পরিমাপ), R-19।
**Exit gate:** `ci-core` সবুজ + `build-apps`-এ অন্তত Android ও Windows সবুজ।
