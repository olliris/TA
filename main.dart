import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'monthly_planning_page.dart';
import 'home_page.dart';
import 'global_calendar_page.dart';
import 'auth/auth_page.dart';
import 'auth/register_page.dart'; // <-- Add this import if needed

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gestion des vols',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => AuthGate(),
        '/home': (context) => HomePage(),
        '/calendar': (context) => GlobalCalendarPage(),
        '/login': (context) => const AuthPage(),
        '/register': (context) => RegisterPage(onTap: () {
          // You may want to navigate back to login or handle after registration
          Navigator.of(context).pushReplacementNamed('/login');
        }),
        // add other routes here if needed
      },
    );
  }
}

class AuthGate extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasData) {
          return HomePage();
        } else {
          return const AuthPage();
        }
      },
    );
  }
}