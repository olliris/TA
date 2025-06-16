// 📄 lib/maintenance_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MaintenancePage extends StatefulWidget {
  const MaintenancePage({super.key});

  @override
  State<MaintenancePage> createState() => _MaintenancePageState();
}

class _MaintenancePageState extends State<MaintenancePage> {
  final _formKey = GlobalKey<FormState>();
  final typeController = TextEditingController();
  final dateController = TextEditingController();
  final technicienController = TextEditingController();
  final coutController = TextEditingController();
  final heuresAvionController = TextEditingController();
  final prochainCtrlController = TextEditingController();

  @override
  void dispose() {
    typeController.dispose();
    dateController.dispose();
    technicienController.dispose();
    coutController.dispose();
    heuresAvionController.dispose();
    prochainCtrlController.dispose();
    super.dispose();
  }

  void enregistrerEntretien() async {
    if (!_formKey.currentState!.validate()) return;

    await FirebaseFirestore.instance.collection('entretiens').add({
      'type': typeController.text,
      'date': dateController.text,
      'technicien': technicienController.text,
      'cout': double.tryParse(coutController.text) ?? 0,
      'heuresAvion': int.tryParse(heuresAvionController.text) ?? 0,
      'prochainCtrl': int.tryParse(prochainCtrlController.text) ?? 0,
      'createdAt': Timestamp.now(),
    });

    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Carnet d’entretien')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: typeController,
                decoration: const InputDecoration(labelText: "Type d’entretien (ex: vidange)"),
                validator: (v) => v == null || v.isEmpty ? 'Champ requis' : null,
              ),
              TextFormField(
                controller: dateController,
                decoration: const InputDecoration(labelText: "Date (JJ/MM/AAAA)"),
                validator: (v) => v == null || v.isEmpty ? 'Champ requis' : null,
              ),
              TextFormField(
                controller: technicienController,
                decoration: const InputDecoration(labelText: "Technicien ou atelier"),
              ),
              TextFormField(
                controller: coutController,
                decoration: const InputDecoration(labelText: "Coût (€)"),
                keyboardType: TextInputType.number,
              ),
              TextFormField(
                controller: heuresAvionController,
                decoration: const InputDecoration(labelText: "Heures moteur actuelles"),
                keyboardType: TextInputType.number,
              ),
              TextFormField(
                controller: prochainCtrlController,
                decoration: const InputDecoration(labelText: "Prochain contrôle prévu (h moteur)"),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: enregistrerEntretien,
                child: const Text("Enregistrer l’entretien"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}