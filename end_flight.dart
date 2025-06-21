import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EndFlightPage extends StatefulWidget {
  @override
  _EndFlightPageState createState() => _EndFlightPageState();
}

class _EndFlightPageState extends State<EndFlightPage> {
  final _formKey = GlobalKey<FormState>();
  String? _compteurFin;
  List<AerodromeEntry> _aerodromes = [AerodromeEntry()];
  List<String> _selectedPilotes = [];
  double _essencePayee = 0.0;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _selectedPilotes = [user.uid];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Terminer le vol")),
      body: _isSubmitting
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Text("Fin de vol", style: TextStyle(fontWeight: FontWeight.bold)),
                    TextFormField(
                      decoration: InputDecoration(labelText: "Compteur avion (ex: 1281h12)"),
                      validator: (v) => v == null || v.isEmpty ? "Obligatoire" : null,
                      onSaved: (v) => _compteurFin = v,
                    ),
                    SizedBox(height: 16),
                    Text("Aérodromes visités", style: TextStyle(fontWeight: FontWeight.bold)),
                    ..._aerodromes
                        .asMap()
                        .entries
                        .map((entry) => _buildAerodromeForm(entry.key, entry.value))
                        .toList(),
                    TextButton.icon(
                        onPressed: () {
                          setState(() => _aerodromes.add(AerodromeEntry()));
                        },
                        icon: Icon(Icons.add),
                        label: Text("Ajouter un aérodrome")),
                    SizedBox(height: 16),
                    Text("Pilotes", style: TextStyle(fontWeight: FontWeight.bold)),
                    _buildPilotesSelector(),
                    SizedBox(height: 16),
                    TextFormField(
                      decoration: InputDecoration(
                          labelText: "Carburant payé (€)", helperText: "Indiquez 0 si rien payé"),
                      keyboardType: TextInputType.number,
                      initialValue: "0",
                      onSaved: (v) =>
                          _essencePayee = double.tryParse(v?.replaceAll(",", ".") ?? "0") ?? 0,
                    ),
                    SizedBox(height: 24),
                    ElevatedButton(
                        onPressed: _submit, child: Text("Terminer le vol et enregistrer")),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildAerodromeForm(int idx, AerodromeEntry entry) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: EdgeInsets.all(8),
        child: Column(
          children: [
            TextFormField(
              decoration: InputDecoration(labelText: "Nom/code aérodrome"),
              initialValue: entry.nom,
              validator: (v) => v == null || v.isEmpty ? "Obligatoire" : null,
              onSaved: (v) => entry.nom = v ?? "",
            ),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    decoration: InputDecoration(labelText: "Atterrissages"),
                    initialValue: entry.atterrissages?.toString() ?? "0",
                    keyboardType: TextInputType.number,
                    onSaved: (v) =>
                        entry.atterrissages = int.tryParse(v ?? "0") ?? 0,
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: CheckboxListTile(
                    title: Text("Payé ?"),
                    value: entry.atterrissagePaye,
                    onChanged: (val) =>
                        setState(() => entry.atterrissagePaye = val ?? false),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    decoration: InputDecoration(labelText: "Parkings"),
                    initialValue: entry.parkings?.toString() ?? "0",
                    keyboardType: TextInputType.number,
                    onSaved: (v) => entry.parkings = int.tryParse(v ?? "0") ?? 0,
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: CheckboxListTile(
                    title: Text("Payé ?"),
                    value: entry.parkingPaye,
                    onChanged: (val) =>
                        setState(() => entry.parkingPaye = val ?? false),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    decoration: InputDecoration(labelText: "Essence (€)"),
                    initialValue: entry.essence?.toString() ?? "0",
                    keyboardType: TextInputType.number,
                    onSaved: (v) =>
                        entry.essence = double.tryParse(v ?? "0") ?? 0.0,
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: CheckboxListTile(
                    title: Text("Payé ?"),
                    value: entry.essencePaye,
                    onChanged: (val) =>
                        setState(() => entry.essencePaye = val ?? false),
                  ),
                ),
              ],
            ),
            if (_aerodromes.length > 1)
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  icon: Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    setState(() => _aerodromes.removeAt(idx));
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPilotesSelector() {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance.collection('users').get(),
      builder: (ctx, snap) {
        if (!snap.hasData) return CircularProgressIndicator();
        final users = snap.data!.docs;
        return Wrap(
          spacing: 8,
          children: users.map((doc) {
            final uid = doc.id;
            final nom = doc['nom'] ?? doc['email'] ?? uid;
            return FilterChip(
              label: Text(nom),
              selected: _selectedPilotes.contains(uid),
              onSelected: (selected) {
                setState(() {
                  if (selected)
                    _selectedPilotes.add(uid);
                  else
                    _selectedPilotes.remove(uid);
                });
              },
            );
          }).toList(),
        );
      },
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState?.save();
    setState(() => _isSubmitting = true);

    try {
      final user = FirebaseAuth.instance.currentUser!;
      final resQuery = await FirebaseFirestore.instance
          .collection('reservations')
          .where('userId', isEqualTo: user.uid)
          .where('terminee', isEqualTo: false)
          .orderBy('debut', descending: true)
          .limit(1)
          .get();
      if (resQuery.docs.isEmpty) throw Exception("Aucune réservation trouvée");
      final resDoc = resQuery.docs.first.reference;

      final data = resQuery.docs.first.data() as Map<String, dynamic>;
      final debutCompteur = _parseCompteur(data['compteurDebut']);
      final finCompteur = _parseCompteur(_compteurFin!);
      final dureeMin = finCompteur - debutCompteur;
      final dureeParPilote = (dureeMin / _selectedPilotes.length).round();

      await resDoc.update({
        'compteurFin': _compteurFin,
        'terminee': true,
        'aerodromes': _aerodromes.map((a) => a.toMap()).toList(),
        'pilotes': _selectedPilotes,
        'essencePayee': _essencePayee,
        'dureeMin': dureeMin,
      });

      for (final piloteId in _selectedPilotes) {
        final userDoc = FirebaseFirestore.instance.collection('users').doc(piloteId);
        await FirebaseFirestore.instance.runTransaction((tx) async {
          final snap = await tx.get(userDoc);
          final heures = (snap['heuresVol'] ?? 0) + dureeParPilote;
          final solde = (snap['solde'] ?? 0) - (_essencePayee / _selectedPilotes.length);
          tx.update(userDoc, {'heuresVol': heures, 'solde': solde});
        });
      }

      final avionDoc = FirebaseFirestore.instance.collection('config').doc('avion');
      await FirebaseFirestore.instance.runTransaction((tx) async {
        final snap = await tx.get(avionDoc);
        final lastCompteur = snap['compteur'] ?? "0h0";
        final lastVal = _parseCompteur(lastCompteur);
        if (finCompteur > lastVal) {
          tx.update(avionDoc, {'compteur': _compteurFin});
        }
      });

      // Mise à jour des heures totales avion dans 'config/general'
      await mettreAJourHeuresTotalesAvion(finCompteur);

      // TODO: Gestion de la facturation différée pour parkings/atterrissages

      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Vol terminé !")));
      Navigator.pop(context);

    } catch (e) {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erreur: $e")));
    }
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

class AerodromeEntry {
  String nom = '';
  int? atterrissages = 0;
  bool atterrissagePaye = false;
  int? parkings = 0;
  bool parkingPaye = false;
  double? essence = 0;
  bool essencePaye = false;

  Map<String, dynamic> toMap() => {
        'nom': nom,
        'atterrissages': atterrissages,
        'atterrissagePaye': atterrissagePaye,
        'parkings': parkings,
        'parkingPaye': parkingPaye,
        'essence': essence,
        'essencePaye': essencePaye,
      };
}

Future<void> mettreAJourHeuresTotalesAvion(int compteurFinMinutes) async {
  final avionRef = FirebaseFirestore.instance.collection('config').doc('general');

  final doc = await avionRef.get();
  final ancienneValeur = doc.data()?['totalMinutesAvion'] ?? 0;

  if (compteurFinMinutes > ancienneValeur) {
    await avionRef.set({'totalMinutesAvion': compteurFinMinutes}, SetOptions(merge: true));
  }
}