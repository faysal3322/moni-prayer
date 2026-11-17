import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

/// হোম স্ক্রিনের "ক্যাটাগরি" গ্রিডের একটা আইটেম।
class CategoryItem {
  final String label;
  final IconData icon;
  final List<Color> gradient;
  final VoidCallback onTap;

  const CategoryItem({
    required this.label,
    required this.icon,
    required this.gradient,
    required this.onTap,
  });
}

/// মর্ডান ক্যাটাগরি গ্রিড: একটাই নরম কার্ডের ভেতরে ৪ কলাম।
/// আইকন ছোট ও হালকা রঙের ব্যাকগ্রাউন্ডে (ডুয়োটোন স্টাইল), নাম আগের সাইজেই (১৫, বোল্ড)।
/// নতুন ক্যাটাগরি যোগ করতে শুধু [items] লিস্টে একটা [CategoryItem] বাড়ান।
class CategorySection extends StatelessWidget {
  final String title;
  final List<CategoryItem> items;

  const CategorySection({super.key, required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: AppTheme.gold,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: AppTheme.gold,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(4, 10, 4, 6),
          decoration: BoxDecoration(
            color: AppTheme.cardBg,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppTheme.divider),
            boxShadow: AppTheme.isDark
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: items.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 2,
              crossAxisSpacing: 0,
              mainAxisExtent: 98,
            ),
            itemBuilder: (_, i) => _CategoryTile(item: items[i]),
          ),
        ),
      ],
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final CategoryItem item;
  const _CategoryTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark;
    final accent = isDark ? item.gradient.first : item.gradient.last;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: item.onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ছোট, নরম রঙের স্কুইর্কল + গ্রেডিয়েন্ট আইকন
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    item.gradient.first.withOpacity(isDark ? 0.28 : 0.16),
                    item.gradient.last.withOpacity(isDark ? 0.18 : 0.08),
                  ],
                ),
                border: Border.all(color: accent.withOpacity(0.18)),
              ),
              child: ShaderMask(
                blendMode: BlendMode.srcIn,
                shaderCallback: (r) => LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [item.gradient.first, item.gradient.last],
                ).createShader(r),
                child: Icon(item.icon, color: Colors.white, size: 27),
              ),
            ),
            const SizedBox(height: 8),
            // নামের সাইজ আগের মতোই (১৫); জায়গা কম হলে নিজে ছোট হয়ে এক লাইনে থাকবে
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                item.label,
                maxLines: 1,
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
