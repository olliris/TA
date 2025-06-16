// 📄 lib/add_flight_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddFlightPage extends StatefulWidget {
  const AddFlightPage({super.key});

  @override
  State<AddFlightPage> createState() => _AddFlightPageState();
}

class _AddFlightPageState extends State<AddFlightPage> {
  final _formKey = GlobalKey<FormState>();

  final compteurDebutH = TextEditingController();
  final compteurDebutM = TextEditingController();
  final compteurFinH = TextEditingController();
  final compteurFinM = TextEditingController();
  final atterrissages = TextEditingController();
  final aerodromes = TextEditingController();
  final carburantL = TextEditingController();
  final carburantPrix = TextEditingController();
  final commentaire = TextEditingController();

  bool aPayeCarburant = false;
  final taxes = <Map<String, dynamic>>[];

  String aerodromeBase = "LSGY"; // à charger depuis Firestore à terme

  int toMinutes(String h, String m) {
    return int.parse(h) * 60 + int.parse(m);
  }

  Future<int> getLastCompteurFin() async {
    final snap = await FirebaseFirestore.instance
        .collection('flights')
        .orderBy('compteurFinMinutes', descending: true)
        .limit(1)
        .get();

    if (snap.docs.isEmpty) return 0;
    return snap.docs.first['compteurFinMinutes'] ?? 0;
  }

  void submit() async {
    if (!_formKey.currentState!.validate()) return;

    final debut = toMinutes(compteurDebutH.text, compteurDebutM.text);
    final fin = toMinutes(compteurFinH.text, compteurFinM.text);
    final duree = fin - debut;

    if (duree <= 0) {
      showDialog(
        context: context,
        builder: (_) => const AlertDialog(
          title: Text("Erreur"),
          content: Text("Le compteur de fin doit être supérieur au début."),
        ),
      );
      return;
    }

    final lastFin = await getLastCompteurFin();
    if (debut != lastFin) {
      final continueAnyway = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Attention"),
          content: Text(
              "Le compteur de début ($debut min) ne correspond pas à la fin du vol précédent ($lastFin min). Continuer ?"),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Corriger")),
            ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text("Continuer")),
          ],
        ),
      );

      if (continueAnyway != true) return;
    }

    final montant = duree * (58 / 60);

    final List<String> aeroList =
        aerodromes.text.split(',').map((e) => e.trim()).toList();
    double totalTaxes = 0;

    for (var code in aeroList) {
      if (code != aerodromeBase) {
        final montant = await showDialog<double>(
          context: context,
          builder: (_) {
            final controller = TextEditingController();
            return AlertDialog(
              title: Text("Taxe pour $code"),
              content: TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Montant en €"),
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context, 0),
                    child: const Text("Ignorer")),
                ElevatedButton(
                    onPressed: () => Navigator.pop(
                        context, double.tryParse(controller.text) ?? 0),
                    child: const Text("Valider"))
              ],
            );
          },
        );
        taxes.add({"code": code, "montant": montant});
        totalTaxes += montant;
      }
    }

    final user = FirebaseAuth.instance.currentUser;
    await FirebaseFirestore.instance.collection('flights').add({
      "userId": user!.uid,
      "compteurDebutMinutes": debut,
      "compteurFinMinutes": fin,
      "durationMinutes": duree,
      "montantAPayer": double.parse(montant.toStringAsFixed(2)),
      "nombreAtterrissages": int.tryParse(atterrissages.text) ?? 1,
      "aerodromes": aeroList,
      "taxesAerodrome": taxes,
      "totalTaxes": totalTaxes,
      "carburantL": double.tryParse(carburantL.text) ?? 0,
      "carburantPrix": double.tryParse(carburantPrix.text) ?? 0,
      "aPayeCarburant": aPayeCarburant,
      "commentaire": commentaire.text,
      "timestamp": Timestamp.now(),
    });

    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Ajouter un vol")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: compteurDebutH,
                      decoration: const InputDecoration(labelText: "Début - Heures"),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: compteurDebutM,
                      decoration: const InputDecoration(labelText: "Début - Minutes"),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: compteurFinH,
                      decoration: const InputDecoration(labelText: "Fin - Heures"),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: compteurFinM,
                      decoration: const InputDecoration(labelText: "Fin - Minutes"),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              TextFormField(
                controller: atterrissages,
                decoration: const InputDecoration(labelText: "Nombre d'atterrissages"),
                keyboardType: TextInputType.number,
              ),
              TextFormField(
                controller: aerodromes,
                decoration: const InputDecoration(
                    labelText: "Aérodromes (séparés par des virgules)"),
              ),
              TextFormField(
                controller: carburantL,
                decoration: const InputDecoration(labelText: "Litres carburant ajoutés"),
                keyboardType: TextInputType.number,
              ),
              TextFormField(
                controller: carburantPrix,
                decoration: const InputDecoration(labelText: "Prix carburant €"),
                keyboardType: TextInputType.number,
              ),
              CheckboxListTile(
                title: const Text("J’ai payé le carburant"),
                value: aPayeCarburant,
                onChanged: (val) {
                  setState(() {
                    aPayeCarburant = val ?? false;
                  });
                },
              ),
              TextFormField(
                controller: commentaire,
                decoration: const InputDecoration(labelText: "Commentaire"),
                maxLines: 3,
              ),
              const SizedBox(height: 20),
              ElevatedButton(onPressed: submit, child: const Text("Enregistrer le vol"))
            ],
          ),
        ),
      ),
    );
  }
}
