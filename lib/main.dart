import 'package:flutter/material.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/dashboard.dart';
import 'services/session.dart';

void main() {
  runApp(const ApolloApp());
}

class ApolloApp extends StatelessWidget {
  const ApolloApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Apollo',
      home: Session.isLoggedIn ? const DashboardPage() : const LoginScreen(),
    );
  }
}