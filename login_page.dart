import 'package:flutter/material.dart';

class LoginPage extends StatefulWidget {
  final void Function()? onTap;
  const LoginPage({super.key, required this.onTap});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // Contrôleurs pour les champs texte
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  void loginUser() {
    String email = emailController.text.trim();
    String password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      showError("Veuillez remplir tous les champs.");
      return;
    }

    // Ici tu peux connecter Firebase ou un backend plus tard
    print("Connexion réussie avec email: $email");
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Bienvenue"),
        content: Text("Connecté en tant que $email"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          )
        ],
      ),
    );
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 25.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.flight_takeoff, size: 100),
                const SizedBox(height: 25),
                const Text("Connexion",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),

                const SizedBox(height: 25),

                // Email
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    hintText: 'Adresse email',
                    border: OutlineInputBorder(),
                    filled: true,
                  ),
                ),
                const SizedBox(height: 10),

                // Mot de passe
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    hintText: 'Mot de passe',
                    border: OutlineInputBorder(),
                    filled: true,
                  ),
                ),
                const SizedBox(height: 20),

                // Bouton Se connecter
                ElevatedButton(
                  onPressed: loginUser,
                  child: const Text("Se connecter"),
                ),

                const SizedBox(height: 20),

                // Lien vers la page d’inscription
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Pas encore de compte ?"),
                    TextButton(
                      onPressed: widget.onTap,
                      child: const Text("Créer un compte"),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
