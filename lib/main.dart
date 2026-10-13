import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'api.dart';
import 'push.dart';
import 'screens/login.dart';
import 'screens/shell.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(statusBarColor: Colors.transparent, statusBarIconBrightness: Brightness.light, systemNavigationBarColor: C.bg2));
  await Api.i.load();
  runApp(const CgApp());
}

class CgApp extends StatelessWidget {
  const CgApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'CloudGames Control',
        debugShowCheckedModeBanner: false,
        theme: cgTheme(),
        scaffoldMessengerKey: messengerKey,
        home: ValueListenableBuilder<bool>(
          valueListenable: Api.i.authed,
          builder: (_, ok, __) => AnimatedSwitcher(duration: const Duration(milliseconds: 350), child: ok ? const Shell(key: ValueKey('shell')) : const LoginScreen(key: ValueKey('login'))),
        ),
      );
}
