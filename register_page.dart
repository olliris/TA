import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';

class RegisterPage extends StatefulWidget {
  final VoidCallback onTap;
  const RegisterPage({super.key, required this.onTap});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final nameController = TextEditingController();

  void registerUser() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();
    final name = nameController.text.trim();

    if (email.isEmpty || password.isEmpty || confirmPassword.isEmpty || name.isEmpty) {
      showError("Tous les champs sont obligatoires.");
      return;
    }

    if (password != confirmPassword) {
      showError("Les mots de passe ne correspondent pas.");
      return;
    }

    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await cred.user?.updateDisplayName(name);

      // Create user document in Firestore
      await FirebaseFirestore.instance.collection('users').doc(cred.user!.uid).set({
        'solde': 0,
        'heuresVol': 0,
        'displayName': name,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
      });

      Fluttertoast.showToast(msg: "Compte créé avec succès !");
      // After registration, go to login page
      widget.onTap();

    } on FirebaseAuthException catch (e) {
      showError(e.message ?? "Une erreur est survenue.");
    } catch (e) {
      showError("Erreur inattendue: $e");
    }
  }

  void showError(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Erreur"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          )
        ],
      ),
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 25),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.flight_takeoff, size: 100),
                const SizedBox(height: 25),
                const Text(
                  "Créer un compte",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 25),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    hintText: 'Prénom Nom',
                    border: OutlineInputBorder(),
                    filled: true,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    hintText: 'Adresse email',
                    border: OutlineInputBorder(),
                    filled: true,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    hintText: 'Mot de passe',
                    border: OutlineInputBorder(),
                    filled: true,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: confirmPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    hintText: 'Confirmer le mot de passe',
                    border: OutlineInputBorder(),
                    filled: true,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: registerUser,
                  child: const Text("S'inscrire"),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Déjà inscrit ?"),
                    TextButton(
                      onPressed: widget.onTap,
                      child: const Text("Se connecter"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}