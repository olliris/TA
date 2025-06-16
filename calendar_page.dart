// 📄 lib/calendar_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:table_calendar/table_calendar.dart';
import 'add_flight_page.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime _selectedDay = DateTime.now();
  Map<DateTime, List<Map<String, dynamic>>> _events = {};

  @override
  void initState() {
    super.initState();
    fetchReservations();
  }

  Future<void> fetchReservations() async {
    final reservations = await FirebaseFirestore.instance.collection('reservations').get();
    final Map<DateTime, List<Map<String, dynamic>>> events = {};

    for (var doc in reservations.docs) {
      final data = doc.data();
      final start = (data['start'] as Timestamp).toDate();
      final date = DateTime(start.year, start.month, start.day);

      events.putIfAbsent(date, () => []);
      events[date]!.add({...data, 'id': doc.id});
    }

    setState(() {
      _events = events;
    });
  }

  Future<void> reserveSlot() async {
    TimeOfDay? start = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (start == null) return;

    TimeOfDay? end = await showTimePicker(context: context, initialTime: TimeOfDay(hour: start.hour + 1, minute: start.minute));
    if (end == null) return;

    final startDate = DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day, start.hour, start.minute);
    final endDate = DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day, end.hour, end.minute);

    final commentController = TextEditingController();
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Commentaire"),
        content: TextField(controller: commentController),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annuler")),
          ElevatedButton(
            onPressed: () async {
              final user = FirebaseAuth.instance.currentUser;
              await FirebaseFirestore.instance.collection('reservations').add({
                'userId': user!.uid,
                'start': Timestamp.fromDate(startDate),
                'end': Timestamp.fromDate(endDate),
                'commentaire': commentController.text,
              });
              Navigator.pop(context);
              fetchReservations();
            },
            child: const Text("Réserver"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dayEvents = _events[_selectedDay] ?? [];
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text("Réservations")),
      body: Column(
        children: [
          TableCalendar(
            focusedDay: _selectedDay,
            firstDay: DateTime.utc(2020),
            lastDay: DateTime.utc(2100),
            selectedDayPredicate: (day) => isSameDay(day, _selectedDay),
            onDaySelected: (selected, focused) => setState(() => _selectedDay = selected),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.builder(
              itemCount: dayEvents.length,
              itemBuilder: (context, index) {
                final event = dayEvents[index];
                final start = (event['start'] as Timestamp).toDate();
                final end = (event['end'] as Timestamp).toDate();
                final isOwner = event['userId'] == currentUser?.uid;

                return ListTile(
                  title: Text("${start.hour}h${start.minute.toString().padLeft(2, '0')} - ${end.hour}h${end.minute.toString().padLeft(2, '0')}"),
                  subtitle: Text(event['commentaire'] ?? ''),
                  trailing: isOwner && end.isBefore(DateTime.now())
                      ? ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const AddFlightPage()),
                            );
                          },
                          child: const Text("Encoder"),
                        )
                      : null,
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: reserveSlot,
        child: const Icon(Icons.add),
      ),
    );
  }
}