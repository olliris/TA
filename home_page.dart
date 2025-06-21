import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'monthly_planning_page.dart';
import 'settings_page.dart';

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("Non connecté")),
      );
    }
    final uid = user.uid;
    final nom = user.displayName ?? "Utilisateur";

    return Scaffold(
      appBar: AppBar(
        title: Text("Bienvenue, $nom"),
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SettingsPage()),
              );
            },
            tooltip: "Réglages",
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            //Text('Mon UID : $uid'),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.calendar_month),
              label: const Text("Planning + Réservations"),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => MonthlyPlanningPage()),
                );
              },
            ),
            const SizedBox(height: 16),
            UserStatsCard(userId: uid),
            const SizedBox(height: 16),
            const Text(
              "Mes vols à venir",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: MyUpcomingFlightsList(userId: uid),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.logout),
              label: const Text("Déconnexion"),
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.pushReplacementNamed(context, '/login');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class UserStatsCard extends StatelessWidget {
  final String userId;
  const UserStatsCard({required this.userId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }
        if (snapshot.hasError) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Text(
                  'Erreur: ${snapshot.error}',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ),
          );
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: Text('Aucune donnée utilisateur')),
            ),
          );
        }
        final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
        final solde = data['solde'] ?? 0.0;
        final heuresVol = data['heuresVol'] ?? 0;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Mon solde : ${solde.toStringAsFixed(2)} €",
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 8),
                Text(
                  "Heures de vol : $heuresVol min",
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class MyUpcomingFlightsList extends StatelessWidget {
  final String userId;
  const MyUpcomingFlightsList({required this.userId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('reservations')
          .where('userId', isEqualTo: userId)
          .where('terminee', isEqualTo: false)
          .orderBy('date', descending: false)
          .limit(10)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Erreur: ${snapshot.error}',
              style: TextStyle(color: Colors.red),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Text("Aucune donnée.");
        }
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return const Text("Aucune réservation à venir.");
        }
        return ListView(
          children: docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final date = (data['date'] as Timestamp?)?.toDate();
            final start = data['start'] ?? "";
            final end = data['end'] ?? "";
            return Card(
              child: ListTile(
                title: Text(
                  date != null
                      ? "${date.day.toString().padLeft(2, "0")}/${date.month.toString().padLeft(2, "0")} - $start → $end"
                      : "?",
                ),
                trailing: const Icon(Icons.flight_takeoff),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}