import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ReservationDialog extends StatefulWidget {
  final String? docId;
  final DateTime initialDate;
  final TimeOfDay? initialStart;
  final TimeOfDay? initialEnd;

  ReservationDialog({
    this.docId,
    required this.initialDate,
    this.initialStart,
    this.initialEnd,
  });

  @override
  State<ReservationDialog> createState() => _ReservationDialogState();
}

class _ReservationDialogState extends State<ReservationDialog> {
  TimeOfDay? startTime;
  TimeOfDay? endTime;
  bool isLoading = false;
  String? error;

  @override
  void initState() {
    super.initState();
    startTime = widget.initialStart;
    endTime = widget.initialEnd;
  }

  Future<bool> _isSlotAvailable(DateTime date, TimeOfDay start, TimeOfDay end) async {
    final dateKey = DateTime(date.year, date.month, date.day);
    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;
    final snapshot = await FirebaseFirestore.instance
        .collection('reservations')
        .where('date', isEqualTo: Timestamp.fromDate(dateKey))
        .get();
    for (var doc in snapshot.docs) {
      if (widget.docId != null && doc.id == widget.docId) continue;
      final data = doc.data() as Map<String, dynamic>;
      if (data['start'] == null || data['end'] == null) continue;
      final existingStart = _parseTimeOfDay(data['start']);
      final existingEnd = _parseTimeOfDay(data['end']);
      final existingStartMin = existingStart.hour * 60 + existingStart.minute;
      final existingEndMin = existingEnd.hour * 60 + existingEnd.minute;
      if (startMinutes < existingEndMin && endMinutes > existingStartMin) {
        return false;
      }
    }
    return true;
  }

  TimeOfDay _parseTimeOfDay(String time) {
    final parts = time.split(':');
    return TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 0,
      minute: int.tryParse(parts.length > 1 ? parts[1] : "0") ?? 0,
    );
  }

  bool _isPast(DateTime date, TimeOfDay? start) {
    final now = DateTime.now();
    final dateDay = DateTime(date.year, date.month, date.day);
    if (dateDay.isBefore(DateTime(now.year, now.month, now.day))) return true;
    if (dateDay.isAtSameMomentAs(DateTime(now.year, now.month, now.day)) &&
        start != null) {
      final nowMinutes = now.hour * 60 + now.minute;
      final startMinutes = start.hour * 60 + start.minute;
      return startMinutes <= nowMinutes;
    }
    return false;
  }

  Future<void> _save() async {
    setState(() {
      isLoading = true;
      error = null;
    });
    if (startTime == null || endTime == null) {
      setState(() {
        isLoading = false;
        error = "Sélectionner les horaires.";
      });
      return;
    }
    if ((endTime!.hour * 60 + endTime!.minute) <=
        (startTime!.hour * 60 + startTime!.minute)) {
      setState(() {
        isLoading = false;
        error = "Fin doit être après début.";
      });
      return;
    }
    // Prevent reservation in the past
    if (_isPast(widget.initialDate, startTime)) {
      setState(() {
        isLoading = false;
        error = "Impossible de réserver dans le passé.";
      });
      return;
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        isLoading = false;
        error = "Utilisateur non connecté.";
      });
      return;
    }
    final available = await _isSlotAvailable(widget.initialDate, startTime!, endTime!);
    if (!available) {
      setState(() {
        isLoading = false;
        error = "Créneau déjà réservé.";
      });
      return;
    }
    final data = {
      'date': Timestamp.fromDate(DateTime(widget.initialDate.year, widget.initialDate.month, widget.initialDate.day)),
      'start': "${startTime!.hour.toString().padLeft(2, '0')}:${startTime!.minute.toString().padLeft(2, '0')}",
      'end': "${endTime!.hour.toString().padLeft(2, '0')}:${endTime!.minute.toString().padLeft(2, '0')}",
      'userId': user.uid,
      'userName': user.displayName,
      'userEmail': user.email,
    };
    if (widget.docId == null) {
      await FirebaseFirestore.instance.collection('reservations').add(data);
    } else {
      await FirebaseFirestore.instance
          .collection('reservations')
          .doc(widget.docId)
          .update(data);
    }
    Navigator.of(context).pop(true);
  }

  Future<void> _delete() async {
    if (widget.docId != null) {
      await FirebaseFirestore.instance
          .collection('reservations')
          .doc(widget.docId)
          .delete();
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.docId == null
          ? "Nouvelle réservation"
          : "Modifier la réservation"),
      content: isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton(
                  child: Text(startTime == null
                      ? "Heure de début"
                      : "Début: ${startTime!.format(context)}"),
                  onPressed: () async {
                    TimeOfDay? picked = await showTimePicker(
                        context: context,
                        initialTime: startTime ?? TimeOfDay(hour: 6, minute: 0));
                    if (picked != null) setState(() => startTime = picked);
                  },
                ),
                ElevatedButton(
                  child: Text(endTime == null
                      ? "Heure de fin"
                      : "Fin: ${endTime!.format(context)}"),
                  onPressed: () async {
                    TimeOfDay? picked = await showTimePicker(
                        context: context,
                        initialTime: endTime ?? TimeOfDay(hour: 7, minute: 0));
                    if (picked != null) setState(() => endTime = picked);
                  },
                ),
                if (error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(error!, style: TextStyle(color: Colors.red)),
                  ),
              ],
            ),
      actions: [
        if (widget.docId != null)
          TextButton(
            onPressed: _delete,
            child: Text("Supprimer", style: TextStyle(color: Colors.red)),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text("Annuler"),
        ),
        ElevatedButton(
          onPressed: isLoading ? null : _save,
          child: Text("Enregistrer"),
        ),
      ],
    );
  }
}