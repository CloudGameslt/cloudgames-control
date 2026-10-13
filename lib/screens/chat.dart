import 'package:flutter/material.dart';

import '../api.dart';
import '../theme.dart';
import '../widgets.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});
  @override
  State<ChatScreen> createState() => _ChatState();
}

class _ChatState extends State<ChatScreen> {
  final _q = TextEditingController(), _sc = ScrollController();
  final List<Map<String, dynamic>> _msgs = [];
  int? _conv;
  bool _busy = false;

  void _down() => WidgetsBinding.instance.addPostFrameCallback((_) { if (_sc.hasClients) _sc.animateTo(_sc.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut); });

  Future<void> _send([String? preset]) async {
    final t = (preset ?? _q.text).trim();
    if (t.isEmpty || _busy) return;
    _q.clear();
    setState(() { _msgs.add({'role': 'user', 'shown': t}); _busy = true; });
    _down();
    try {
      final d = await Api.i.post('/cgi/chat', {'conv': _conv, 'text': t});
      _conv = d['conv'] as int?;
      _msgs.add({'role': 'assistant', 'shown': d['answer'], 'meta': {'sources': d['sources'], 'proposals': d['proposals'], 'model': d['model'], 'usage': d['usage'], 'calls': d['calls']}});
    } catch (e) {
      _msgs.add({'role': 'assistant', 'error': '$e'});
    }
    if (mounted) setState(() => _busy = false);
    _down();
  }

  Future<void> _history() async {
    try {
      final L = (await Api.i.get('/cgi/convs') as List).cast<Map>();
      if (!mounted) return;
      final id = await showModalBottomSheet<int>(
        context: context,
        builder: (ctx) => SafeArea(
          child: ListView(shrinkWrap: true, padding: const EdgeInsets.only(bottom: 16), children: [
            const Padding(padding: EdgeInsets.fromLTRB(20, 0, 20, 8), child: Text('Pokalbiai', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800))),
            if (L.isEmpty) const Empty('Pokalbių dar nėra'),
            for (final c in L) ListTile(leading: const Icon(Icons.chat_bubble_outline_rounded, color: C.muted), title: Text('${c['title']}', maxLines: 1, overflow: TextOverflow.ellipsis), subtitle: Text(ago(c['updated_at']), style: const TextStyle(color: C.muted)), onTap: () => Navigator.pop(ctx, c['id'] as int)),
          ]),
        ),
      );
      if (id == null) return;
      final c = await Api.i.get('/cgi/convs/$id');
      setState(() {
        _conv = id;
        _msgs..clear()..addAll(((c['messages'] ?? []) as List).map((m) => Map<String, dynamic>.from(m)));
      });
      _down();
    } catch (e) {
      if (mounted) toast(context, '$e');
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Row(children: [Icon(Icons.auto_awesome, color: C.violet), SizedBox(width: 10), Text('CGIntelligent')]),
          actions: [
            IconButton(tooltip: 'Pokalbiai', onPressed: _history, icon: const Icon(Icons.history_rounded)),
            IconButton(tooltip: 'Naujas pokalbis', onPressed: () => setState(() { _conv = null; _msgs.clear(); }), icon: const Icon(Icons.add_comment_outlined)),
          ],
        ),
        body: Column(children: [
          Expanded(
            child: _msgs.isEmpty
                ? ListView(padding: const EdgeInsets.all(24), children: [
                    const SizedBox(height: 30),
                    Center(child: Container(width: 74, height: 74, decoration: BoxDecoration(shape: BoxShape.circle, gradient: const LinearGradient(colors: [C.violet, C.accent]), boxShadow: [BoxShadow(color: C.violet.withAlpha(80), blurRadius: 30)]), child: const Icon(Icons.auto_awesome, color: Colors.white, size: 34))),
                    const SizedBox(height: 18),
                    const Text('Klausk apie CloudGames', textAlign: TextAlign.center, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    const Text('Atsakymai remiasi projekto kodu, metrikomis ir žurnalais – su šaltiniais.', textAlign: TextAlign.center, style: TextStyle(color: C.muted)),
                    const SizedBox(height: 22),
                    Wrap(alignment: WrapAlignment.center, spacing: 8, runSpacing: 8, children: [
                      for (final q in const ['Kokia dabar serverio būklė?', 'Kokios naujausios klaidos?', 'Ar yra saugumo problemų?', 'Kaip veikia 2FA prisijungimas?'])
                        ActionChip(label: Text(q), onPressed: () => _send(q), backgroundColor: C.card, side: const BorderSide(color: C.line)),
                    ]),
                  ])
                : ListView.builder(
                    controller: _sc,
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                    itemCount: _msgs.length + (_busy ? 1 : 0),
                    itemBuilder: (_, i) => i == _msgs.length ? const _Typing() : _Bubble(_msgs[i]),
                  ),
          ),
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
              decoration: const BoxDecoration(color: C.bg2, border: Border(top: BorderSide(color: C.line))),
              child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Expanded(child: TextField(controller: _q, minLines: 1, maxLines: 5, textCapitalization: TextCapitalization.sentences, decoration: const InputDecoration(hintText: 'Klausk CGIntelligent…', contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12)))),
                const SizedBox(width: 8),
                IconButton.filled(onPressed: _busy ? null : () => _send(), style: IconButton.styleFrom(backgroundColor: C.accent, minimumSize: const Size(48, 48)), icon: const Icon(Icons.arrow_upward_rounded, color: Colors.white)),
              ]),
            ),
          ),
        ]),
      );
}

class _Bubble extends StatelessWidget {
  final Map<String, dynamic> m;
  const _Bubble(this.m);
  @override
  Widget build(BuildContext context) {
    final me = m['role'] == 'user';
    final meta = (m['meta'] ?? {}) as Map;
    return Align(
      alignment: me ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * (me ? 0.8 : 0.92)),
        padding: const EdgeInsets.fromLTRB(14, 11, 14, 11),
        decoration: BoxDecoration(
          color: me ? C.accent.withAlpha(40) : C.card,
          borderRadius: BorderRadius.only(topLeft: const Radius.circular(18), topRight: const Radius.circular(18), bottomLeft: Radius.circular(me ? 18 : 5), bottomRight: Radius.circular(me ? 5 : 18)),
          border: Border.all(color: me ? C.accent.withAlpha(90) : C.line),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (m['error'] != null) Text('${m['error']}', style: const TextStyle(color: C.bad)) else if (me) Text('${m['shown']}', style: const TextStyle(fontSize: 14.5, height: 1.4)) else Md('${m['shown'] ?? ''}'),
          if ((meta['proposals'] ?? []) is List && (meta['proposals'] as List).isNotEmpty)
            for (final p in (meta['proposals'] as List))
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: C.warn.withAlpha(25), borderRadius: BorderRadius.circular(10), border: Border.all(color: C.warn.withAlpha(90))),
                child: Row(children: [const Icon(Icons.lock_clock_rounded, color: C.warn, size: 18), const SizedBox(width: 8), Expanded(child: Text('Pasiūlymas #${p is Map ? p['id'] : p} laukia patvirtinimo skiltyje „Veiksmai“', style: const TextStyle(fontSize: 13)))]),
              ),
          if ((meta['sources'] ?? []) is List && (meta['sources'] as List).isNotEmpty)
            Padding(padding: const EdgeInsets.only(top: 8), child: Wrap(spacing: 5, runSpacing: 5, children: [for (final s in (meta['sources'] as List).take(8)) Pill('$s', C.blue)])),
          if (meta['model'] != null)
            Padding(padding: const EdgeInsets.only(top: 6), child: Text('${meta['model']}${meta['usage'] is Map ? ' · ${num0(meta['usage']['input'])}/${num0(meta['usage']['output'])} tok.' : ''}', style: const TextStyle(color: C.muted, fontSize: 11))),
        ]),
      ),
    );
  }
}

class _Typing extends StatelessWidget {
  const _Typing();
  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 5),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(18), border: Border.all(color: C.line)),
          child: const Row(mainAxisSize: MainAxisSize.min, children: [SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: C.violet)), SizedBox(width: 10), Text('Tikrinu duomenis…', style: TextStyle(color: C.muted))]),
        ),
      );
}
