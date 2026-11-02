import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

// নফল নামাজ / রোজা / আমল পেজগুলোর শেয়ার্ড কার্ড ও হেডার।

class FastCard extends StatelessWidget {
  final String icon, title, dates, desc;
  final Color color;
  final String? alert;
  const FastCard({
    required this.icon,
    required this.title,
    required this.dates,
    required this.desc,
    required this.color,
    this.alert,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(icon, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 10),
          Expanded(child: Text(title,
              style: TextStyle(color: AppTheme.readable(color), fontSize: 16, fontWeight: FontWeight.bold))),
        ]),
        const SizedBox(height: 6),
        Row(children: [
          Icon(Icons.calendar_today, size: 14, color: AppTheme.soft),
          const SizedBox(width: 6),
          Expanded(child: Text(dates,
              style: TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w600))),
        ]),
        const SizedBox(height: 8),
        Text(desc,
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.5)),
        if (alert != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(alert!,
                style: TextStyle(color: AppTheme.readable(color), fontSize: 14, fontWeight: FontWeight.bold)),
          ),
        ],
      ]),
    );
  }
}

class ProhibitedRow extends StatelessWidget {
  final String icon, title, desc;
  const ProhibitedRow(this.icon, this.title, this.desc);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(icon, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: const TextStyle(color: AppTheme.missed, fontSize: 14, fontWeight: FontWeight.bold)),
          Text(desc,
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.4)),
        ])),
      ]),
    );
  }
}

class AmalCard extends StatefulWidget {
  final String num, title, desc;
  final Color color;
  const AmalCard({
    required this.num,
    required this.title,
    required this.desc,
    required this.color,
  });

  @override
  State<AmalCard> createState() => AmalCardState();
}

class AmalCardState extends State<AmalCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: widget.color.withOpacity(0.3)),
      ),
      child: Column(children: [
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: widget.color.withOpacity(_expanded ? 0.15 : 0.05),
              borderRadius: _expanded
                  ? const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12))
                  : BorderRadius.circular(12),
            ),
            child: Row(children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: widget.color,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(
                  child: Text(widget.num,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(widget.title,
                    style: TextStyle(
                        color: AppTheme.readable(widget.color), fontSize: 14, fontWeight: FontWeight.bold)),
              ),
              Icon(
                _expanded ? Icons.expand_less : Icons.expand_more,
                color: AppTheme.readable(widget.color),
                size: 20,
              ),
            ]),
          ),
        ),
        if (_expanded)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
            child: Text(widget.desc,
                style: TextStyle(
                    color: AppTheme.textPrimary, fontSize: 13, height: 1.6)),
          ),
      ]),
    );
  }
}

Widget nflSectionHeader(String icon, String title, Color color) {
  return Row(children: [
    Text(icon, style: const TextStyle(fontSize: 22)),
    const SizedBox(width: 10),
    Expanded(
        child: Text(title,
            style: TextStyle(
                color: AppTheme.readable(color), fontSize: 17, fontWeight: FontWeight.bold))),
  ]);
}
