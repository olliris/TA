import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StartFlightPage extends StatefulWidget {
  @override
  _StartFlightPageState createState() => _StartFlightPageState();
}

class _StartFlightPageState extends State<StartFlightPage> {
  final _formKey = GlobalKey<FormState>();
  String? _compteurDebut;
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Démarrer un vol")),
      body: _isSubmitting
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Text(
                      "Avant le vol, entrez le compteur affiché sur l'avion",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 32),
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: "Compteur de début (ex: 1281h12)",
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v == null || v.isEmpty ? "Champ obligatoire" : null,
                      onSaved: (v) => _compteurDebut = v,
                    ),
                    SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _submit,
                      child: Text("Enregistrer & Commencer le vol"),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState?.save();
    setState(() => _isSubmitting = true);

    try {
      final user = FirebaseAuth.instance.currentUser!;
      // On crée une réservation de vol non terminée
      await FirebaseFirestore.instance.collection('reservations').add({
        'userId': user.uid,
        'compteurDebut': _compteurDebut,
        'debut': FieldValue.serverTimestamp(),
        'terminee': false,
      });

      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Début de vol enregistré ! Bon vol 🚀")),
      );
      Navigator.pop(context);

    } catch (e) {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur: $e")),
      );
    }
  }
}