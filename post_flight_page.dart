// 📄 lib/post_flight_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PostFlightPage extends StatefulWidget {
  final String? reservationId;
  final String? heureDebutPreRemplie;

  const PostFlightPage({super.key, this.reservationId, this.heureDebutPreRemplie});

  @override
  State<PostFlightPage> createState() => _PostFlightPageState();
}

class _PostFlightPageState extends State<PostFlightPage> {
  final _formKey = GlobalKey<FormState>();
  final heureDebutController = TextEditingController();
  final heureFinController = TextEditingController();
  final nbAtterrissagesController = TextEditingController();
  final aerodromesController = TextEditingController();
  final taxesController = TextEditingController();
  final carburantLitresController = TextEditingController();
  final carburantPrixController = TextEditingController();
  final remarqueController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.heureDebutPreRemplie != null) {
      heureDebutController.text = widget.heureDebutPreRemplie!;
    }
  }

  void enregistrerPostVol() async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final hd = _parseHoraire(heureDebutController.text);
    final hf = _parseHoraire(heureFinController.text);
    final dureeVol = hf - hd;
    final coutVol = dureeVol * (58 / 60);

    await FirebaseFirestore.instance.collection('vols').add({
      'userId': user.uid,
      'reservationId': widget.reservationId,
      'heureDebut': heureDebutController.text,
      'heureFin': heureFinController.text,
      'dureeMin': dureeVol,
      'coutVol': coutVol,
      'nbAtterrissages': int.tryParse(nbAtterrissagesController.text) ?? 0,
      'aerodromes': aerodromesController.text,
      'taxes': double.tryParse(taxesController.text) ?? 0,
      'carburantLitres': double.tryParse(carburantLitresController.text) ?? 0,
      'carburantPrix': double.tryParse(carburantPrixController.text) ?? 0,
      'remarque': remarqueController.text,
      'date': Timestamp.now(),
    });

    if (!mounted) return;
    Navigator.pop(context);
  }

  int _parseHoraire(String texte) {
    final parts = texte.split('h');
    final heures = int.tryParse(parts[0]) ?? 0;
    final minutes = int.tryParse(parts[1]) ?? 0;
    return heures * 60 + minutes;
  }

  @override
  void dispose() {
    heureDebutController.dispose();
    heureFinController.dispose();
    nbAtterrissagesController.dispose();
    aerodromesController.dispose();
    taxesController.dispose();
    carburantLitresController.dispose();
    carburantPrixController.dispose();
    remarqueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Enregistrement post-vol")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: heureDebutController,
                decoration: const InputDecoration(labelText: "Heure de début (ex: 1245h34)"),
              ),
              TextFormField(
                controller: heureFinController,
                decoration: const InputDecoration(labelText: "Heure de fin (ex: 1246h24)"),
              ),
              TextFormField(
                controller: nbAtterrissagesController,
                decoration: const InputDecoration(labelText: "Nombre d'atterrissages"),
                keyboardType: TextInputType.number,
              ),
              TextFormField(
                controller: aerodromesController,
                decoration: const InputDecoration(labelText: "Aérodromes visités"),
              ),
              TextFormField(
                controller: taxesController,
                decoration: const InputDecoration(labelText: "Taxes payées (€)"),
                keyboardType: TextInputType.number,
              ),
              const Divider(),
              TextFormField(
                controller: carburantLitresController,
                decoration: const InputDecoration(labelText: "Carburant ajouté (litres)"),
                keyboardType: TextInputType.number,
              ),
              TextFormField(
                controller: carburantPrixController,
                decoration: const InputDecoration(labelText: "Prix carburant (€)"),
                keyboardType: TextInputType.number,
              ),
              const Divider(),
              TextFormField(
                controller: remarqueController,
                decoration: const InputDecoration(labelText: "Remarques / anomalies"),
                maxLines: 3,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: enregistrerPostVol,
                child: const Text("Valider le vol"),
              )
            ],
          ),
        ),
      ),
    );
  }
}
