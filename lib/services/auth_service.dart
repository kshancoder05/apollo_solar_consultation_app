import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:apollo_solar_consultation_app/services/session.dart';

const String kAuthUrl = 'https://bernard100.app.n8n.cloud/webhook/apollo-auth';
const String kAuthProxyUrl = 'http://localhost:3000/api/auth';
String get _authUrl => kIsWeb ? kAuthProxyUrl : kAuthUrl;

class AuthService {
  static String lastError = '';

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
      final res = await http
          .post(
            Uri.parse(_authUrl),
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
