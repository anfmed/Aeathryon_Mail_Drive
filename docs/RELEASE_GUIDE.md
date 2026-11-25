# RELEASE_GUIDE — Android ও Windows (+ Linux) release

## ১. Android — নিজের signing key (একবার, বিনামূল্যে)
1. কম্পিউটারে (JDK থাকলে `keytool` আছে): 
   `keytool -genkeypair -v -keystore aethryon-release.jks -alias aethryon -keyalg RSA -keysize 4096 -validity 10000`
   (দুটি password চাইবে — মনে রাখুন; নাম/সংস্থা যা খুশি।)
2. **`aethryon-release.jks` ফাইলটি নিরাপদ জায়গায় ২টি কপি রাখুন (পেনড্রাইভ/অফলাইন)।** হারালে Play Store-এ একই অ্যাপের আপডেট দেওয়া যাবে না। কখনো repo-তে দেবেন না (`.gitignore` ঠেকায়)।
3. base64 বানান: Windows PowerShell: `[Convert]::ToBase64String([IO.File]::ReadAllBytes("aethryon-release.jks")) | Set-Clipboard`
4. GitHub → Settings → Secrets and variables → Actions → New repository secret — ৪টি:
   `ANDROID_KEYSTORE_BASE64` (উপরের base64), `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS` (= `aethryon`), `ANDROID_KEY_PASSWORD`।
5. `ci` চালান → APK এখন **আপনার key দিয়ে** সই হয় (`apksigner` ধাপের লগে সার্টিফিকেট-তথ্য দেখাবে)। secrets না থাকলে APK debug-key-এ থাকে — শুধু পরীক্ষার জন্য।
- **Package-id:** `com.aethryon.drive_app` / `com.aethryon.mail_app` (CI-তে `flutter create --org com.aethryon`)। বদলাতে চাইলে `ci.yml`-এর `--org` পরিবর্তন করুন — **প্রকাশের পর আর বদলানো যায় না**।
- **Play Store:** আলাদা ধাপ (Google Play Console-এ একবারের ডেভেলপার-ফি লাগে — পরিমাণ UNVERIFIED; আপনার সিদ্ধান্ত)। এই repo APK দেয়, AAB নয়; Play-তে AAB লাগলে আমাকে বলুন (`flutter build appbundle` যোগ হবে)। সরাসরি APK বিতরণে Play লাগে না (ব্যবহারকারী "unknown sources" অনুমতি দেবেন)।

## ২. Windows
- আউটপুট: `*-windows-x64.zip` (unzip করে `.exe` চালান)। **কোড-সাইনিং নেই** → প্রথমবার Windows SmartScreen "Unknown publisher" সতর্কতা দেখাবে ("More info → Run anyway")। সাইনিং সার্টিফিকেট paid; আপনি চাইলে পরে।
- Microsoft Store/MSIX: স্থগিত (UNVERIFIED খরচ/নিয়ম)।

## ৩. Linux (ঐচ্ছিক টিক)
- আউটপুট: `*-linux-x64.tar.gz`। AppImage/`.deb` প্যাকেজিং এখনো নেই। secure storage-এর জন্য `libsecret` চালু থাকা desktop (GNOME Keyring/KWallet) লাগে — নইলে অ্যাপ পাসওয়ার্ড সংরক্ষণ করতে পারবে না (R-12)।

## ৪. Draft release
`ci` → "draft release" টিক → GitHub Releases-এ **draft** তৈরি হয় (SHA256SUMS সহ)। পড়ে দেখে নিজে "Publish" চাপুন।

## ৫. প্রকাশের আগের তালিকা
☐ `docs/PRIVACY_POLICY_DRAFT.md`-এ `[CONTACT-EMAIL]` বসিয়ে একটি পাবলিক URL-এ রাখা (GitHub Pages/Gist) ☐ আইকন/লোগো ☐ `docs/STORE_LISTING_DRAFT.md` ☐ আসল ফোনে `docs/MEASUREMENT_PROTOCOL.md` ☐ আপনার নিজের account-এ self-test ☐ লাইসেন্স-সিদ্ধান্ত (ADR-021) ☐ আইনি পর্যালোচনা (আমি আইনজীবী নই)।
