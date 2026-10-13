import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../api.dart';
import '../theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginState();
}

class _LoginState extends State<LoginScreen> {
  final _email = TextEditingController(), _pw = TextEditingController(), _code = TextEditingController();
  String? _ticket, _err;
  bool _busy = false, _hide = true;

  Future<void> _go() async {
    if (_busy) return;
    setState(() { _busy = true; _err = null; });
    try {
      if (_ticket == null) {
        if (_email.text.trim().isEmpty || _pw.text.isEmpty) throw ApiError('Įvesk el. paštą ir slaptažodį');
        final t = await Api.i.login(_email.text, _pw.text);
        if (t != null && mounted) setState(() => _ticket = t);
      } else {
        if (_code.text.trim().length < 6) throw ApiError('Įvesk 6 skaitmenų kodą');
        await Api.i.login2fa(_ticket!, _code.text);
      }
    } on ApiError catch (e) {
      if (e.status == 401 && _ticket != null && e.message.contains('laikas')) _ticket = null;
      _err = e.message;
    } catch (_) {
      _err = 'Nepavyko prisijungti';
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final two = _ticket != null;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: RadialGradient(center: Alignment(0.7, -1.1), radius: 1.3, colors: [Color(0x55FF6B1F), C.bg], stops: [0, 0.75])),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Center(child: Image.asset('assets/logo.png', height: 96)),
                  const SizedBox(height: 18),
                  const Text('CloudGames Control', textAlign: TextAlign.center, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                  const SizedBox(height: 6),
                  Text(two ? 'Įvesk kodą iš autentifikavimo programėlės' : 'Prisijunk su savo CloudGames paskyra', textAlign: TextAlign.center, style: const TextStyle(color: C.muted)),
                  const SizedBox(height: 28),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: two
                        ? TextField(
                            key: const ValueKey('code'),
                            controller: _code,
                            autofocus: true,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            maxLength: 9,
                            autofillHints: const [AutofillHints.oneTimeCode],
                            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9A-Za-z-]'))],
                            style: const TextStyle(fontSize: 30, letterSpacing: 10, fontWeight: FontWeight.w800),
                            decoration: const InputDecoration(counterText: '', hintText: '000000'),
                            onChanged: (v) { if (RegExp(r'^\d{6}$').hasMatch(v)) _go(); },
                            onSubmitted: (_) => _go(),
                          )
                        : AutofillGroup(
                            key: const ValueKey('pw'),
                            child: Column(children: [
                              TextField(controller: _email, keyboardType: TextInputType.emailAddress, autofillHints: const [AutofillHints.email], textInputAction: TextInputAction.next, decoration: const InputDecoration(labelText: 'El. paštas', prefixIcon: Icon(Icons.alternate_email_rounded))),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _pw,
                                obscureText: _hide,
                                autofillHints: const [AutofillHints.password],
                                onSubmitted: (_) => _go(),
                                decoration: InputDecoration(labelText: 'Slaptažodis', prefixIcon: const Icon(Icons.lock_outline_rounded), suffixIcon: IconButton(onPressed: () => setState(() => _hide = !_hide), icon: Icon(_hide ? Icons.visibility_outlined : Icons.visibility_off_outlined))),
                              ),
                            ]),
                          ),
                  ),
                  if (_err != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: C.bad.withAlpha(28), borderRadius: BorderRadius.circular(12), border: Border.all(color: C.bad.withAlpha(80))),
                      child: Row(children: [const Icon(Icons.error_outline_rounded, color: C.bad, size: 20), const SizedBox(width: 10), Expanded(child: Text(_err!, style: const TextStyle(color: C.text)))]),
                    ),
                  ],
                  const SizedBox(height: 20),
                  FilledButton(onPressed: _busy ? null : _go, child: _busy ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white)) : Text(two ? 'Patvirtinti' : 'Prisijungti')),
                  if (two) TextButton(onPressed: () => setState(() { _ticket = null; _code.clear(); _err = null; }), child: const Text('Grįžti')),
                  const SizedBox(height: 26),
                  const Text('Programėlė skirta CloudGames administracijai. Reikalinga įjungta 2FA apsauga.', textAlign: TextAlign.center, style: TextStyle(color: C.muted, fontSize: 12)),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
