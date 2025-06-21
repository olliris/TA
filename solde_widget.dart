import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SoldeWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return SizedBox();

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('config').doc('pricing').get(),
      builder: (context, priceSnap) {
        if (priceSnap.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        final prixParHeure = (priceSnap.data?.data() as Map?)?['prixParHeure'] ?? 58.0;
        final prixParMinute = prixParHeure / 60.0;

        return FutureBuilder<QuerySnapshot>(
          future: FirebaseFirestore.instance
              .collection('reservations')
              .where('userId', isEqualTo: userId)
              .get(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }
            final docs = snapshot.data?.docs ?? [];
            int totalMinutes = 0;
            for (var doc in docs) {
              final data = doc.data() as Map<String, dynamic>;
              if (data['compteurDebut'] != null && data['compteurFin'] != null) {
                final debut = _parseCompteur(data['compteurDebut']);
                final fin = _parseCompteur(data['compteurFin']);
                final diff = fin - debut;
                if (diff > 0) totalMinutes += diff;
              }
            }
            final montant = totalMinutes * prixParMinute;
            return Card(
              color: Colors.blue[50],
              margin: EdgeInsets.all(8),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    Text("Solde personnel", style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Text("Minutes volées : $totalMinutes min"),
                    Text("Montant estimé : ${montant.toStringAsFixed(2)} €"),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  int _parseCompteur(String compteur) {
    final regex = RegExp(r'(\d+)h(\d+)');
    final match = regex.firstMatch(compteur);
    if (match == null) return 0;
    final heures = int.tryParse(match.group(1) ?? '') ?? 0;
    final minutes = int.tryParse(match.group(2) ?? '') ?? 0;
    return heures * 60 + minutes;
  }
}