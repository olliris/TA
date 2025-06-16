// 📄 lib/flight_history_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class FlightHistoryPage extends StatefulWidget {
  const FlightHistoryPage({super.key});

  @override
  State<FlightHistoryPage> createState() => _FlightHistoryPageState();
}

class _FlightHistoryPageState extends State<FlightHistoryPage> {
  int totalMinutes = 0;
  double totalCost = 0;
  double totalTaxes = 0;
  double totalCarburant = 0;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Center(child: Text("Utilisateur non connecté."));

    return Scaffold(
      appBar: AppBar(title: const Text("Historique des vols")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('vols')
            .where('userId', isEqualTo: user.uid)
            .orderBy('date', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final vols = snapshot.data!.docs;
          totalMinutes = 0;
          totalCost = 0;
          totalTaxes = 0;
          totalCarburant = 0;

          final widgets = vols.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final date = (data['date'] as Timestamp).toDate();
            final minutes = data['dureeMin'] ?? 0;
            final cout = data['coutVol'] ?? 0.0;
            final taxes = data['taxes'] ?? 0.0;
            final carburant = data['carburantPrix'] ?? 0.0;

            totalMinutes += minutes;
            totalCost += cout;
            totalTaxes += taxes;
            totalCarburant += carburant;

            return ListTile(
              title: Text("Vol du ${DateFormat('dd/MM/yyyy').format(date)} - $minutes min"),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Coût : ${cout.toStringAsFixed(2)} €"),
                  Text("Aérodromes : ${data['aerodromes'] ?? ''}"),
                  Text("Taxes : ${taxes.toStringAsFixed(2)} €"),
                  Text("Carburant avancé : ${carburant.toStringAsFixed(2)} €"),
                  if ((data['remarque'] ?? '').isNotEmpty)
                    Text("Remarque : ${data['remarque']}", style: const TextStyle(color: Colors.red))
                ],
              ),
            );
          }).toList();

          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              Card(
                color: Colors.blue.shade50,
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Récapitulatif", style: TextStyle(fontWeight: FontWeight.bold)),
                      Text("Total minutes volées : $totalMinutes min"),
                      Text("Total payé : ${totalCost.toStringAsFixed(2)} €"),
                      Text("Taxes cumulées : ${totalTaxes.toStringAsFixed(2)} €"),
                      Text("Carburant avancé : ${totalCarburant.toStringAsFixed(2)} €"),
                    ],
                  ),
                ),
              ),
              ...widgets
            ],
          );
        },
      ),
    );
  }
}
