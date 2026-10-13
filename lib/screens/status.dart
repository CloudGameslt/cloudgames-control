import 'dart:async';

import 'package:flutter/material.dart';

import '../api.dart';
import '../theme.dart';
import '../widgets.dart';
import 'feed.dart';
import 'incidents.dart';

class StatusScreen extends StatefulWidget {
  const StatusScreen({super.key});
  @override
  State<StatusScreen> createState() => _StatusState();
}

class _StatusState extends State<StatusScreen> with WidgetsBindingObserver {
  Map<String, dynamic>? _d;
  List<Map<String, dynamic>> _m = [];
  Object? _err;
  Timer? _t;
  int _h = 24;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
    _t = Timer.periodic(const Duration(seconds: 30), (_) => _load(quiet: true));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    if (s == AppLifecycleState.resumed) _load(quiet: true);
  }

  @override
  void dispose() {
    _t?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _load({bool quiet = false}) async {
    try {
      final r = await Future.wait([Api.i.get('/cgi/overview'), Api.i.get('/cgi/metrics?h=$_h')]);
      if (!mounted) return;
      setState(() {
        _d = Map<String, dynamic>.from(r[0]);
        _m = ((r[1]['series'] ?? []) as List).map((e) => Map<String, dynamic>.from(e)).toList();
        _err = null;
      });
    } catch (e) {
      if (mounted && (!quiet || _d == null)) setState(() => _err = e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(children: [Image.asset('assets/logo.png', height: 30), const SizedBox(width: 10), const Text('Būklė')]),
        actions: [IconButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FeedScreen())), icon: const Icon(Icons.notifications_none_rounded)), const SizedBox(width: 6)],
      ),
      body: _d == null
          ? (_err != null ? ErrorBox(_err!, _load) : const Center(child: CircularProgressIndicator()))
          : RefreshIndicator(color: C.accent, onRefresh: _load, child: _body()),
    );
  }

  Widget _body() {
    final d = _d!, snap = (d['snap'] ?? {}) as Map, s = (snap['sample'] ?? {}) as Map, ch = (snap['checks'] ?? {}) as Map, ai = (d['ai'] ?? {}) as Map;
    final counts = Map<String, dynamic>.from((d['incidents']?['counts'] ?? {}) as Map);
    final open = ((d['incidents']?['open'] ?? []) as List).cast<Map>();
    final crit = (counts['critical'] ?? 0) + (counts['high'] ?? 0), total = counts.values.fold<num>(0, (a, b) => a + (b as num));
    final siteOk = ch['site']?['ok'] == true;
    final good = siteOk && crit == 0;
    num? n(dynamic v) => v is num ? v : null;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: good ? [const Color(0xFF15402B), const Color(0xFF12201A)] : [const Color(0xFF4A1B1F), const Color(0xFF221316)]),
            border: Border.all(color: (good ? C.ok : C.bad).withAlpha(70)),
          ),
          child: Row(children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(shape: BoxShape.circle, color: (good ? C.ok : C.bad).withAlpha(40)),
              child: Icon(good ? Icons.verified_rounded : Icons.warning_amber_rounded, color: good ? C.ok : C.bad, size: 30),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(!siteOk ? 'Svetainė neatsako' : good ? 'Viskas veikia' : 'Reikia dėmesio', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(total == 0 ? 'Atvirų incidentų nėra' : '$total atviri incidentai${crit > 0 ? ' · $crit svarbūs' : ''}', style: const TextStyle(color: C.text2)),
                if (ch['site']?['ms'] != null) Text('API atsakas ${ch['site']['ms']} ms · versija ${d['version'] ?? '—'}', style: const TextStyle(color: C.muted, fontSize: 12)),
              ]),
            ),
          ]),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.75,
          children: [
            Ring(value: n(s['cpu'])?.toDouble(), label: 'CPU', sub: 'load ${s['load1'] ?? '—'} · ${s['cores'] ?? '?'} br.', color: _tone(n(s['cpu']), 70, 90)),
            Ring(value: n(s['mem'])?.toDouble(), label: 'RAM', sub: s['memTotalGb'] != null ? 'iš ${s['memTotalGb']} GB' : '', color: _tone(n(s['mem']), 80, 92)),
            Ring(value: n(s['disk'])?.toDouble(), label: 'Diskas', sub: s['diskFreeGb'] != null ? 'laisva ${s['diskFreeGb']} GB' : '', color: _tone(n(s['disk']), 80, 90)),
            Ring(value: ai['configured'] == true ? 100.0 : 0.0, label: 'CGIntelligent', sub: ai['configured'] == true ? (ai['breaker'] != null && ai['breaker'] != 0 ? 'pauzė' : '${num0(ai['todayTokens'])} tok. šiandien') : 'AI neprijungtas', color: ai['configured'] == true ? C.violet : C.muted),
          ],
        ),
        const SizedBox(height: 12),
        Section(
          'Apkrova',
          trailing: SegmentedButton<int>(
            style: SegmentedButton.styleFrom(visualDensity: VisualDensity.compact, selectedBackgroundColor: C.accent.withAlpha(40), selectedForegroundColor: C.text, foregroundColor: C.muted, side: const BorderSide(color: C.line)),
            showSelectedIcon: false,
            segments: const [ButtonSegment(value: 6, label: Text('6 v.')), ButtonSegment(value: 24, label: Text('24 v.')), ButtonSegment(value: 168, label: Text('7 d.'))],
            selected: {_h},
            onSelectionChanged: (v) { setState(() => _h = v.first); _load(); },
          ),
          child: Column(children: [
            LineChart(data: _m, series: const [('cpu', 'CPU', C.accent), ('mem', 'RAM', C.blue), ('disk', 'Diskas', C.warn)]),
            const SizedBox(height: 16),
            LineChart(data: _m, height: 80, max: null, series: const [('rx', 'Įeina MB/s', C.ok), ('tx', 'Išeina MB/s', C.violet)]),
          ]),
        ),
        const SizedBox(height: 12),
        if (open.isNotEmpty) ...[
          Section('Atviri incidentai', padding: const EdgeInsets.fromLTRB(6, 14, 6, 6), child: Column(children: [for (final x in open.take(6)) IncidentTile(Map<String, dynamic>.from(x), onBack: _load)])),
          const SizedBox(height: 12),
        ],
        Section('Paslaugos', child: Column(children: _services(d))),
        const SizedBox(height: 12),
        if (((d['recommendations'] ?? []) as List).isNotEmpty) ...[
          Section('AI rekomendacijos', child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            for (final r in (d['recommendations'] as List).cast<Map>())
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('#${r['id']} ${r['title']}', style: const TextStyle(fontWeight: FontWeight.w700)),
                  if (r['summary'] != null) Padding(padding: const EdgeInsets.only(top: 4), child: Text('${r['summary']}', style: const TextStyle(color: C.text2, fontSize: 13.5))),
                  for (final p in ((r['plan'] ?? []) as List)) Padding(padding: const EdgeInsets.only(top: 4, left: 6), child: Text('• $p', style: const TextStyle(color: C.muted, fontSize: 13))),
                ]),
              ),
          ])),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  Color _tone(num? v, num w, num b) => v == null ? C.muted : v >= b ? C.bad : v >= w ? C.warn : C.ok;

  List<Widget> _services(Map d) {
    final snap = (d['snap'] ?? {}) as Map, ch = (snap['checks'] ?? {}) as Map;
    final rows = <(Color, String, String)>[];
    final site = ch['site'];
    if (site != null) rows.add((site['ok'] == true ? C.ok : C.bad, 'Svetainės API', site['ok'] == true ? '${site['ms']} ms' : 'neatsako'));
    final pub = ch['public'];
    if (pub != null) rows.add((pub['ok'] == true ? C.ok : C.bad, 'Iš interneto', pub['ok'] == true ? '${pub['ms']} ms' : 'nepasiekiama'));
    if (ch['db'] != null) rows.add((ch['db']['ok'] == true ? C.ok : C.bad, 'Duomenų bazė', ch['db']['ok'] == true ? 'veikia' : 'klaida'));
    final dc = ch['discord'];
    if (dc != null && dc['configured'] == true) rows.add((dc['online'] == true ? C.ok : C.bad, 'Discord botas', dc['online'] == true ? 'prisijungęs' : 'neprisijungęs'));
    if (snap['pm2'] is List) {
      for (final p in (snap['pm2'] as List)) {
        rows.add((p['status'] == 'online' ? C.ok : C.bad, 'PM2: ${p['name']}', '${p['status']} · ${p['memMb']} MB'));
      }
    }
    (snap['services'] as Map? ?? {}).forEach((k, v) => rows.add((v == 'active' ? C.ok : C.bad, 'Paslauga $k', '$v')));
    for (final g in ((ch['gameAgents'] ?? []) as List)) {
      final on = g['online'] == true && g['running'] == true;
      rows.add((g['age'] == null ? C.muted : on ? C.ok : C.bad, 'CS: ${g['name']}', g['online'] == true ? '${g['players'] ?? 0}/${g['max'] ?? 0} · ${g['map'] ?? ''}' : 'neprisijungęs'));
    }
    final b = snap['backup'];
    if (b is Map && b['file'] != null) rows.add(((b['ageH'] ?? 99) < 26 ? C.ok : C.bad, 'Atsarginė kopija', 'prieš ${b['ageH']} val.'));
    final tls = snap['tls'];
    if (tls is Map && tls['days'] != null) rows.add(((tls['days'] as num) >= 14 ? C.ok : C.warn, 'HTTPS sertifikatas', 'liko ${tls['days']} d.'));
    if (rows.isEmpty) return [const Empty('Duomenys renkami…')];
    return [
      for (final r in rows)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 7),
          child: Row(children: [Dot(r.$1), const SizedBox(width: 12), Expanded(child: Text(r.$2, style: const TextStyle(fontWeight: FontWeight.w600))), Text(r.$3, style: const TextStyle(color: C.muted, fontSize: 12.5))]),
        ),
    ];
  }
}
