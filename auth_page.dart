import 'package:flutter/material.dart';
import 'login_page.dart';
import 'register_page.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool showLoginPage = true;

  // This function can be called to show the login page
  void showLogin() {
    setState(() {
      showLoginPage = true;
    });
  }

  // This function can be called to show the register page
  void showRegister() {
    setState(() {
      showLoginPage = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Pass explicit navigation functions to child pages
    if (showLoginPage) {
      return LoginPage(
        onTap: showRegister, // Go to register when requested
      );
    } else {
      return RegisterPage(
        onTap: showLogin, // Go to login when requested
      );
    }
  }
}