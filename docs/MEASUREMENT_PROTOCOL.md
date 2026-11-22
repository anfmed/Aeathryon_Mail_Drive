# MEASUREMENT_PROTOCOL — ডিভাইসে পরিমাপ (P-01, P-02, P-03)
CI-তে বানানো unsigned build দিয়ে। প্রতিটি সংখ্যা ৫ বার নিয়ে মধ্যমা লিখুন।
## Android (সবচেয়ে দুর্বল ফোন)
- ফোনের মডেল, RAM, Android সংস্করণ লিখুন।
- **Cold start (P-01):** অ্যাপ সম্পূর্ণ বন্ধ (Recent apps থেকে সরান) → আইকন ট্যাপ → প্রথম স্ক্রিন সম্পূর্ণ দেখা যাওয়া পর্যন্ত সেকেন্ড (ফোনের স্ক্রিন-রেকর্ডার চালিয়ে ফ্রেম গুনুন, বা `adb shell am start -W <package>/.MainActivity` → `TotalTime`)।
- **Idle RAM (P-03):** অ্যাপ খোলা, ৫ মিনিট কিছু না করে: Settings → Developer options → Running services/Memory; বা `adb shell dumpsys meminfo <package>` → "TOTAL PSS"।
## Windows (৪ GB PC)
- **Cold start (P-01):** Task Manager খুলে অ্যাপ বন্ধ; exe চালান; স্টপওয়াচে প্রথম UI দেখা পর্যন্ত।
- **Idle RAM (P-02):** Task Manager → Details → অ্যাপের "Memory (active private working set)", ৫ মিনিট idle পরে।
- সঙ্গে নোট করুন: অন্য কোন অ্যাপ খোলা ছিল।
## লক্ষ্য (PROPOSED, PERFORMANCE_REQUIREMENTS.md)
P-01 ≤ ২.০ s (low-end Android ≤ ৩.০ s) · P-02 ≤ ১৫০/২০০ MB · P-03 ≤ ১২০ MB। বাজেটের চেয়ে বেশি হলে ADR-003 পুনর্বিবেচনা।
