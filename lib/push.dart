import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import 'api.dart';
import 'theme.dart';

final messengerKey = GlobalKey<ScaffoldMessengerState>();

class Push {
  static final status = ValueNotifier<String>('Tikrinama…');
  static bool enabled = false;
  static StreamSubscription? _a, _b;

  static Future<void> init() async {
    try {
      final c = await Api.i.publicGet('/app/config');
      final f = c is Map ? c['fcm'] : null;
      if (f == null) {
        status.value = 'Serveryje dar neįjungti (Firebase)';
        return;
      }
      if (Firebase.apps.isEmpty) {
        final ios = Platform.isIOS && '${f['appIdIos'] ?? ''}'.isNotEmpty;
        await Firebase.initializeApp(options: FirebaseOptions(apiKey: '${f['apiKey']}', appId: ios ? '${f['appIdIos']}' : '${f['appId']}', messagingSenderId: '${f['senderId']}', projectId: '${f['projectId']}'));
      }
      final m = FirebaseMessaging.instance;
      final s = await m.requestPermission(alert: true, badge: true, sound: true);
      if (s.authorizationStatus == AuthorizationStatus.denied) {
        enabled = false;
        status.value = 'Išjungti telefono nustatymuose';
        await Api.i.post('/app/push', {'token': ''});
        return;
      }
      final t = await m.getToken();
      if (t != null) await Api.i.post('/app/push', {'token': t});
      await _a?.cancel();
      await _b?.cancel();
      _a = m.onTokenRefresh.listen((t) => Api.i.post('/app/push', {'token': t}).catchError((_) => null));
      _b = FirebaseMessaging.onMessage.listen((msg) {
        final n = msg.notification;
        if (n == null) return;
        messengerKey.currentState?.showSnackBar(SnackBar(
          duration: const Duration(seconds: 5),
          content: Row(children: [
            const Icon(Icons.notifications_active_rounded, color: C.accent),
            const SizedBox(width: 12),
            Expanded(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(n.title ?? '', style: const TextStyle(fontWeight: FontWeight.w700)),
              if ((n.body ?? '').isNotEmpty) Text(n.body!, style: const TextStyle(color: C.text2, fontSize: 13)),
            ])),
          ]),
        ));
      });
      enabled = true;
      status.value = 'Įjungti';
    } catch (e) {
      status.value = 'Nepavyko įjungti: $e';
    }
  }

  static Future<void> disable() async {
    try {
      await Api.i.post('/app/push', {'token': ''});
      if (Firebase.apps.isNotEmpty) await FirebaseMessaging.instance.deleteToken();
    } catch (_) {}
    enabled = false;
    status.value = 'Išjungti šiame telefone';
  }
}
