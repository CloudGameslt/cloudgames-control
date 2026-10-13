import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../api.dart';
import '../push.dart';
import '../theme.dart';
import 'actions.dart';
import 'chat.dart';
import 'incidents.dart';
import 'settings.dart';
import 'status.dart';

class Shell extends StatefulWidget {
  const Shell({super.key});
  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int _i = 0;
  Map<String, dynamic>? _update;

  @override
  void initState() {
    super.initState();
    Push.init();
    _checkUpdate();
  }

  Future<void> _checkUpdate() async {
    try {
      final d = await Api.i.get('/app/release');
      final a = d['android'];
      if (a is Map && (a['build'] ?? 0) is num && (a['build'] as num) > kBuild && mounted) setState(() => _update = Map<String, dynamic>.from(a));
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final pages = [const StatusScreen(), const IncidentsScreen(), const ChatScreen(), const ActionsScreen(), const SettingsScreen()];
    return Scaffold(
      body: Column(children: [
        if (_update != null)
          Material(
            color: C.accent.withAlpha(36),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                child: Row(children: [
                  const Icon(Icons.system_update_rounded, color: C.accent),
                  const SizedBox(width: 10),
                  Expanded(child: Text('Nauja versija ${_update!['version']} (${_update!['build']})', style: const TextStyle(fontWeight: FontWeight.w600))),
                  TextButton(onPressed: () => launchUrl(Uri.parse('$kBase${_update!['url']}'), mode: LaunchMode.externalApplication), child: const Text('Atnaujinti')),
                ]),
              ),
            ),
          ),
        Expanded(child: IndexedStack(index: _i, children: pages)),
      ]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _i,
        onDestinationSelected: (i) => setState(() => _i = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.speed_outlined), selectedIcon: Icon(Icons.speed_rounded), label: 'Būklė'),
          NavigationDestination(icon: Icon(Icons.report_gmailerrorred_outlined), selectedIcon: Icon(Icons.report_rounded), label: 'Incidentai'),
          NavigationDestination(icon: Icon(Icons.auto_awesome_outlined), selectedIcon: Icon(Icons.auto_awesome), label: 'AI'),
          NavigationDestination(icon: Icon(Icons.task_alt_outlined), selectedIcon: Icon(Icons.task_alt_rounded), label: 'Veiksmai'),
          NavigationDestination(icon: Icon(Icons.tune_outlined), selectedIcon: Icon(Icons.tune_rounded), label: 'Nustatymai'),
        ],
      ),
    );
  }
}
