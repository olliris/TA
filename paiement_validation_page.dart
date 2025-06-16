// 📄 lib/paiement_validation_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class PaiementValidationPage extends StatelessWidget {
  const PaiementValidationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Validation des paiements")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('paiements')
            .where('valide', isEqualTo: false)
            .orderBy('date', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final paiements = snapshot.data!.docs;

          if (paiements.isEmpty) {
            return const Center(child: Text("Aucun paiement à valider."));
          }

          return ListView(
            children: paiements.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final montant = data['montant'] ?? 0;
              final date = (data['date'] as Timestamp).toDate();
              final dateStr = DateFormat('dd/MM/yyyy').format(date);
              final userId = data['userId'] ?? '';
              return ListTile(
                title: Text("Utilisateur : $userId"),
                subtitle: Text("Montant: €$montant\nDate: $dateStr"),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.check, color: Colors.green),
                      tooltip: "Valider",
                      onPressed: () async {
                        await FirebaseFirestore.instance
                            .collection('paiements')
                            .doc(doc.id)
                            .update({'valide': true});
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      tooltip: "Supprimer",
                      onPressed: () async {
                        await FirebaseFirestore.instance
                            .collection('paiements')
                            .doc(doc.id)
                            .delete();
                      },
                    ),
                  ],
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
