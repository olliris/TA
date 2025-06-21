import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SettingsPage extends StatefulWidget {
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    nameController.text = user?.displayName ?? '';
  }

  Future<void> saveNewName() async {
    final user = FirebaseAuth.instance.currentUser;
    final newName = nameController.text.trim();
    if (user != null && newName.isNotEmpty) {
      await user.updateDisplayName(newName);
      await user.reload();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Nom mis à jour !")),
      );
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Réglages")),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: "Nom d'affichage",
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: saveNewName,
              child: Text("Enregistrer"),
            ),
          ],
        ),
      ),
    );
  }
}