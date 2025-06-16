// 📄 lib/main_navigation.dart

import 'package:flutter/material.dart';
import 'pages/dashboard_page.dart';
import 'pages/calendar_page.dart';
import 'pages/add_flight_page.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  final pages = const [
    DashboardPage(),
    CalendarPage(),
    AddFlightPage(),
  ];

  final labels = ["Dashboard", "Calendrier", "Nouveau vol"];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: labels[0]),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: labels[1]),
          BottomNavigationBarItem(icon: Icon(Icons.flight_takeoff), label: labels[2]),
        ],
      ),
    );
  }
}
