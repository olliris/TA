// 📄 lib/widgets/anomalie_form.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class AnomalieForm extends StatefulWidget {
  final String volId;
  const AnomalieForm({super.key, required this.volId});

  @override
  State<AnomalieForm> createState() => _AnomalieFormState();
}

class _AnomalieFormState extends State<AnomalieForm> {
  final TextEditingController commentaireController = TextEditingController();
  String gravite = 'faible';
  List<File> images = [];

  Future<void> ajouterImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage();
    if (picked.isNotEmpty) {
      setState(() {
        images.addAll(picked.map((e) => File(e.path)));
      });
    }
  }

  Future<void> soumettreAnomalie() async {
    final docRef = await FirebaseFirestore.instance.collection('anomalies').add({
      'volId': widget.volId,
      'commentaire': commentaireController.text,
      'gravite': gravite,
      'date': Timestamp.now(),
      'photos': [],
    });

    final List<String> urls = [];
    for (final file in images) {
      final name = file.path.split("/").last;
      final ref = FirebaseStorage.instance.ref('anomalies/${docRef.id}/$name');
      await ref.putFile(file);
      final url = await ref.getDownloadURL();
      urls.add(url);
    }

    await docRef.update({'photos': urls});
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text("Signaler une anomalie", style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: gravite,
            items: const [
              DropdownMenuItem(value: 'faible', child: Text("Gravité faible")),
              DropdownMenuItem(value: 'moyenne', child: Text("Gravité moyenne")),
              DropdownMenuItem(value: 'critique', child: Text("Gravité critique")),
            ],
            onChanged: (val) => setState(() => gravite = val!),
            decoration: const InputDecoration(labelText: "Gravité"),
          ),
          TextField(
            controller: commentaireController,
            maxLines: 3,
            decoration: const InputDecoration(labelText: "Commentaire"),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              ...images.map((img) => Image.file(img, width: 80, height: 80, fit: BoxFit.cover)),
              IconButton(
                onPressed: ajouterImage,
                icon: const Icon(Icons.add_a_photo),
                tooltip: "Ajouter une photo",
              )
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: soumettreAnomalie,
            icon: const Icon(Icons.report_problem),
            label: const Text("Soumettre"),
          ),
        ],
      ),
    );
  }
}
