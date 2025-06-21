import 'package:cloud_firestore/cloud_firestore.dart';

class Reservation {
  final String id;
  final DateTime date;
  final String start;
  final String end;
  final String userId;
  final String userName;
  final bool terminee;

  Reservation({
    required this.id,
    required this.date,
    required this.start,
    required this.end,
    required this.userId,
    required this.userName,
    required this.terminee,
  });

  factory Reservation.fromFirestore(String id, Map<String, dynamic> data) {
    return Reservation(
      id: id,
      date: (data['date'] as Timestamp).toDate(),
      start: data['start'] ?? "",
      end: data['end'] ?? "",
      userId: data['userId'] ?? "",
      userName: data['userName'] ?? "",
      terminee: data['terminee'] ?? false,
    );
  }
}