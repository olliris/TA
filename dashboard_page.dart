// 📄 lib/dashboard_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'widgets/recurring_reservation_form.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  Future<Map<String, dynamic>> chargerStats() async {
    final vols = await FirebaseFirestore.instance.collection('vols').get();
    final users = await FirebaseFirestore.instance.collection('users').get();
    final paiements = await FirebaseFirestore.instance.collection('paiements').get();

    int totalMinutes = 0;
    double totalFrais = 0;
    double totalCarburant = 0;
    final Map<String, int> minutesParPilote = {};
    final Map<String, double> paiementsParPilote = {};
    final Map<String, double> carburantParPilote = {};

    for (final doc in vols.docs) {
      final data = doc.data();
      totalMinutes += data['dureeMin'] ?? 0;
      totalFrais += data['coutVol'] ?? 0.0;
      totalCarburant += data['carburantPrix'] ?? 0.0;
      final userId = data['userId'] ?? '';
      minutesParPilote[userId] = (minutesParPilote[userId] ?? 0) + (data['dureeMin'] ?? 0);
      carburantParPilote[userId] = (carburantParPilote[userId] ?? 0) + (data['carburantPrix'] ?? 0.0);
    }

    for (final doc in paiements.docs) {
      final data = doc.data();
      final userId = data['userId'] ?? '';
      paiementsParPilote[userId] = (paiementsParPilote[userId] ?? 0) + (data['montant'] ?? 0.0);
    }

    return {
      'totalMinutes': totalMinutes,
      'totalHeures': (totalMinutes / 60).toStringAsFixed(1),
      'totalFrais': totalFrais.toStringAsFixed(2),
      'totalCarburant': totalCarburant.toStringAsFixed(2),
      'pilotes': users.docs.map((u) {
        final id = u.id;
        final nom = u['email'] ?? id;
        final min = minutesParPilote[id] ?? 0;
        final paiement = paiementsParPilote[id] ?? 0.0;
        final avance = carburantParPilote[id] ?? 0.0;
        final volCout = min * 58 / 60;
        final solde = paiement - volCout + avance;
        return {
          'id': id,
          'nom': nom,
          'heures': (min / 60).toStringAsFixed(1),
          'cout': volCout.toStringAsFixed(2),
          'paye': paiement.toStringAsFixed(2),
          'avance': avance.toStringAsFixed(2),
          'solde': solde.toStringAsFixed(2),
        };
      }).toList(),
    };
  }

  Future<void> exporterCSV(BuildContext context, List pilotes) async {
    final buffer = StringBuffer();
    buffer.writeln("Nom,Heures,Cout,Paye,Avance Carburant,Solde");
    for (final p in pilotes) {
      buffer.writeln("${p['nom']},${p['heures']},${p['cout']},${p['paye']},${p['avance']},${p['solde']}");
    }
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/rapport_copro.csv');
    await file.writeAsString(buffer.toString(), encoding: utf8);
    await Share.shareXFiles([XFile(file.path)], text: "Rapport copropriété ULM");
  }

  void ajouterPaiement(BuildContext context, String userId, String userNom) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Ajouter un paiement pour $userNom"),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: "Montant en €"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annuler")),
          ElevatedButton(
            onPressed: () async {
              final montant = double.tryParse(controller.text);
              if (montant != null && montant > 0) {
                await FirebaseFirestore.instance.collection('paiements').add({
                  'userId': userId,
                  'montant': montant,
                  'valide': false,
                  'date': Timestamp.now(),
                });
                Navigator.pop(context);
              }
            },
            child: const Text("Ajouter"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text("Tableau de bord"),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            tooltip: "Nouvelle réservation récurrente",
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => RecurringReservationForm(userId: userId),
              ),
            ),
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: chargerStats(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final data = snapshot.data!;
          final pilotes = data['pilotes'] as List;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                color: Colors.lightBlue.shade50,
                child: ListTile(
                  title: const Text("Heures totales avion"),
                  subtitle: Text("${data['totalHeures']} h (${data['totalMinutes']} minutes)"),
                ),
              ),
              Card(
                color: Colors.green.shade50,
                child: ListTile(
                  title: const Text("Frais total générés"),
                  subtitle: Text("${data['totalFrais']} € | Carburant avancé : ${data['totalCarburant']} €"),
                ),
              ),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Détail par pilote", style: TextStyle(fontWeight: FontWeight.bold)),
                  TextButton.icon(
                    onPressed: () => exporterCSV(context, pilotes),
                    icon: const Icon(Icons.download),
                    label: const Text("Exporter CSV"),
                  )
                ],
              ),
              ...pilotes.map((p) => ListTile(
                    title: Text(p['nom']),
                    subtitle: Text("${p['heures']} h - ${p['cout']} €"),
                    trailing: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("Payé: ${p['paye']} €"),
                        Text("Solde: ${p['solde']} €", style: TextStyle(
                          color: double.parse(p['solde']) < 0 ? Colors.red : Colors.green,
                          fontWeight: FontWeight.bold,
                        )),
                        IconButton(
                          onPressed: () => ajouterPaiement(context, p['id'], p['nom']),
                          icon: const Icon(Icons.add_circle_outline),
                          tooltip: "Ajouter paiement",
                        ),
                      ],
                    ),
                  ))
            ],
          );
        },
      ),
    );
  }
}
