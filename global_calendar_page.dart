import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

class GlobalCalendarPage extends StatefulWidget {
  @override
  _GlobalCalendarPageState createState() => _GlobalCalendarPageState();
}

class _GlobalCalendarPageState extends State<GlobalCalendarPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Réserver un vol - Calendrier")),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime(DateTime.now().year, 1, 1),
            lastDay: DateTime(DateTime.now().year + 2, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) async {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
              final result = await showDialog(
                context: context,
                builder: (_) => ReservationDialog(
                  initialDate: selectedDay,
                ),
              );
              if (result == true) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Réservation enregistrée !")),
                );
              }
            },
            calendarFormat: CalendarFormat.month,
            availableCalendarFormats: const {
              CalendarFormat.month: 'Mois',
              CalendarFormat.twoWeeks: '2 semaines',
              CalendarFormat.week: 'Semaine',
            },
            headerStyle: HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            "Planning hebdomadaire (cliquer sur les blocs pour voir les détails)",
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: WeeklyPlanning(selectedDay: _selectedDay ?? DateTime.now()),
          ),
        ],
      ),
    );
  }
}

// ----- Affichage hebdomadaire -----

class WeeklyPlanning extends StatelessWidget {
  final DateTime selectedDay;
  WeeklyPlanning({required this.selectedDay});

  @override
  Widget build(BuildContext context) {
    // Cherche le lundi de la semaine sélectionnée
    final weekStart = selectedDay.subtract(Duration(days: selectedDay.weekday - 1));
    final weekEnd = weekStart.add(Duration(days: 6));

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('reservations')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(
              DateTime(weekStart.year, weekStart.month, weekStart.day)))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(
              DateTime(weekEnd.year, weekEnd.month, weekEnd.day, 23, 59, 59)))
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
        final List<Appointment> appointments = [];
        for (var doc in snapshot.data!.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final date = (data['date'] as Timestamp).toDate();
          final start = _parseTimeOfDay(data['start']);
          final end = _parseTimeOfDay(data['end']);
          final startDateTime = DateTime(date.year, date.month, date.day, start.hour, start.minute);
          final endDateTime = DateTime(date.year, date.month, date.day, end.hour, end.minute);
          final user = data['userName'] ?? data['userId'] ?? '';
          appointments.add(Appointment(
            startTime: startDateTime,
            endTime: endDateTime,
            subject: user,
            color: Colors.blueAccent,
          ));
        }
        return SfCalendar(
          view: CalendarView.week,
          initialDisplayDate: selectedDay,
          dataSource: ReservationDataSource(appointments),
          timeSlotViewSettings: TimeSlotViewSettings(
            startHour: 6,
            endHour: 22,
            timeInterval: Duration(minutes: 30),
          ),
          onTap: (details) {
            if (details.appointments != null && details.appointments!.isNotEmpty) {
              final Appointment appt = details.appointments!.first;
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: Text("Réservation"),
                  content: Text(
                    "Réservé par : ${appt.subject}\n"
                    "Début : ${appt.startTime.hour.toString().padLeft(2, '0')}:${appt.startTime.minute.toString().padLeft(2, '0')}\n"
                    "Fin : ${appt.endTime.hour.toString().padLeft(2, '0')}:${appt.endTime.minute.toString().padLeft(2, '0')}\n"
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text("OK"),
                    ),
                  ],
                ),
              );
            }
          },
        );
      },
    );
  }

  TimeOfDay _parseTimeOfDay(String time) {
    final parts = time.split(':');
    return TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 0,
      minute: int.tryParse(parts.length > 1 ? parts[1] : "0") ?? 0,
    );
  }
}

class ReservationDataSource extends CalendarDataSource {
  ReservationDataSource(List<Appointment> source) {
    appointments = source;
  }
}

// ----- Dialog de réservation -----

class ReservationDialog extends StatefulWidget {
  final DateTime initialDate;
  ReservationDialog({required this.initialDate});

  @override
  _ReservationDialogState createState() => _ReservationDialogState();
}

class _ReservationDialogState extends State<ReservationDialog> {
  final _formKey = GlobalKey<FormState>();
  TimeOfDay? _start;
  TimeOfDay? _end;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Nouvelle réservation"),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text("Début"),
              trailing: Text(_start != null ? "${_start!.hour}h${_start!.minute.toString().padLeft(2, "0")}" : "--:--"),
              onTap: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay(hour: 8, minute: 0),
                );
                if (picked != null) setState(() => _start = picked);
              },
            ),
            ListTile(
              title: Text("Fin"),
              trailing: Text(_end != null ? "${_end!.hour}h${_end!.minute.toString().padLeft(2, "0")}" : "--:--"),
              onTap: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay(hour: 10, minute: 0),
                );
                if (picked != null) setState(() => _end = picked);
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          child: Text("Annuler"),
          onPressed: () => Navigator.of(context).pop(false),
        ),
        ElevatedButton(
          child: Text("Réserver"),
          onPressed: () async {
            if (_start == null || _end == null) return;
            final user = FirebaseAuth.instance.currentUser;
            if (user == null) return;
            // Ajoute la réservation dans Firestore
            await FirebaseFirestore.instance.collection('reservations').add({
              'userId': user.uid,
              'userName': user.displayName ?? '',
              'date': Timestamp.fromDate(widget.initialDate),
              'start': "${_start!.hour.toString().padLeft(2, "0")}:${_start!.minute.toString().padLeft(2, "0")}",
              'end': "${_end!.hour.toString().padLeft(2, "0")}:${_end!.minute.toString().padLeft(2, "0")}",
              'terminee': false,
            });
            Navigator.of(context).pop(true);
          },
        ),
      ],
    );
  }
}