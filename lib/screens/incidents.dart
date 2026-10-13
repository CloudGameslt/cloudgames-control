import 'dart:convert';

import 'package:flutter/material.dart';

import '../api.dart';
import '../theme.dart';
import '../widgets.dart';

class IncidentTile extends StatelessWidget {
  final Map<String, dynamic> x;
  final VoidCallback? onBack;
  const IncidentTile(this.x, {super.key, this.onBack});
  @override
  Widget build(BuildContext context) => InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (_) => IncidentScreen(x['id'] as int)));
          onBack?.call();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Padding(padding: const EdgeInsets.only(top: 5), child: Dot(sevColor(x['severity']))),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${x['title']}', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5)),
                const SizedBox(height: 5),
                Wrap(spacing: 6, runSpacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: [
                  Pill(stLabel[x['status']] ?? '${x['status']}', stColor(x['status'])),
                  Text('#${x['id']} · ${ago(x['last_at'])} · ${x['count']}×${x['analyzed_at'] != null ? ' · AI' : ''}', style: const TextStyle(color: C.muted, fontSize: 12)),
                ]),
              ]),
            ),
            const Icon(Icons.chevron_right_rounded, color: C.muted),
          ]),
        ),
      );
}

class IncidentsScreen extends StatefulWidget {
  const IncidentsScreen({super.key});
  @override
  State<IncidentsScreen> createState() => _IncidentsState();
}

class _IncidentsState extends State<IncidentsScreen> {
  String _f = 'open';
  List<Map<String, dynamic>>? _l;
  Object? _err;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final d = await Api.i.get('/cgi/incidents${_f == 'all' ? '' : '?status=$_f'}');
      if (mounted) setState(() { _l = (d as List).map((e) => Map<String, dynamic>.from(e)).toList(); _err = null; });
    } catch (e) {
      if (mounted) setState(() => _err = e);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Incidentai')),
        body: Column(children: [
          SizedBox(
            height: 48,
            child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 16), children: [
              for (final f in const [('open', 'Atviri'), ('resolved', 'Išspręsti'), ('dismissed', 'Atmesti'), ('all', 'Visi')])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(f.$2),
                    selected: _f == f.$1,
                    onSelected: (_) { setState(() { _f = f.$1; _l = null; }); _load(); },
                    selectedColor: C.accent.withAlpha(50),
                    backgroundColor: C.card,
                    side: BorderSide(color: _f == f.$1 ? C.accent : C.line),
                    showCheckmark: false,
                  ),
                ),
            ]),
          ),
          Expanded(
            child: _l == null
                ? (_err != null ? ErrorBox(_err!, _load) : const Center(child: CircularProgressIndicator()))
                : RefreshIndicator(
                    color: C.accent,
                    onRefresh: _load,
                    child: _l!.isEmpty
                        ? ListView(children: const [SizedBox(height: 80), Empty('Incidentų nėra', icon: Icons.verified_outlined)])
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(10, 6, 10, 24),
                            itemCount: _l!.length,
                            separatorBuilder: (_, __) => const Divider(indent: 30),
                            itemBuilder: (_, i) => IncidentTile(_l![i], onBack: _load),
                          ),
                  ),
          ),
        ]),
      );
}

class IncidentScreen extends StatefulWidget {
  final int id;
  const IncidentScreen(this.id, {super.key});
  @override
  State<IncidentScreen> createState() => _IncidentState();
}

class _IncidentState extends State<IncidentScreen> {
  Map<String, dynamic>? _x;
  Object? _err;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final d = await Api.i.get('/cgi/incidents/${widget.id}');
      if (mounted) setState(() { _x = Map<String, dynamic>.from(d); _err = null; });
    } catch (e) {
      if (mounted) setState(() => _err = e);
    }
  }

  Future<void> _analyze() async {
    setState(() => _busy = true);
    try {
      final d = await Api.i.post('/cgi/incidents/${widget.id}/analyze');
      if (mounted) setState(() => _x = {..._x!, ...Map<String, dynamic>.from(d)});
    } catch (e) {
      if (mounted) toast(context, '$e');
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _status() async {
    final note = TextEditingController();
    final st = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + MediaQuery.of(ctx).viewInsets.bottom),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Text('Keisti būseną', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 14),
          TextField(controller: note, maxLines: 3, decoration: const InputDecoration(hintText: 'Pastaba (neprivaloma)')),
          const SizedBox(height: 14),
          for (final s in const [('resolved', 'Išspręstas', C.ok), ('analyzing', 'Analizuojamas', C.warn), ('dismissed', 'Atmestas', C.muted), ('new', 'Naujas', C.bad)])
            if (s.$1 != _x!['status'])
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: OutlinedButton.icon(onPressed: () => Navigator.pop(ctx, s.$1), icon: Dot(s.$3), label: Text(s.$2), style: OutlinedButton.styleFrom(alignment: Alignment.centerLeft)),
              ),
          TextButton(onPressed: () => Navigator.pop(ctx, ''), child: const Text('Išsaugoti tik pastabą')),
        ]),
      ),
    );
    if (st == null) return;
    try {
      await Api.i.post('/cgi/incidents/${widget.id}', {'status': st.isEmpty ? null : st, 'note': note.text});
      await _load();
      if (mounted) toast(context, 'Išsaugota');
    } catch (e) {
      if (mounted) toast(context, '$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final x = _x;
    return Scaffold(
      appBar: AppBar(title: Text('Incidentas #${widget.id}'), actions: [if (x != null) IconButton(onPressed: _status, icon: const Icon(Icons.edit_note_rounded))]),
      body: x == null
          ? (_err != null ? ErrorBox(_err!, _load) : const Center(child: CircularProgressIndicator()))
          : RefreshIndicator(
              color: C.accent,
              onRefresh: _load,
              child: ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 32), children: [
                Wrap(spacing: 8, children: [Pill(sevLabel[x['severity']] ?? '${x['severity']}', sevColor(x['severity'])), Pill(stLabel[x['status']] ?? '${x['status']}', stColor(x['status'])), Pill('${x['kind']}', C.muted)]),
                const SizedBox(height: 12),
                Text('${x['title']}', style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800, height: 1.25)),
                const SizedBox(height: 6),
                Text('Pirmą kartą ${when(x['first_at'])} · paskutinį ${when(x['last_at'])} · ${x['count']}×', style: const TextStyle(color: C.muted, fontSize: 12.5)),
                if (x['evidence']?['summary'] != null) ...[
                  const SizedBox(height: 14),
                  Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: C.bg2, borderRadius: BorderRadius.circular(14), border: Border.all(color: C.line)), child: Text('${x['evidence']['summary']}', style: const TextStyle(color: C.text2, height: 1.45))),
                ],
                const SizedBox(height: 16),
                _analysis(x['analysis']),
                const SizedBox(height: 12),
                if (((x['proposals'] ?? []) as List).isNotEmpty) ...[
                  Section('Pasiūlyti veiksmai', child: Column(children: [for (final p in (x['proposals'] as List)) ListTile(contentPadding: EdgeInsets.zero, title: Text('#${p['id']} ${p['title']}'), trailing: Pill(stLabel[p['status']] ?? '${p['status']}', stColor(p['status'])))])),
                  const SizedBox(height: 12),
                ],
                Section('Įrodymai', child: SelectableText(const JsonEncoder.withIndent('  ').convert(x['evidence'] ?? {}), style: const TextStyle(fontFamily: 'monospace', fontSize: 12, color: C.text2))),
                const SizedBox(height: 12),
                Section('Istorija', child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  if (((x['notes'] ?? []) as List).isEmpty) const Text('Pastabų nėra', style: TextStyle(color: C.muted)),
                  for (final n in ((x['notes'] ?? []) as List))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('${when(n['at'])} · ${n['by']}${n['status'] != null ? ' → ${stLabel[n['status']] ?? n['status']}' : ''}', style: const TextStyle(color: C.muted, fontSize: 12)),
                        if ('${n['text'] ?? ''}'.isNotEmpty) Text('${n['text']}'),
                      ]),
                    ),
                ])),
              ]),
            ),
    );
  }

  Widget _analysis(dynamic a) {
    return Section(
      'CGIntelligent analizė',
      trailing: _busy ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : null,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (a == null) const Text('Analizės dar nėra. AI patikrins kodą, metrikas ir žurnalus.', style: TextStyle(color: C.muted)),
        if (a is Map) ...[
          if (a['summary'] != null) Text('${a['summary']}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, height: 1.4)),
          for (final k in const [('cause', 'Tikėtina priežastis'), ('confidence', 'Pasitikėjimas'), ('impact', 'Poveikis'), ('risk', 'Rizika'), ('where', 'Kur'), ('when', 'Kada')])
            if (a[k.$1] != null && '${a[k.$1]}'.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(k.$2, style: const TextStyle(color: C.muted, fontSize: 12, fontWeight: FontWeight.w600)), const SizedBox(height: 2), Text('${a[k.$1]}', style: const TextStyle(height: 1.4))]),
              ),
          for (final k in const [('plan', 'Taisymo planas'), ('verify', 'Kaip patikrinti'), ('missing', 'Trūksta duomenų')])
            if (a[k.$1] is List && (a[k.$1] as List).isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(k.$2, style: const TextStyle(color: C.muted, fontSize: 12, fontWeight: FontWeight.w600)),
                  for (final (i, p) in (a[k.$1] as List).indexed) Padding(padding: const EdgeInsets.only(top: 4), child: Text('${i + 1}. $p', style: const TextStyle(height: 1.4))),
                ]),
              ),
          if (a['sources'] is List && (a['sources'] as List).isNotEmpty)
            Padding(padding: const EdgeInsets.only(top: 12), child: Wrap(spacing: 6, runSpacing: 6, children: [for (final s in (a['sources'] as List).take(10)) Pill('$s', C.blue)])),
          Padding(padding: const EdgeInsets.only(top: 10), child: Text('${a['model'] ?? ''} · ${when(a['at'])}', style: const TextStyle(color: C.muted, fontSize: 11.5))),
        ],
        const SizedBox(height: 14),
        FilledButton.icon(onPressed: _busy ? null : _analyze, icon: const Icon(Icons.auto_awesome), label: Text(_busy ? 'Analizuojama…' : a == null ? 'Analizuoti su AI' : 'Analizuoti iš naujo')),
      ]),
    );
  }
}
