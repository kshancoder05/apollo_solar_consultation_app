import 'package:flutter/material.dart';
import 'package:apollo_solar_consultation_app/services/auth_service.dart';
import 'package:apollo_solar_consultation_app/screens/home/dashboard.dart';

const _navy = Color(0xFF1A2A6C);
const _gold = Color(0xFFC8A200);
const _grey = Color(0xFF888888);

class RegisterScreen extends StatefulWidget {
  final VoidCallback? onSuccess;
  const RegisterScreen({Key? key, this.onSuccess}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  String _role = 'Sales';
  bool _busy = false;
  bool _obscure = true;
  String _error = '';

  static const _roles = [
    {'key': 'Sales', 'label': 'Sales'},
    {'key': 'Head of Sales', 'label': 'Head of Sales'},
    {'key': 'Engineering', 'label': 'Engineering'},
    {'key': 'Head of Engineering', 'label': 'Head of Engineering'},
    {'key': 'Admin', 'label': 'Admin'},
  ];

  String _normalizeRole(String role) {
    final value = role.toLowerCase().trim();
    if (value.contains('head of sales') || value == 'hos') return 'hos';
    if (value.contains('engineering') || value.contains('eng')) return 'eng';
    if (value.contains('admin')) return 'admin';
    return 'sales';
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_name.text.trim().isEmpty || _email.text.trim().isEmpty || _password.text.isEmpty) {
      setState(() => _error = 'Fill in name, email, and password.');
      return;
    }
    setState(() {
      _busy = true;
      _error = '';
    });
    final ok = await AuthService.register(
      name: _name.text,
      email: _email.text,
      password: _password.text,
      role: _normalizeRole(_role),
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) {
      if (widget.onSuccess != null) {
        widget.onSuccess!();
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const DashboardPage()),
        );
      }
    } else {
      setState(() => _error = AuthService.lastError);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        backgroundColor: _navy,
        foregroundColor: Colors.white,
        title: const Text('Create Account'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                _field(_name, 'Full name', Icons.person_outline),
                const SizedBox(height: 14),
                _field(_email, 'Email', Icons.email_outlined, keyboard: TextInputType.emailAddress),
                const SizedBox(height: 14),
                _field(_password, 'Password', Icons.lock_outline,
                    obscure: _obscure,
                    suffix: IconButton(
                      icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility, color: _grey),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    )),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  value: _role,
                  decoration: InputDecoration(
                    labelText: 'Role',
                    prefixIcon: const Icon(Icons.badge_outlined, color: _grey),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  items: _roles
                      .map((r) => DropdownMenuItem(value: r['key'], child: Text(r['label']!)))
                      .toList(),
                  onChanged: (v) => setState(() => _role = v ?? 'Sales'),
                ),
                const SizedBox(height: 6),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Role may be reviewed/approved by an admin.',
                      style: TextStyle(color: _grey, fontSize: 11.5)),
                ),
                if (_error.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(_error, style: const TextStyle(color: Color(0xFFC0392B), fontSize: 12.5)),
                ],
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _busy ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _gold,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: _busy
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                        : const Text('Register', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController c, String label, IconData icon,
      {bool obscure = false, TextInputType keyboard = TextInputType.text, Widget? suffix}) {
    return TextField(
      controller: c,
      obscureText: obscure,
      keyboardType: keyboard,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: _grey),
        suffixIcon: suffix,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
