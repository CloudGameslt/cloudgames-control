import 'dart:convert';

import 'package:flutter/material.dart';

import '../api.dart';
import '../theme.dart';
import '../widgets.dart';

class ActionsScreen extends StatefulWidget {
  const ActionsScreen({super.key});
  @override
  State<ActionsScreen> createState() => _ActionsState();
}

class _ActionsState extends State<ActionsScreen> {
  Map<String, dynamic>? _d;
  Object? _err;
  String? _running;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final d = await Api.i.get('/cgi/actions');
      if (mounted) setState(() { _d = Map<String, dynamic>.from(d); _err = null; });
    } catch (e) {
      if (mounted) setState(() => _err = e);
    }
  }

  Future<void> _decide(Map p, bool ok) async {
    final code = await askCode(context, ok ? 'Patvirtinti veiksmą' : 'Atmesti pasiūlymą', ok ? '„${p['title']}“ bus įvykdytas iš karto. Įvesk 2FA kodą.' : 'Įvesk 2FA kodą.');
    if (code == null || code.isEmpty) return;
    try {
      final r = await Api.i.post('/cgi/proposals/${p['id']}/${ok ? 'approve' : 'reject'}', {'code': code});
      if (mounted) toast(context, r['status'] == 'executed' ? 'Įvykdyta' : r['status'] == 'failed' ? 'Vykdymas nepavyko' : 'Atmesta');
    } catch (e) {
      if (mounted) toast(context, '$e');
    }
    _load();
  }

  Future<void> _run(Map a) async {
    setState(() => _running = a['id']);
    try {
      final r = await Api.i.post('/cgi/run/${a['id']}');
      if (!mounted) return;
      final res = r['result'];
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (ctx) => DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          builder: (_, sc) => ListView(controller: sc, padding: const EdgeInsets.fromLTRB(20, 0, 20, 24), children: [
            Text('${a['title']}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            SelectableText(res is String ? res : const JsonEncoder.withIndent('  ').convert(res), style: const TextStyle(fontFamily: 'monospace', fontSize: 12, color: C.text2)),
          ]),
        ),
      );
    } catch (e) {
      if (mounted) toast(context, '$e');
    }
    if (mounted) setState(() => _running = null);
  }

  @override
  Widget build(BuildContext context) {
    final d = _d;
    return Scaffold(
      appBar: AppBar(title: const Text('Veiksmai')),
      body: d == null
          ? (_err != null ? ErrorBox(_err!, _load) : const Center(child: CircularProgressIndicator()))
          : RefreshIndicator(
              color: C.accent,
              onRefresh: _load,
              child: Builder(builder: (_) {
                final all = ((d['proposals'] ?? []) as List).cast<Map>();
                final pend = all.where((p) => p['status'] == 'pending' && p['expired'] != true).toList();
                final hist = all.where((p) => !(p['status'] == 'pending' && p['expired'] != true)).toList();
                final safe = ((d['catalog'] ?? []) as List).cast<Map>().where((a) => a['level'] == 2).toList();
                return ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 28), children: [
                  if (pend.isEmpty) const Section('Laukia patvirtinimo', child: Empty('Nieko nelaukia', icon: Icons.task_alt_rounded)),
                  for (final p in pend) ...[_card(p, true), const SizedBox(height: 12)],
                  if (Api.i.canManage) ...[
                    const SizedBox(height: 12),
                    Section('Saugūs veiksmai', child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      const Text('Vykdomi iš karto ir nieko nekeičia. Rizikingi veiksmai – tik per pasiūlymą su 2FA.', style: TextStyle(color: C.muted, fontSize: 12.5)),
                      const SizedBox(height: 10),
                      for (final a in safe)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: OutlinedButton.icon(
                            onPressed: _running != null ? null : () => _run(a),
                            icon: _running == a['id'] ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.play_arrow_rounded),
                            label: Text('${a['title']}'),
                            style: OutlinedButton.styleFrom(alignment: Alignment.centerLeft),
                          ),
                        ),
                    ])),
                  ],
                  const SizedBox(height: 12),
                  Section('Istorija', padding: const EdgeInsets.fromLTRB(6, 14, 6, 8), child: Column(children: [
                    if (hist.isEmpty) const Empty('Istorija tuščia'),
                    for (final p in hist.take(30))
                      ExpansionTile(
                        tilePadding: const EdgeInsets.symmetric(horizontal: 10),
                        shape: const Border(),
                        title: Text('#${p['id']} ${p['title']}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                        subtitle: Padding(padding: const EdgeInsets.only(top: 4), child: Row(children: [Pill(stLabel[p['expired'] == true && p['status'] == 'pending' ? 'expired' : p['status']] ?? '${p['status']}', stColor(p['status'])), const SizedBox(width: 8), Text(when(p['created_at']), style: const TextStyle(color: C.muted, fontSize: 12))])),
                        children: [Padding(padding: const EdgeInsets.fromLTRB(10, 0, 10, 12), child: _details(p))],
                      ),
                  ])),
                ]);
              }),
            ),
    );
  }

  Widget _card(Map p, bool pending) => Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: BorderSide(color: C.warn.withAlpha(110))),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [const Pill('Laukia patvirtinimo', C.warn), const Spacer(), Text(p['source'] == 'ai' ? 'Pasiūlė AI' : 'Pasiūlė ${p['creator'] ?? 'admin'}', style: const TextStyle(color: C.muted, fontSize: 12))]),
            const SizedBox(height: 10),
            Text('${p['title']}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            _details(p),
            const SizedBox(height: 14),
            if (Api.i.canApprove)
              Row(children: [
                Expanded(child: OutlinedButton(onPressed: () => _decide(p, false), child: const Text('Atmesti'))),
                const SizedBox(width: 10),
                Expanded(child: FilledButton.icon(onPressed: () => _decide(p, true), icon: const Icon(Icons.verified_user_rounded), label: const Text('Patvirtinti'))),
              ])
            else
              const Text('Patvirtinti gali tik narys su teise „cgi.approve“.', style: TextStyle(color: C.muted)),
          ]),
        ),
      );

  Widget _details(Map p) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        for (final k in const [('why', 'Kodėl'), ('affected', 'Kas paveikiama'), ('risk', 'Rizika'), ('verify', 'Kaip patikrinsime'), ('rollback', 'Kaip atšaukti'), ('result', 'Rezultatas')])
          if ('${p[k.$1] ?? ''}'.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(k.$2, style: const TextStyle(color: C.muted, fontSize: 12, fontWeight: FontWeight.w600)), const SizedBox(height: 2), Text('${p[k.$1]}', style: const TextStyle(height: 1.4))]),
            ),
        if (p['decided_name'] != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text('Sprendė ${p['decided_name']} · ${when(p['decided_at'])}', style: const TextStyle(color: C.muted, fontSize: 12))),
      ]);
}
