package com.example.moni_prayer

/**
 * উইজেটের ব্যাকগ্রাউন্ড রং — দিনের সময় অনুযায়ী ধীরে ধীরে (gradually) বদলায়।
 *
 * এই ফাইলে Android-এর কোনো ক্লাস নেই, শুধু হিসাব। তাই আলাদাভাবে টেস্ট করা যায়।
 *
 * কীভাবে কাজ করে:
 *  - দিনকে ১৪টা ধাপে ভাগ করা হয়েছে (ফজর, সূর্যোদয়, সকাল, ৯–১০টা, দুপুর,
 *    দুপুর গড়ানো, বিকেল, বিকেলের শেষ, সূর্যাস্ত, গোধূলি, এশা, রাত, গভীর রাত,
 *    তাহাজ্জুদ)। ধাপের সীমা আসল ওয়াক্তের সময় থেকে ঠিক হয়।
 *  - প্রতিটা ধাপের একটা নিজস্ব রং আছে (আগের গ্র্যাডিয়েন্টের "নিচের" রং)।
 *  - ধাপের ঠিক মাঝখানে রংটা পুরোপুরি সেই ধাপের রং। এক ধাপের মাঝ থেকে
 *    পরের ধাপের মাঝ পর্যন্ত রংটা মসৃণভাবে (smoothstep) মিশে যায় — হঠাৎ লাফ
 *    নেই, আকাশের রং যেভাবে ধীরে ধীরে বদলায় সেভাবে।
 *  - নিষিদ্ধ সময়ে ধীরে ধীরে নয়, সঙ্গে সঙ্গে পুরো লাল (শুরু হওয়া মাত্র লাল,
 *    শেষ হওয়া মাত্র লাল চলে যায়) — যাতে কেউ ভুল করে নামাজ না পড়ে।
 */
object SkyColor {

    // ═══ রং বদলাতে চাইলে শুধু নিচের hex (RRGGBB) গুলো বদলান ═══
    private val FAJR = argb(0x2F2940)        // ভোর/ফজর
    private val SUNRISE = argb(0x4C163C)     // সূর্যোদয়
    private val MORNING1 = argb(0x0F3B48)    // সকাল
    private val MORNING2 = argb(0x15416E)    // ৯–১০টা
    private val NOON = argb(0x102B5C)        // দুপুর
    private val AFTERNOON1 = argb(0x25374E)  // দুপুর গড়ানো
    private val ASR1 = argb(0x482914)        // বিকেল
    private val ASR2 = argb(0x4C2218)        // বিকেলের শেষ
    private val SUNSET = argb(0x4B1F42)      // সূর্যাস্ত
    private val DUSK = argb(0x251745)        // গোধূলি
    private val ISHA = argb(0x0D1838)        // এশা
    private val NIGHT = argb(0x09091B)       // রাত
    private val DEEPNIGHT = argb(0x040611)   // গভীর রাত
    private val TAHAJJUD = argb(0x140F35)    // শেষ রাত/তাহাজ্জুদ

    // নিষিদ্ধ সময়ের লাল (সঙ্গে সঙ্গে বসে, সঙ্গে সঙ্গে যায়)
    private val FORBIDDEN_RED = argb(0x9A2212)
    // ওয়াক্তের ডেটা না থাকলে আগের মতো গাঢ় সবুজ
    private val DEFAULT = argb(0x1B2E1F)

    private const val MIN = 60_000L
    private const val DAY = 24L * 60L * MIN

    private fun argb(rgb: Int): Int = (0xFF shl 24) or rgb

    /** এই মুহূর্তের ব্যাকগ্রাউন্ড রং (ARGB Int)। */
    fun backgroundColor(
        isForbidden: Boolean,
        nowMs: Long,
        fajr: Long, sunrise: Long, dhuhr: Long, asr: Long, maghrib: Long, isha: Long
    ): Int {
        if (isForbidden) return FORBIDDEN_RED
        if (fajr <= 0L || sunrise <= 0L || dhuhr <= 0L || asr <= 0L || maghrib <= 0L || isha <= 0L) {
            return DEFAULT
        }
        return skyColorAt(nowMs, fajr, sunrise, dhuhr, asr, maghrib, isha)
    }

    internal fun skyColorAt(
        nowMs: Long,
        f: Long, s: Long, d: Long, a: Long, m: Long, i: Long
    ): Int {
        // শেষ-তৃতীয়াংশ (তাহাজ্জুদ শুরু): মাগরিব থেকে পরের ফজর পর্যন্ত রাতের ২/৩ অংশ পরে
        val last = m + (f + DAY - m) * 2L / 3L
        val asrMid = a + (m - a) * 45L / 100L

        // ১৪টা ধাপের সীমা (১৫টা বিন্দু); ধাপ n = [b[n], b[n+1]]
        val b = longArrayOf(
            f, s, s + 45 * MIN, s + 150 * MIN, d - 90 * MIN, d + 60 * MIN, a,
            asrMid, m - 30 * MIN, m + 25 * MIN, i, i + 90 * MIN, i + 240 * MIN, last, f + DAY
        )
        // সময়গুলো বেমানান (যেমন মেরু অঞ্চল/ভুল ডেটা) হলে নিরাপদ রং
        for (n in 0 until b.size - 1) {
            if (b[n + 1] <= b[n]) return DEFAULT
        }
        val cols = intArrayOf(
            FAJR, SUNRISE, MORNING1, MORNING2, NOON, AFTERNOON1, ASR1,
            ASR2, SUNSET, DUSK, ISHA, NIGHT, DEEPNIGHT, TAHAJJUD
        )

        // প্রতিটা ধাপের মাঝখানে "পুরো সেই রং" — আগের দিন, আজ, পরের দিন (রাত ঘুরে আসার জন্য)
        val ts = LongArray(cols.size * 3)
        val cs = IntArray(cols.size * 3)
        var n = 0
        for (k in -1..1) {
            for (c in cols.indices) {
                ts[n] = (b[c] + b[c + 1]) / 2L + k * DAY
                cs[n] = cols[c]
                n++
            }
        }

        if (nowMs <= ts[0]) return cs[0]
        if (nowMs >= ts[n - 1]) return cs[n - 1]
        var idx = 0
        while (idx < n - 2 && nowMs >= ts[idx + 1]) idx++

        val x = (nowMs - ts[idx]).toDouble() / (ts[idx + 1] - ts[idx]).toDouble()
        val eased = x * x * (3.0 - 2.0 * x)   // smoothstep: দুই প্রান্তে ধীর, মাঝে একটু দ্রুত
        return mix(cs[idx], cs[idx + 1], eased)
    }

    private fun mix(c0: Int, c1: Int, t: Double): Int {
        fun ch(shift: Int): Int {
            val a = (c0 shr shift) and 0xFF
            val b = (c1 shr shift) and 0xFF
            return Math.round(a + (b - a) * t).toInt().coerceIn(0, 255)
        }
        return (0xFF shl 24) or (ch(16) shl 16) or (ch(8) shl 8) or ch(0)
    }
}
