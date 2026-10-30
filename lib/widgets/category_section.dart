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

/// বড় আইকন + বড় নামসহ ক্যাটাগরি গ্রিড (৩ কলাম)।
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
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          itemCount: items.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.9,
          ),
          itemBuilder: (_, i) => _CategoryTile(item: items[i]),
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
    return Material(
      color: AppTheme.cardBg,
      borderRadius: BorderRadius.circular(20),
      elevation: AppTheme.isDark ? 0 : 1.5,
      shadowColor: Colors.black26,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: item.onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.divider),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: item.gradient,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: item.gradient.last.withOpacity(0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(item.icon, color: Colors.white, size: 34),
              ),
              const SizedBox(height: 10),
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
      ),
    );
  }
}
