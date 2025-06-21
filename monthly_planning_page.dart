import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MonthlyPlanningPage extends StatefulWidget {
  @override
  _MonthlyPlanningPageState createState() => _MonthlyPlanningPageState();
}

class _MonthlyPlanningPageState extends State<MonthlyPlanningPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  Map<DateTime, List<Reservation>> _reservationsByDay = {};

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _fetchReservationsForMonth(_focusedDay);
  }

  Future<void> _fetchReservationsForMonth(DateTime month) async {
    final monthStart = DateTime(month.year, month.month, 1);
    final monthEnd = DateTime(month.year, month.month + 1, 0, 23, 59, 59);

    final snapshot = await FirebaseFirestore.instance
        .collection('reservations')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(monthStart))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(monthEnd))
        .get();

    final items = snapshot.docs
        .map((doc) => Reservation.fromFirestore(doc))
        .toList();

    final map = <DateTime, List<Reservation>>{};
    for (final res in items) {
      final key = DateTime(res.date.year, res.date.month, res.date.day);
      map.putIfAbsent(key, () => []).add(res);
    }
    setState(() {
      _reservationsByDay = map;
    });
  }

  List<Reservation> _getReservationsForDay(DateTime day) {
    final key = DateTime(day.year, day.month, day.day);
    final reservations = _reservationsByDay[key] ?? [];
    reservations.sort((a, b) => a.reservationId.compareTo(b.reservationId));
    return reservations;
  }

  Future<int> _getNextReservationId() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('reservations')
        .orderBy('reservationId', descending: true)
        .limit(1)
        .get();
    if (snapshot.docs.isNotEmpty) {
      final data = snapshot.docs.first.data();
      if (data['reservationId'] != null) {
        return (data['reservationId'] as int) + 1;
      }
    }
    return 1;
  }

  void _showAddReservationDialog(DateTime day) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selected = DateTime(day.year, day.month, day.day);
    if (selected.isBefore(today)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("You cannot make a reservation in the past.")),
      );
      return;
    }
    final nextId = await _getNextReservationId();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom),
        child: AddReservationDialog(
          selectedDay: day,
          nextReservationId: nextId,
        ),
      ),
    ).then((value) {
      if (value == true) {
        _fetchReservationsForMonth(_focusedDay);
      }
    });
  }

  Widget _buildEventsMarker(DateTime date, List<dynamic> events) {
    if (events.isEmpty) return SizedBox.shrink();
    return Positioned(
      right: 1,
      bottom: 1,
      child: Container(
        width: 7,
        height: 7,
        decoration: BoxDecoration(
          color: Colors.blueAccent,
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final reservationsForSelectedDay =
        _selectedDay == null ? [] : _getReservationsForDay(_selectedDay!);

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selected = _selectedDay == null
        ? today
        : DateTime(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day);
    final isPast = selected.isBefore(today);

    return Scaffold(
      appBar: AppBar(title: Text('Monthly Planning')),
      body: Column(
        children: [
          TableCalendar<Reservation>(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            eventLoader: (day) => _getReservationsForDay(day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
              _fetchReservationsForMonth(focusedDay);
            },
            headerStyle: HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
            ),
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: Colors.blue[100],
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
              markersMaxCount: 1,
              markersAlignment: Alignment.bottomRight,
              markerDecoration: BoxDecoration(
                color: Colors.blueAccent,
                shape: BoxShape.circle,
              ),
            ),
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, date, events) =>
                  _buildEventsMarker(date, events),
            ),
          ),
          const SizedBox(height: 16),
          if (_selectedDay != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Reservations for ${_selectedDay!.day}/${_selectedDay!.month}/${_selectedDay!.year}",
                  style: TextStyle(fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton.icon(
                  icon: Icon(Icons.add, color: Theme.of(context).colorScheme.primary),
                  label: Text(
                    "Make Reservation",
                    style: TextStyle(color: Theme.of(context).colorScheme.primary),
                  ),
                  onPressed: isPast
                      ? null
                      : () => _showAddReservationDialog(_selectedDay!),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Theme.of(context).colorScheme.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: reservationsForSelectedDay.isEmpty
                  ? const Center(child: Text("No reservations for this day."))
                  : ListView.builder(
                      itemCount: reservationsForSelectedDay.length,
                      itemBuilder: (context, index) {
                        final res = reservationsForSelectedDay[index];
                        return Card(
                          child: ListTile(
                            leading: CircleAvatar(
                              child: Text('${res.reservationId}'),
                            ),
                            title: Text(res.userName.isNotEmpty
                                ? res.userName
                                : res.userId),
                            subtitle: Text(
                                "${_formatTime(res.start)} - ${_formatTime(res.end)}"),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(String timeStr) {
    if (timeStr.isEmpty) return "--h--";
    final parts = timeStr.split(":");
    if (parts.length != 2) return timeStr;
    return "${int.parse(parts[0])}h${parts[1].padLeft(2, '0')}";
  }
}

class Reservation {
  final String id;
  final int reservationId;
  final DateTime date;
  final String start;
  final String end;
  final String userId;
  final String userName;

  Reservation({
    required this.id,
    required this.reservationId,
    required this.date,
    required this.start,
    required this.end,
    required this.userId,
    required this.userName,
  });

  factory Reservation.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Reservation(
      id: doc.id,
      reservationId: (data['reservationId'] ?? 0) is int
          ? data['reservationId']
          : int.tryParse(data['reservationId']?.toString() ?? '0') ?? 0,
      date: (data['date'] as Timestamp).toDate(),
      start: data['start'] ?? "",
      end: data['end'] ?? "",
      userId: data['userId'] ?? "",
      userName: data['userName'] ?? "",
    );
  }
}

class AddReservationDialog extends StatefulWidget {
  final DateTime selectedDay;
  final int nextReservationId;
  AddReservationDialog({required this.selectedDay, required this.nextReservationId});

  @override
  State<AddReservationDialog> createState() => _AddReservationDialogState();
}

class _AddReservationDialogState extends State<AddReservationDialog> {
  TimeOfDay? _start;
  TimeOfDay? _end;
  bool _loading = false;

  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Wrap(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Text("Make a Reservation", style: Theme.of(context).textTheme.titleLarge)),
              const SizedBox(height: 10),
              Center(child: Text("Reservation ID: ${widget.nextReservationId}")),
              const SizedBox(height: 10),
              Text(
                "Date: ${widget.selectedDay.day}/${widget.selectedDay.month}/${widget.selectedDay.year}",
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 20),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    ListTile(
                      title: Text("Start Time"),
                      trailing: Text(_start != null
                          ? _start!.format(context)
                          : "--:--"),
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay(hour: 8, minute: 0),
                        );
                        if (picked != null) setState(() => _start = picked);
                      },
                    ),
                    ListTile(
                      title: Text("End Time"),
                      trailing: Text(_end != null
                          ? _end!.format(context)
                          : "--:--"),
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay(hour: 14, minute: 0),
                        );
                        if (picked != null) setState(() => _end = picked);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    child: Text("Cancel"),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    child: _loading ? SizedBox(width:20,height:20,child:CircularProgressIndicator(strokeWidth:2)) : Text("Save"),
                    onPressed: (_start != null && _end != null && !_loading)
                        ? () async {
                            setState(() => _loading = true);
                            final user = FirebaseAuth.instance.currentUser;
                            if (user == null) return;
                            await FirebaseFirestore.instance.collection('reservations').add({
                              'reservationId': widget.nextReservationId,
                              'userId': user.uid,
                              'userName': user.displayName ?? "",
                              'date': Timestamp.fromDate(widget.selectedDay),
                              'start': "${_start!.hour.toString().padLeft(2, "0")}:${_start!.minute.toString().padLeft(2, "0")}",
                              'end': "${_end!.hour.toString().padLeft(2, "0")}:${_end!.minute.toString().padLeft(2, "0")}",
                              'terminee': false,
                            });
                            Navigator.pop(context, true);
                          }
                        : null,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}