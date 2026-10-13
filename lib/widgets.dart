import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'api.dart';
import 'theme.dart';

const sevLabel = {'info': 'Info', 'warn': 'Įspėjimas', 'high': 'Aukštas', 'critical': 'Kritinis', 'medium': 'Vidutinis', 'low': 'Žemas'};
const stLabel = {'new': 'Naujas', 'analyzing': 'Analizuojamas', 'awaiting': 'Laukia patvirtinimo', 'resolved': 'Išspręstas', 'dismissed': 'Atmestas', 'pending': 'Laukia', 'executed': 'Įvykdyta', 'failed': 'Nepavyko', 'rejected': 'Atmesta', 'expired': 'Pasibaigė', 'approved': 'Patvirtinta'};

Color sevColor(String? s) => switch (s) { 'critical' || 'high' => C.bad, 'warn' || 'medium' => C.warn, 'info' || 'low' => C.blue, _ => C.muted };
Color stColor(String? s) => switch (s) { 'new' || 'failed' => C.bad, 'analyzing' || 'awaiting' || 'pending' => C.warn, 'resolved' || 'executed' || 'approved' => C.ok, _ => C.muted };

String ago(dynamic ms) {
  final v = ms is num ? ms.toInt() : int.tryParse('$ms') ?? 0;
  if (v == 0) return '—';
  final s = DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(v)).inSeconds;
  if (s < 60) return 'ką tik';
  if (s < 3600) return 'prieš ${s ~/ 60} min.';
  if (s < 86400) return 'prieš ${s ~/ 3600} val.';
  return 'prieš ${s ~/ 86400} d.';
}

String when(dynamic ms) {
  final v = ms is num ? ms.toInt() : int.tryParse('$ms') ?? 0;
  if (v == 0) return '—';
  final d = DateTime.fromMillisecondsSinceEpoch(v);
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(d.month)}-${two(d.day)} ${two(d.hour)}:${two(d.minute)}';
}

String num0(dynamic v) {
  final n = v is num ? v : num.tryParse('$v') ?? 0;
  final s = n.round().toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(' ');
    b.write(s[i]);
  }
  return b.toString();
}

class Pill extends StatelessWidget {
  final String text;
  final Color color;
  const Pill(this.text, this.color, {super.key});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(color: color.withAlpha(34), borderRadius: BorderRadius.circular(20)),
        child: Text(text, style: TextStyle(color: color, fontSize: 11.5, fontWeight: FontWeight.w700)),
      );
}

class Dot extends StatelessWidget {
  final Color color;
  final double size;
  const Dot(this.color, {super.key, this.size = 9});
  @override
  Widget build(BuildContext context) => Container(width: size, height: size, decoration: BoxDecoration(color: color, shape: BoxShape.circle, boxShadow: [BoxShadow(color: color.withAlpha(90), blurRadius: 8, spreadRadius: 1)]));
}

class Section extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? trailing;
  final EdgeInsets padding;
  const Section(this.title, {super.key, required this.child, this.trailing, this.padding = const EdgeInsets.fromLTRB(16, 14, 16, 16)});
  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: padding,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(title.toUpperCase(), style: const TextStyle(fontSize: 11.5, letterSpacing: 1.2, fontWeight: FontWeight.w700, color: C.muted))),
              if (trailing != null) trailing!,
            ]),
            const SizedBox(height: 12),
            child,
          ]),
        ),
      );
}

class Empty extends StatelessWidget {
  final String text;
  final IconData icon;
  const Empty(this.text, {super.key, this.icon = Icons.inbox_outlined});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 28),
        child: Column(children: [Icon(icon, color: C.muted.withAlpha(140), size: 34), const SizedBox(height: 10), Text(text, textAlign: TextAlign.center, style: const TextStyle(color: C.muted))]),
      );
}

class ErrorBox extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;
  const ErrorBox(this.error, this.onRetry, {super.key});
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.cloud_off_rounded, size: 44, color: C.muted),
            const SizedBox(height: 12),
            Text(error is ApiError ? '$error' : 'Nepavyko įkelti duomenų', textAlign: TextAlign.center, style: const TextStyle(color: C.text2)),
            const SizedBox(height: 16),
            OutlinedButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh_rounded), label: const Text('Bandyti dar kartą')),
          ]),
        ),
      );
}

class Ring extends StatelessWidget {
  final double? value;
  final String label;
  final String sub;
  final Color color;
  const Ring({super.key, required this.value, required this.label, required this.sub, required this.color});
  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            SizedBox(
              width: 58,
              height: 58,
              child: CustomPaint(
                painter: _RingPainter((value ?? 0).clamp(0, 100) / 100, color),
                child: Center(child: Text(value == null ? '—' : '${value!.round()}%', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14))),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                const SizedBox(height: 3),
                Text(sub, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: C.muted, fontSize: 11.5)),
              ]),
            ),
          ]),
        ),
      );
}

class _RingPainter extends CustomPainter {
  final double v;
  final Color color;
  _RingPainter(this.v, this.color);
  @override
  void paint(Canvas canvas, Size size) {
    final r = Rect.fromLTWH(4, 4, size.width - 8, size.height - 8);
    canvas.drawArc(r, 0, math.pi * 2, false, Paint()..color = C.line..style = PaintingStyle.stroke..strokeWidth = 6);
    canvas.drawArc(r, -math.pi / 2, math.pi * 2 * v, false, Paint()..shader = SweepGradient(colors: [color.withAlpha(150), color], transform: const GradientRotation(-math.pi / 2)).createShader(r)..style = PaintingStyle.stroke..strokeWidth = 6..strokeCap = StrokeCap.round);
  }

  @override
  bool shouldRepaint(_RingPainter o) => o.v != v || o.color != color;
}

class LineChart extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  final List<(String, String, Color)> series;
  final double height;
  final double? max;
  const LineChart({super.key, required this.data, required this.series, this.height = 130, this.max = 100});
  @override
  Widget build(BuildContext context) {
    if (data.length < 2) return SizedBox(height: height, child: const Center(child: Text('Metrikos dar kaupiamos', style: TextStyle(color: C.muted))));
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(height: height, width: double.infinity, child: CustomPaint(painter: _LinePainter(data, series, max))),
      const SizedBox(height: 10),
      Wrap(spacing: 14, runSpacing: 6, children: [
        for (final s in series)
          Row(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 10, height: 3, decoration: BoxDecoration(color: s.$3, borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 6),
            Text('${s.$2}: ', style: const TextStyle(color: C.muted, fontSize: 12)),
            Text(_last(s.$1), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
          ]),
      ]),
    ]);
  }

  String _last(String k) {
    final v = data.last[k];
    if (v == null) return '—';
    return max == 100 ? '${(v as num).round()}%' : (v as num).toStringAsFixed(1);
  }
}

class _LinePainter extends CustomPainter {
  final List<Map<String, dynamic>> d;
  final List<(String, String, Color)> s;
  final double? max;
  _LinePainter(this.d, this.s, this.max);
  @override
  void paint(Canvas canvas, Size size) {
    var mx = max ?? 0;
    for (final row in d) {
      for (final x in s) {
        final v = row[x.$1];
        if (v is num && v > mx) mx = v.toDouble();
      }
    }
    if (mx <= 0) mx = 1;
    final grid = Paint()..color = C.line..strokeWidth = 1;
    for (final f in [0.25, 0.5, 0.75]) {
      final y = size.height * (1 - f);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    for (final x in s) {
      final path = Path(), fill = Path();
      var started = false;
      double lastX = 0;
      for (var i = 0; i < d.length; i++) {
        final v = d[i][x.$1];
        if (v is! num) continue;
        final px = size.width * i / (d.length - 1), py = size.height - (v / mx) * (size.height - 6) - 3;
        if (!started) {
          path.moveTo(px, py);
          fill.moveTo(px, size.height);
          fill.lineTo(px, py);
          started = true;
        } else {
          path.lineTo(px, py);
          fill.lineTo(px, py);
        }
        lastX = px;
      }
      if (!started) continue;
      fill.lineTo(lastX, size.height);
      fill.close();
      canvas.drawPath(fill, Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [x.$3.withAlpha(60), x.$3.withAlpha(0)]).createShader(Offset.zero & size));
      canvas.drawPath(path, Paint()..color = x.$3..style = PaintingStyle.stroke..strokeWidth = 2..strokeJoin = StrokeJoin.round);
    }
  }

  @override
  bool shouldRepaint(_LinePainter o) => true;
}

class Md extends StatelessWidget {
  final String text;
  final double size;
  const Md(this.text, {super.key, this.size = 14.5});

  List<InlineSpan> _inline(String s) {
    final out = <InlineSpan>[];
    final re = RegExp(r'\*\*([^*]+)\*\*|`([^`]+)`');
    var i = 0;
    for (final m in re.allMatches(s)) {
      if (m.start > i) out.add(TextSpan(text: s.substring(i, m.start)));
      if (m.group(1) != null) {
        out.add(TextSpan(text: m.group(1), style: const TextStyle(fontWeight: FontWeight.w700)));
      } else {
        out.add(TextSpan(text: m.group(2), style: TextStyle(fontFamily: 'monospace', fontSize: size - 1.5, color: C.accent2, backgroundColor: C.bg.withAlpha(120))));
      }
      i = m.end;
    }
    if (i < s.length) out.add(TextSpan(text: s.substring(i)));
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final parts = text.split('```');
    final kids = <Widget>[];
    for (var p = 0; p < parts.length; p++) {
      if (p.isOdd) {
        final code = parts[p].replaceFirst(RegExp(r'^\w*\n'), '').trimRight();
        kids.add(Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: C.bg, borderRadius: BorderRadius.circular(10), border: Border.all(color: C.line)),
          child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: SelectableText(code, style: const TextStyle(fontFamily: 'monospace', fontSize: 12.5, color: C.text2))),
        ));
        continue;
      }
      for (final line in parts[p].split('\n')) {
        final t = line.trimRight();
        if (t.trim().isEmpty) continue;
        final h = RegExp(r'^#{1,4}\s+(.+)').firstMatch(t);
        final li = RegExp(r'^\s*(?:[-*•]|\d+[.)])\s+(.+)').firstMatch(t);
        if (h != null) {
          kids.add(Padding(padding: const EdgeInsets.only(top: 8, bottom: 4), child: Text(h.group(1)!, style: TextStyle(fontWeight: FontWeight.w800, fontSize: size + 1))));
        } else if (li != null) {
          kids.add(Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 4),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Padding(padding: EdgeInsets.only(top: size * 0.55, right: 8), child: Container(width: 5, height: 5, decoration: const BoxDecoration(color: C.accent, shape: BoxShape.circle))),
              Expanded(child: Text.rich(TextSpan(children: _inline(li.group(1)!)), style: TextStyle(fontSize: size, height: 1.45))),
            ]),
          ));
        } else {
          kids.add(Padding(padding: const EdgeInsets.only(bottom: 6), child: Text.rich(TextSpan(children: _inline(t)), style: TextStyle(fontSize: size, height: 1.45))));
        }
      }
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: kids);
  }
}

Future<String?> askCode(BuildContext context, String title, String subtitle) {
  final c = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(subtitle, style: const TextStyle(color: C.muted)),
        const SizedBox(height: 14),
        TextField(controller: c, autofocus: true, keyboardType: TextInputType.number, maxLength: 9, textAlign: TextAlign.center, style: const TextStyle(fontSize: 24, letterSpacing: 8, fontWeight: FontWeight.w700), decoration: const InputDecoration(counterText: '', hintText: '000000')),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Atšaukti')),
        FilledButton(onPressed: () => Navigator.pop(ctx, c.text.trim()), child: const Text('Patvirtinti')),
      ],
    ),
  );
}

void toast(BuildContext context, String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
