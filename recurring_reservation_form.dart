// 📄 lib/widgets/recurring_reservation_form.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class RecurringReservationForm extends StatefulWidget {
  final String userId;
  const RecurringReservationForm({super.key, required this.userId});

  @override
  State<RecurringReservationForm> createState() => _RecurringReservationFormState();
}

class _RecurringReservationFormState extends State<RecurringReservationForm> {
  final _formKey = GlobalKey<FormState>();
  DateTime? selectedDate;
  TimeOfDay? startTime;
  TimeOfDay? endTime;
  final TextEditingController commentController = TextEditingController();
  bool repeat = false;
  int repeatCount = 4;

  Future<void> pickDate(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => selectedDate = picked);
  }

  Future<void> pickTime(bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 8, minute: 0),
    );
    if (picked != null) setState(() => isStart ? startTime = picked : endTime = picked);
  }

  Future<void> saveReservations() async {
    if (!_formKey.currentState!.validate()) return;
    if (selectedDate == null || startTime == null || endTime == null) return;

    final baseDate = selectedDate!;
    final List<DateTime> dates = List.generate(
      repeat ? repeatCount : 1,
      (i) => baseDate.add(Duration(days: 7 * i)),
    );

    for (final date in dates) {
      final debut = DateTime(date.year, date.month, date.day, startTime!.hour, startTime!.minute);
      final fin = DateTime(date.year, date.month, date.day, endTime!.hour, endTime!.minute);

      await FirebaseFirestore.instance.collection('reservations').add({
        'userId': widget.userId,
        'start': debut,
        'end': fin,
        'commentaire': commentController.text,
        'createdAt': Timestamp.now(),
      });
    }

    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Nouvelle réservation")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              ListTile(
                title: Text(selectedDate == null
                    ? "Choisir une date"
                    : DateFormat.yMMMMd().format(selectedDate!)),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => pickDate(context),
              ),
              ListTile(
                title: Text(startTime == null
                    ? "Heure de début"
                    : startTime!.format(context)),
                trailing: const Icon(Icons.access_time),
                onTap: () => pickTime(true),
              ),
              ListTile(
                title: Text(endTime == null
                    ? "Heure de fin"
                    : endTime!.format(context)),
                trailing: const Icon(Icons.access_time),
                onTap: () => pickTime(false),
              ),
              TextFormField(
                controller: commentController,
                decoration: const InputDecoration(labelText: "Commentaire"),
              ),
              SwitchListTile(
                title: const Text("Répéter chaque semaine ?"),
                value: repeat,
                onChanged: (val) => setState(() => repeat = val),
              ),
              if (repeat)
                Slider(
                  value: repeatCount.toDouble(),
                  min: 2,
                  max: 10,
                  divisions: 8,
                  label: "$repeatCount semaines",
                  onChanged: (val) => setState(() => repeatCount = val.round()),
                ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: saveReservations,
                icon: const Icon(Icons.save),
                label: const Text("Enregistrer"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
