import 'package:flutter/material.dart';

/// একটি লিস্ট যা শুরু হয় নির্দিষ্ট [startIndex] আইটেম থেকে — অনুমান বা
/// বারবার চেষ্টা ছাড়াই, সঙ্গে সঙ্গে ঠিক ঐ আইটেমে। উপরে স্ক্রল করলে আগের
/// আইটেমগুলোও স্বাভাবিকভাবে পাওয়া যায় (লিস্ট lazy — ভারী হয় না)।
///
/// কৌশল: CustomScrollView-এর `center` — [startIndex]-এর আগের আইটেমগুলো
/// উল্টো দিকে বাড়া একটা sliver-এ, বাকিগুলো center sliver-এ।
///
/// স্ক্রল থামলে স্ক্রিনের উপরের দিকে দৃশ্যমান প্রথম আইটেমের ইনডেক্স
/// [onTopIndexChanged]-এ জানায় — "সর্বশেষ পঠিত অবস্থান" সেভ করতে।
class AnchoredList extends StatefulWidget {
  final int itemCount;
  final int startIndex;
  final IndexedWidgetBuilder itemBuilder;
  final ScrollController? controller;
  final double horizontalPadding;
  final double topPadding;
  final double bottomPadding;
  final ValueChanged<int>? onTopIndexChanged;

  const AnchoredList({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.startIndex = 0,
    this.controller,
    this.horizontalPadding = 0,
    this.topPadding = 0,
    this.bottomPadding = 0,
    this.onTopIndexChanged,
  });

  @override
  State<AnchoredList> createState() => _AnchoredListState();
}

class _AnchoredListState extends State<AnchoredList> {
  final Key _centerKey = UniqueKey();
  final Map<int, GlobalKey> _keys = {};

  Widget _wrap(BuildContext context, int i) => KeyedSubtree(
        key: _keys.putIfAbsent(i, () => GlobalKey()),
        child: widget.itemBuilder(context, i),
      );

  /// স্ক্রিনের উপর থেকে প্রথম (আংশিক হলেও) দৃশ্যমান আইটেমের ইনডেক্স।
  int? _firstVisibleIndex() {
    final self = context.findRenderObject();
    if (self is! RenderBox || !self.attached) return null;
    final top = self.localToGlobal(Offset.zero).dy;
    int? best;
    double bestBottom = double.infinity;
    _keys.forEach((i, key) {
      final box = key.currentContext?.findRenderObject();
      if (box is! RenderBox || !box.attached || !box.hasSize) return;
      final bottom = box.localToGlobal(Offset.zero).dy + box.size.height;
      // উপরের কিনারার একটু নিচেও যার শেষ অংশ আছে — সেটাই "এখন যা পড়া হচ্ছে"
      if (bottom > top + 24 && bottom < bestBottom) {
        bestBottom = bottom;
        best = i;
      }
    });
    return best;
  }

  bool _onScrollEnd(ScrollEndNotification n) {
    final cb = widget.onTopIndexChanged;
    if (cb != null) {
      final i = _firstVisibleIndex();
      if (i != null) cb(i);
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final count = widget.itemCount;
    final start = count == 0 ? 0 : widget.startIndex.clamp(0, count - 1);
    final h = widget.horizontalPadding;

    return NotificationListener<ScrollEndNotification>(
      onNotification: _onScrollEnd,
      child: CustomScrollView(
        controller: widget.controller,
        center: _centerKey,
        slivers: [
          if (start > 0)
            SliverPadding(
              padding: EdgeInsets.fromLTRB(h, widget.topPadding, h, 0),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  // আগের আইটেমগুলো center থেকে উপরের দিকে বাড়ে — তাই উল্টো ইনডেক্স
                  (c, i) => _wrap(c, start - 1 - i),
                  childCount: start,
                ),
              ),
            ),
          SliverPadding(
            key: _centerKey,
            padding: EdgeInsets.fromLTRB(
                h, start > 0 ? 6 : widget.topPadding, h, widget.bottomPadding),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (c, i) => _wrap(c, start + i),
                childCount: count - start,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
