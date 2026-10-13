import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

const kBase = String.fromEnvironment('API', defaultValue: 'https://cloudgames.lt');
const kBuild = int.fromEnvironment('BUILD', defaultValue: 1);
const kVersion = String.fromEnvironment('VERSION', defaultValue: '1.0.0');

class ApiError implements Exception {
  final String message;
  final int status;
  ApiError(this.message, [this.status = 0]);
  @override
  String toString() => message;
}

class Api {
  Api._();
  static final Api i = Api._();

  final _st = const FlutterSecureStorage();
  final _client = http.Client();
  final authed = ValueNotifier<bool>(false);
  int? deviceId;
  String? _refresh;
  String? _access;
  DateTime _accessExp = DateTime(2000);
  Map<String, dynamic> user = {};
  Future<void>? _refreshing;

  bool get canApprove => user['perms']?['approve'] == true;
  bool get canManage => user['perms']?['manage'] == true;
  String get username => (user['username'] ?? '').toString();

  Future<void> load() async {
    try {
      final id = await _st.read(key: 'device_id');
      _refresh = await _st.read(key: 'refresh');
      final u = await _st.read(key: 'user');
      if (id != null && _refresh != null) {
        deviceId = int.tryParse(id);
        if (u != null) user = Map<String, dynamic>.from(jsonDecode(u));
        authed.value = true;
      }
    } catch (_) {}
  }

  Uri _u(String p) => Uri.parse('$kBase/api$p');

  Future<dynamic> _send(String method, String path, {Object? body, String? bearer}) async {
    final req = http.Request(method, _u(path));
    req.headers['Accept'] = 'application/json';
    if (body != null) {
      req.headers['Content-Type'] = 'application/json';
      req.body = jsonEncode(body);
    }
    if (bearer != null) req.headers['Authorization'] = 'Bearer $bearer';
    http.Response res;
    try {
      res = await http.Response.fromStream(await _client.send(req).timeout(const Duration(seconds: 120)));
    } on TimeoutException {
      throw ApiError('Serveris neatsakė laiku');
    } on SocketException {
      throw ApiError('Nėra interneto ryšio');
    } on http.ClientException {
      throw ApiError('Nepavyko prisijungti prie serverio');
    }
    dynamic d;
    try {
      d = res.bodyBytes.isEmpty ? null : jsonDecode(utf8.decode(res.bodyBytes));
    } catch (_) {
      d = null;
    }
    if (res.statusCode >= 400) {
      throw ApiError(d is Map && d['error'] is String ? d['error'] as String : 'Klaida ${res.statusCode}', res.statusCode);
    }
    return d;
  }

  Future<String?> login(String email, String password) async {
    final d = await _send('POST', '/login', body: {'email': email.trim(), 'password': password});
    if (d is Map && d['need2fa'] == true) return d['ticket'] as String;
    await _session(d['token'] as String);
    return null;
  }

  Future<void> login2fa(String ticket, String code) async {
    final d = await _send('POST', '/login/2fa', body: {'ticket': ticket, 'code': code.trim()});
    await _session(d['token'] as String);
  }

  Future<void> _session(String siteToken) async {
    final name = Platform.isIOS ? 'iPhone' : 'Android ${Platform.operatingSystemVersion.split(' ').take(2).join(' ')}';
    final d = await _send('POST', '/app/session', bearer: siteToken, body: {'name': name, 'platform': Platform.isIOS ? 'ios' : 'android', 'build': kBuild});
    await _apply(d);
  }

  Future<void> _apply(dynamic d) async {
    deviceId = d['deviceId'] as int;
    _refresh = d['refresh'] as String;
    _access = d['access'] as String;
    _accessExp = DateTime.now().add(Duration(seconds: ((d['expiresIn'] ?? 900) as int) - 60));
    if (d['user'] is Map) user = Map<String, dynamic>.from(d['user']);
    await _st.write(key: 'device_id', value: '$deviceId');
    await _st.write(key: 'refresh', value: _refresh);
    await _st.write(key: 'user', value: jsonEncode(user));
    authed.value = true;
  }

  Future<void> _doRefresh() async {
    try {
      final d = await _send('POST', '/app/refresh', body: {'deviceId': deviceId, 'refresh': _refresh, 'build': kBuild});
      await _apply(d);
    } on ApiError catch (e) {
      if (e.status == 401) {
        await clear();
        throw ApiError(e.message, 401);
      }
      rethrow;
    }
  }

  Future<void> _ensure({bool force = false}) async {
    if (!force && _access != null && DateTime.now().isBefore(_accessExp)) return;
    if (_refresh == null || deviceId == null) {
      await clear();
      throw ApiError('Prisijunk iš naujo', 401);
    }
    _refreshing ??= _doRefresh().whenComplete(() => _refreshing = null);
    await _refreshing;
  }

  Future<dynamic> req(String method, String path, [Object? body]) async {
    await _ensure();
    try {
      return await _send(method, path, body: body, bearer: _access);
    } on ApiError catch (e) {
      if (e.status != 401) rethrow;
      await _ensure(force: true);
      return _send(method, path, body: body, bearer: _access);
    }
  }

  Future<dynamic> get(String p) => req('GET', p);
  Future<dynamic> post(String p, [Object? b]) => req('POST', p, b ?? {});
  Future<dynamic> put(String p, Object b) => req('PUT', p, b);
  Future<dynamic> del(String p) => req('DELETE', p);
  Future<dynamic> publicGet(String p) => _send('GET', p);

  Future<void> logout() async {
    try {
      await post('/app/logout');
    } catch (_) {}
    await clear();
  }

  Future<void> clear() async {
    _access = null;
    _refresh = null;
    deviceId = null;
    user = {};
    try {
      await _st.deleteAll();
    } catch (_) {}
    authed.value = false;
  }
}
