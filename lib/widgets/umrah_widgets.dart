import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/umrah_data.dart';
import '../utils/app_language.dart';
import '../utils/app_theme.dart';
import '../utils/umrah_progress.dart';

/// ওমরাহ স্ক্রিনগুলোর সবুজ বাটনের রঙ
const Color kUmrahGreen = Color(0xFF3F9468);

Widget umrahBox({required Widget child, Color? border, Color? fill}) {
  return Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: fill ?? AppTheme.cardBg,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: border ?? AppTheme.divider),
    ),
    child: child,
  );
}

Widget umrahSectionLabel(String text, Color color) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text,
      style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.bold),
    ),
  );
}

/// বড় সবুজ বাটন (স্ক্রিনশটের মতো — গোল কোণ, ডানে তীর)
class UmrahPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData icon;
  const UmrahPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon = Icons.arrow_forward,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: enabled ? kUmrahGreen : AppTheme.divider24,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: enabled ? Colors.white : AppTheme.soft,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Icon(icon, color: enabled ? Colors.white : AppTheme.soft),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// পুরুষ / নারী নির্বাচন
class UmrahGenderChips extends StatelessWidget {
  final AppLanguage lang;
  const UmrahGenderChips({super.key, required this.lang});

  @override
  Widget build(BuildContext context) {
    final p = UmrahProgress.instance;
    return AnimatedBuilder(
      animation: p,
      builder: (_, __) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ChoiceChip(
            label: Text(lang.isBn ? 'পুরুষ' : 'Male',
                style: const TextStyle(fontSize: 12)),
            selected: !p.female,
            onSelected: (_) => p.setFemale(false),
            visualDensity: VisualDensity.compact,
          ),
          const SizedBox(width: 6),
          ChoiceChip(
            label: Text(lang.isBn ? 'নারী' : 'Female',
                style: const TextStyle(fontSize: 12)),
            selected: p.female,
            onSelected: (_) => p.setFemale(true),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

/// দোয়া কার্ড (আরবি · উচ্চারণ · অর্থ)
class UmrahDuaCard extends StatelessWidget {
  final UmrahDua dua;
  final AppLanguage lang;
  const UmrahDuaCard({super.key, required this.dua, required this.lang});

  @override
  Widget build(BuildContext context) {
    final d = dua;
    return umrahBox(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  d.title,
                  style: TextStyle(
                    color: AppTheme.gold,
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {
                  Clipboard.setData(
                    ClipboardData(
                      text: '${d.arabic}\n\n${d.translit}\n\n${d.meaning}',
                    ),
                  );
                  ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(
                      SnackBar(
                        content: Text(lang.isBn ? 'কপি হয়েছে' : 'Copied'),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                },
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child:
                      Icon(Icons.copy_rounded, size: 18, color: AppTheme.soft),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Directionality(
            textDirection: TextDirection.rtl,
            child: SizedBox(
              width: double.infinity,
              child: Text(
                d.arabic,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'ScheherazadeNew',
                  fontSize: 26,
                  height: 2.0,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            d.translit,
            style: TextStyle(
              color: AppTheme.accent,
              fontSize: 14,
              height: 1.6,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            d.meaning,
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 14,
              height: 1.6,
            ),
          ),
          if (d.note.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.overlay.withOpacity(0.05),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                d.note,
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12.5,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// তাওয়াফ / সাঈ কাউন্টার (আগের লজিকই, [UmrahProgress]-এ সেভ হয়)
class UmrahCounterCard extends StatelessWidget {
  final UmrahCounter kind;
  final AppLanguage lang;
  const UmrahCounterCard({super.key, required this.kind, required this.lang});

  @override
  Widget build(BuildContext context) {
    final p = UmrahProgress.instance;
    final bn = lang.isBn;
    String t(String b, String e) => bn ? b : e;
    String n(int v) => lang.toLocalNum(v);

    final isTawaf = kind == UmrahCounter.tawaf;
    final count = p.counterOf(kind);
    final done = count >= 7;
    final next = count + 1;

    String title;
    String hint;
    String? hint2;
    if (isTawaf) {
      title = t('তাওয়াফ কাউন্টার', 'Tawaf counter');
      if (done) {
        hint = t(
          'সাত চক্কর পূর্ণ! হাজরে আসওয়াদে আবার ইসতিলাম (অষ্টমবার) করুন, চাদর দিয়ে দুই কাঁধ ঢেকে নিন, তারপর দুই রাকাত নামাজ।',
          'Seven rounds complete! Make istilam once more, cover both shoulders, then pray two rak\'ahs.',
        );
      } else if (count == 0) {
        hint = t(
          'হাজরে আসওয়াদ বরাবর দাঁড়িয়ে ইসতিলাম করে ১ম চক্কর শুরু করুন। কাবা থাকবে আপনার বামে।',
          'Face the Black Stone, make istilam and begin round 1. The Kaaba stays on your left.',
        );
      } else if (next <= 3) {
        hint = t(
          '${n(next)}ম চক্কর: পুরুষরা রমল করুন (কাঁধ হেলিয়ে একটু দ্রুত ছোট পদক্ষেপ)। হাজরে আসওয়াদ বরাবর এলে ইসতিলাম।',
          'Round $next: men do raml (brisk short steps). Istilam at the Black Stone.',
        );
      } else {
        hint = t(
          '${n(next)}ম চক্কর: স্বাভাবিক গতিতে হাঁটুন। হাজরে আসওয়াদ বরাবর এলে ইসতিলাম।',
          'Round $next: walk normally. Istilam at the Black Stone.',
        );
      }
      hint2 = done
          ? null
          : t(
              'রুকনে ইয়ামানী থেকে হাজরে আসওয়াদের মাঝে: “রাব্বানা আতিনা ফিদ দুনইয়া হাসানাহ…”',
              'Between the Yemeni corner and the Black Stone: "Rabbana atina…"',
            );
    } else {
      title = t('সাঈ কাউন্টার', 'Sa\'i counter');
      final atSafa = count % 2 == 0;
      if (done) {
        hint = t(
          'সাত চক্কর পূর্ণ — আপনি এখন মারওয়ায়। সাঈ শেষ!',
          'Seven laps done — you are at Marwa. Sa\'i complete!',
        );
      } else if (count == 0) {
        hint = t(
          'সাফায় যান: “ইন্নাস সাফা ওয়াল মারওয়াতা মিন শা‘আইরিল্লাহ — আবদাউ বিমা বাদাআল্লাহু বিহি”, কিবলামুখী হয়ে তিনবার তাকবীর, দোয়া। তারপর মারওয়ার দিকে ১ম চক্কর শুরু করুন।',
          'Go to Safa, recite the verse, face the Kaaba, takbeer and dua, then start lap 1 toward Marwa.',
        );
      } else {
        hint = t(
          '${n(next)}ম চক্কর: ${atSafa ? 'সাফা থেকে মারওয়ার' : 'মারওয়া থেকে সাফার'} দিকে। এখন আপনি ${atSafa ? 'সাফায়' : 'মারওয়ায়'} — কিবলামুখী হয়ে দোয়া করে রওনা হোন।',
          'Lap $next: ${atSafa ? 'Safa → Marwa' : 'Marwa → Safa'}.',
        );
      }
      hint2 = done
          ? null
          : t(
              'দুই সবুজ বাতির মাঝে পুরুষ দ্রুত চলবেন; নারী স্বাভাবিক গতিতে।',
              'Men move briskly between the green lights; women walk normally.',
            );
    }

    void inc() {
      if (count >= 7) return;
      HapticFeedback.mediumImpact();
      p.setCounter(kind, count + 1);
    }

    return umrahBox(
      border: AppTheme.gold.withOpacity(0.5),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              color: AppTheme.gold,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: inc,
            child: SizedBox(
              width: 150,
              height: 150,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox.expand(
                    child: CircularProgressIndicator(
                      value: count / 7,
                      strokeWidth: 10,
                      backgroundColor: AppTheme.divider,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        done ? AppTheme.completed : AppTheme.gold,
                      ),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        n(count),
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 46,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '/ ${n(7)}',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            hint,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 14,
              height: 1.6,
            ),
          ),
          if (hint2 != null) ...[
            const SizedBox(height: 6),
            Text(
              hint2,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12.5,
                height: 1.5,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              IconButton(
                tooltip: t('একটি পিছনে', 'Undo'),
                onPressed: count > 0 ? () => p.setCounter(kind, count - 1) : null,
                icon: const Icon(Icons.undo),
              ),
              Expanded(
                child: ElevatedButton(
                  onPressed: done ? null : inc,
                  child: Text(
                    done
                        ? t('সম্পন্ন ✅', 'Done ✅')
                        : t('${n(next)}ম চক্কর সম্পন্ন (+১)',
                            'Round $next done (+1)'),
                  ),
                ),
              ),
              IconButton(
                tooltip: t('আবার ০ থেকে', 'Reset'),
                onPressed: count > 0 ? () => p.setCounter(kind, 0) : null,
                icon: const Icon(Icons.restart_alt),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
