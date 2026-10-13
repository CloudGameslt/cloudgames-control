import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../api.dart';
import '../push.dart';
import '../theme.dart';
import '../widgets.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsState();
}

class _SettingsState extends State<SettingsScreen> {
  List<Map<String, dynamic>> _cats = [];
  List<Map<String, dynamic>> _devs = [];
  Map<String, dynamic>? _rel;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final r = await Future.wait([Api.i.get('/app/prefs'), Api.i.get('/app/release')]);
      if (!mounted) return;
      setState(() {
        _cats = ((r[0]['categories'] ?? []) as List).map((e) => Map<String, dynamic>.from(e)).toList();
        _rel = Map<String, dynamic>.from(r[1]);
        _devs = ((r[1]['devices'] ?? []) as List).map((e) => Map<String, dynamic>.from(e)).toList();
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggle(Map<String, dynamic> c, bool v) async {
    setState(() => c['on'] = v);
    try {
      await Api.i.put('/app/prefs', {'prefs': {c['id']: v}});
    } catch (e) {
      if (mounted) { setState(() => c['on'] = !v); toast(context, '$e'); }
    }
  }

  Future<void> _master(bool v) async {
    if (v) {
      await Push.init();
    } else {
      await Push.disable();
    }
    if (mounted) setState(() {});
  }

  Future<void> _revoke(Map d) async {
    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(title: const Text('Atjungti įrenginį?'), content: Text('„${d['name']}“ bus atjungtas ir nebegaus pranešimų.'), actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Ne')), FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Atjungti'))]));
    if (ok != true) return;
    try {
      await Api.i.del('/app/devices/${d['id']}');
      if (d['current'] == true) { await Api.i.clear(); return; }
      _load();
    } catch (e) {
      if (mounted) toast(context, '$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final roles = ((Api.i.user['roles'] ?? []) as List).join(', ');
    final a = _rel?['android'];
    return Scaffold(
      appBar: AppBar(title: const Text('Nustatymai')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              color: C.accent,
              onRefresh: _load,
              child: ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 32), children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(children: [
                      CircleAvatar(radius: 26, backgroundColor: C.accent.withAlpha(50), child: Text(Api.i.username.isEmpty ? '?' : Api.i.username[0].toUpperCase(), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: C.accent))),
                      const SizedBox(width: 14),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(Api.i.username, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)), Text(roles, style: const TextStyle(color: C.muted))])),
                    ]),
                  ),
                ),
                const SizedBox(height: 12),
                Section('Pranešimai', child: ValueListenableBuilder<String>(
                  valueListenable: Push.status,
                  builder: (_, st, __) => Column(children: [
                    SwitchListTile(contentPadding: EdgeInsets.zero, value: Push.enabled, onChanged: _master, title: const Text('Gauti pranešimus šiame telefone', style: TextStyle(fontWeight: FontWeight.w600)), subtitle: Text(st, style: const TextStyle(color: C.muted, fontSize: 12.5))),
                    const Divider(),
                    for (final c in _cats) SwitchListTile(contentPadding: EdgeInsets.zero, dense: true, value: c['on'] == true, onChanged: Push.enabled ? (v) => _toggle(c, v) : null, title: Text('${c['label']}')),
                    if (Push.enabled)
                      Align(alignment: Alignment.centerLeft, child: TextButton.icon(onPressed: () async { try { final r = await Api.i.post('/app/test-push'); if (mounted) toast(context, 'Išsiųsta: ${r['sent']}/${r['total']}'); } catch (e) { if (mounted) toast(context, '$e'); } }, icon: const Icon(Icons.send_rounded, size: 18), label: const Text('Siųsti bandomąjį pranešimą'))),
                  ]),
                )),
                const SizedBox(height: 12),
                Section('Prijungti įrenginiai', child: Column(children: [
                  for (final d in _devs)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(d['platform'] == 'ios' ? Icons.phone_iphone_rounded : Icons.phone_android_rounded, color: d['current'] == true ? C.accent : C.muted),
                      title: Text('${d['name']}${d['current'] == true ? ' (šis)' : ''}'),
                      subtitle: Text('Aktyvus ${ago(d['lastSeen'])}${d['push'] == true ? ' · pranešimai' : ''}', style: const TextStyle(color: C.muted, fontSize: 12)),
                      trailing: IconButton(onPressed: () => _revoke(d), icon: const Icon(Icons.link_off_rounded, color: C.bad)),
                    ),
                ])),
                const SizedBox(height: 12),
                Section('Programėlė', child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Versija $kVersion ($kBuild)', style: const TextStyle(fontWeight: FontWeight.w600)),
                  if (a is Map && (a['build'] ?? 0) is num && (a['build'] as num) > kBuild)
                    Padding(padding: const EdgeInsets.only(top: 10), child: FilledButton.icon(onPressed: () => launchUrl(Uri.parse('$kBase${a['url']}'), mode: LaunchMode.externalApplication), icon: const Icon(Icons.system_update_rounded), label: Text('Atnaujinti į ${a['version']} (${a['build']})')))
                  else
                    const Padding(padding: EdgeInsets.only(top: 4), child: Text('Naudoji naujausią versiją', style: TextStyle(color: C.muted))),
                ])),
                const SizedBox(height: 20),
                OutlinedButton.icon(
                  onPressed: () async { await Push.disable(); await Api.i.logout(); },
                  icon: const Icon(Icons.logout_rounded, color: C.bad),
                  label: const Text('Atsijungti', style: TextStyle(color: C.bad)),
                  style: OutlinedButton.styleFrom(side: BorderSide(color: C.bad.withAlpha(110))),
                ),
              ]),
            ),
    );
  }
}
