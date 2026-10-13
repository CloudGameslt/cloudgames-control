import 'package:flutter/material.dart';

import '../api.dart';
import '../theme.dart';
import '../widgets.dart';

const catIcon = {'users': Icons.person_add_alt_1_rounded, 'orders': Icons.shopping_bag_rounded, 'support': Icons.support_agent_rounded, 'down': Icons.cloud_off_rounded, 'error': Icons.bug_report_rounded, 'security': Icons.shield_rounded, 'approval': Icons.lock_clock_rounded, 'anticheat': Icons.gpp_maybe_rounded, 'load': Icons.speed_rounded, 'deploy': Icons.rocket_launch_rounded};

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});
  @override
  State<FeedScreen> createState() => _FeedState();
}

class _FeedState extends State<FeedScreen> {
  List<Map<String, dynamic>>? _l;
  Object? _err;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final d = await Api.i.get('/app/feed');
      if (mounted) setState(() { _l = (d as List).map((e) => Map<String, dynamic>.from(e)).toList(); _err = null; });
    } catch (e) {
      if (mounted) setState(() => _err = e);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Pranešimai')),
        body: _l == null
            ? (_err != null ? ErrorBox(_err!, _load) : const Center(child: CircularProgressIndicator()))
            : RefreshIndicator(
                color: C.accent,
                onRefresh: _load,
                child: _l!.isEmpty
                    ? ListView(children: const [SizedBox(height: 80), Empty('Pranešimų dar nėra', icon: Icons.notifications_none_rounded)])
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(12, 6, 12, 24),
                        itemCount: _l!.length,
                        separatorBuilder: (_, __) => const Divider(indent: 58),
                        itemBuilder: (_, i) {
                          final f = _l![i], c = sevColor(f['severity']);
                          return ListTile(
                            leading: Container(width: 40, height: 40, decoration: BoxDecoration(color: (f['severity'] == 'info' ? C.accent : c).withAlpha(36), borderRadius: BorderRadius.circular(12)), child: Icon(catIcon[f['category']] ?? Icons.notifications_rounded, color: f['severity'] == 'info' ? C.accent : c, size: 21)),
                            title: Text('${f['title']}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5)),
                            subtitle: Text([if ('${f['body'] ?? ''}'.isNotEmpty) '${f['body']}', ago(f['at'])].join('\n'), style: const TextStyle(color: C.muted, fontSize: 12.5)),
                            isThreeLine: '${f['body'] ?? ''}'.isNotEmpty,
                          );
                        },
                      ),
              ),
      );
}
