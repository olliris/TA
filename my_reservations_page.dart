import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'reservation_dialog.dart';

class MyReservationsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) {
      return Scaffold(
        appBar: AppBar(title: Text("Mes réservations")),
        body: Center(child: Text("Non connecté")),
      );
    }

    final reservationsStream = FirebaseFirestore.instance
        .collection('reservations')
        .where('userId', isEqualTo: currentUserId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.now())
        .orderBy('date')
        .snapshots();

    return Scaffold(
      appBar: AppBar(title: const Text("Mes réservations à venir")),
      body: StreamBuilder<QuerySnapshot>(
        stream: reservationsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                "Erreur Firestore : ${snapshot.error}",
                style: TextStyle(color: Colors.red),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("Aucune réservation à venir"));
          }

          final docs = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['date'] != null &&
                data['userId'] != null &&
                data['start'] != null &&
                data['end'] != null;
          }).toList();

          if (docs.isEmpty) {
            return const Center(child: Text("Aucune réservation à venir"));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final date = (data['date'] as Timestamp).toDate();
              final start = data['start'];
              final end = data['end'];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  leading: const Icon(Icons.flight),
                  title: Text(
                    "${date.day.toString().padLeft(2, '0')}/"
                    "${date.month.toString().padLeft(2, '0')}/"
                    "${date.year} de $start à $end",
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.orange),
                        onPressed: () async {
                          final result = await showDialog(
                            context: context,
                            builder: (ctx) => ReservationDialog(
                              docId: doc.id,
                              initialDate: date,
                              initialStart: _parseTimeOfDay(start),
                              initialEnd: _parseTimeOfDay(end),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          final confirm = await showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text("Supprimer la réservation ?"),
                              content: const Text("Cette action est irréversible."),
                              actions: [
                                TextButton(
                                  child: const Text("Annuler"),
                                  onPressed: () => Navigator.pop(ctx, false),
                                ),
                                TextButton(
                                  child: const Text("Supprimer"),
                                  onPressed: () => Navigator.pop(ctx, true),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            await FirebaseFirestore.instance
                                .collection('reservations')
                                .doc(doc.id)
                                .delete();
                          }
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

TimeOfDay _parseTimeOfDay(String time) {
  final parts = time.split(':');
  return TimeOfDay(
    hour: int.tryParse(parts[0]) ?? 0,
    minute: int.tryParse(parts.length > 1 ? parts[1] : "0") ?? 0,
  );
}