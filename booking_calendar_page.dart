// 📄 lib/booking_calendar_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:table_calendar/table_calendar.dart';
import 'post_flight_page.dart';

class BookingCalendarPage extends StatefulWidget {
  const BookingCalendarPage({super.key});

  @override
  State<BookingCalendarPage> createState() => _BookingCalendarPageState();
}

class _BookingCalendarPageState extends State<BookingCalendarPage> {
  CalendarFormat calendarFormat = CalendarFormat.week;
  DateTime selectedDay = DateTime.now();
  final TextEditingController commentaireController = TextEditingController();

  void reserverSlot() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance.collection('reservations').add({
      'userId': user.uid,
      'date': Timestamp.fromDate(selectedDay),
      'commentaire': commentaireController.text,
      'createdAt': Timestamp.now(),
    });

    commentaireController.clear();
    setState(() {});
  }

  Stream<QuerySnapshot> getReservations(DateTime day) {
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    return FirebaseFirestore.instance
        .collection('reservations')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThan: Timestamp.fromDate(end))
        .snapshots();
  }

  void ouvrirSaisiePostVol(BuildContext context, DocumentSnapshot reservationDoc) {
    final data = reservationDoc.data() as Map<String, dynamic>;
    final dateStr = data['date'] != null
        ? (data['date'] as Timestamp).toDate().toString().split(" ")[0]
        : "";
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.9,
        child: PostFlightPage(
          reservationId: reservationDoc.id,
          heureDebutPreRemplie: dateStr,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text("Réservations")),
      body: Column(
        children: [
          TableCalendar(
            focusedDay: selectedDay,
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2100, 12, 31),
            calendarFormat: calendarFormat,
            onFormatChanged: (format) => setState(() => calendarFormat = format),
            onDaySelected: (selected, _) => setState(() => selectedDay = selected),
            selectedDayPredicate: (day) => isSameDay(day, selectedDay),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: commentaireController,
              decoration: const InputDecoration(labelText: "Commentaire pour la réservation"),
            ),
          ),
          ElevatedButton(
            onPressed: reserverSlot,
            child: const Text("Réserver ce créneau"),
          ),
          const Divider(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: getReservations(selectedDay),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                final docs = snapshot.data!.docs;
                if (docs.isEmpty) return const Center(child: Text("Aucune réservation pour ce jour."));

                return ListView(
                  children: docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final isMine = data['userId'] == currentUser?.uid;
                    return ListTile(
                      title: Text(data['commentaire'] ?? 'Sans commentaire'),
                      subtitle: Text("Réservé par: ${data['userId']}"),
                      trailing: isMine
                          ? IconButton(
                              icon: const Icon(Icons.flight_takeoff),
                              tooltip: "Encoder ce vol",
                              onPressed: () => ouvrirSaisiePostVol(context, doc),
                            )
                          : null,
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
