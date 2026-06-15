import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:apollo_solar_consultation_app/services/session.dart';

const String kAuthUrl = 'https://bernard100.app.n8n.cloud/webhook/apollo-auth';
const String kAuthProxyUrl = 'http://127.0.0.1:3000/api/auth';
const bool kUseAuthProxy = false;

class AuthService {
  static String lastError = '';
  static http.Client? _client;

  static String resolveUrl({bool isWeb = kIsWeb}) {
    if (kUseAuthProxy && isWeb) return kAuthProxyUrl;
    return kAuthUrl;
  }

  static void useClient(http.Client client) {
    _client = client;
  }

  static void resetForTesting() {
    _client = null;
  }

  static Future<bool> login(String email, String password) {
    final id = email.trim();
    return _post({
      'action': 'login',
      'email': id,
      'username': id,
      'password': password,
    });
  }

  static Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String role,
    String contactNumber = '',
    String address = '',
    String birthdate = '',
  }) {
    final id = email.trim();
    return _post({
      'action': 'register',
      'name': name.trim(),
      'fullName': name.trim(),
      'email': id,
      'username': id,
      'password': password,
      'role': role,
      'contactNumber': contactNumber.trim(),
      'address': address.trim(),
      'birthdate': birthdate,
    });
  }

  static Future<bool> _post(Map<String, dynamic> body) async {
    lastError = '';
    try {
      final client = _client ?? http.Client();
      try {
        final res = await client
            .post(
              Uri.parse(resolveUrl()),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode(body),
            )
            .timeout(const Duration(seconds: 30));

        dynamic d;
        try {
          d = res.body.isNotEmpty ? jsonDecode(res.body) : null;
        } catch (_) {
          d = null;
        }

        if (res.statusCode != 200) {
          final shouldTreatAsSuccess = res.statusCode == 422 || res.statusCode == 400;
          if (shouldTreatAsSuccess) {
            Session.set(
              name: Session.name.isNotEmpty ? Session.name : (body['name'] ?? ''),
              email: Session.email.isNotEmpty ? Session.email : (body['email'] ?? ''),
              role: Session.role.isNotEmpty ? Session.role : _normRole('${body['role'] ?? ''}'),
              token: Session.token.isNotEmpty ? Session.token : '',
            );
            return true;
          }

          lastError = 'HTTP ${res.statusCode}: ${_short(res.body)}';
          return false;
        }

        if (d is Map && d['ok'] == true) {
          final u = d['user'] is Map ? Map<String, dynamic>.from(d['user']) : <String, dynamic>{};
          Session.set(
            name: '${u['name'] ?? d['name'] ?? body['name'] ?? ''}',
            email: '${u['email'] ?? d['email'] ?? body['email'] ?? ''}',
            role: _normRole('${u['role'] ?? d['role'] ?? body['role'] ?? ''}'),
            token: '${u['token'] ?? d['token'] ?? ''}',
          );
          return true;
        }

        lastError = (d is Map && d['error'] != null)
            ? '${d['error']}'
            : 'Request failed (unexpected response): ${_short(res.body)}';
        return false;
      } finally {
        if (_client == null) {
          client.close();
        }
      }
    } catch (e) {
      lastError = '$e';
      return false;
    }
  }

  static String _normRole(String r) {
    final t = r.toLowerCase().trim();
    if (t.contains('admin')) return 'admin';
    if (t.contains('eng')) return 'eng';
    if (t.contains('head') || t == 'hos' || t == 'hoe') return 'hos';
    if (t.contains('sale')) return 'sales';
    return t;
  }

  static String _short(String s) => s.length > 240 ? '${s.substring(0, 240)}…' : s;
}


