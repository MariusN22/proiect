import 'package:flutter/material.dart';

class Appointment {
  final String id;
  final String doctorId;
  final String doctorName;
  final String patientId;
  final String patientName;
  final String? patientEmail;
  final String? patientPhone;
  final DateTime date;
  final String time;
  final String type;
  final String note;
  final String status;         // "pending", "confirmed", "canceled"
  final String? cancelReason;

  Appointment({
    required this.id,
    required this.doctorId,
    required this.doctorName,
    required this.patientId,
    required this.patientName,
    this.patientEmail,
    this.patientPhone,
    required this.date,
    required this.time,
    required this.type,
    required this.note,
    this.status = "pending",   // default modernizat pentru orice programare nouă
    this.cancelReason,
  });

  /// Din Map (Firebase) către model
  factory Appointment.fromMap(Map<String, dynamic> map) {
    DateTime parsedDate;
    if (map['date'] is DateTime) {
      parsedDate = map['date'];
    } else if (map['date'] is String) {
      parsedDate = DateTime.tryParse(map['date']) ?? DateTime.now();
    } else if (map['date'] != null && map['date'].toString().length >= 10) {
      parsedDate = DateTime.tryParse(map['date'].toString()) ?? DateTime.now();
    } else {
      parsedDate = DateTime.now();
    }

    // Status compatibil: dacă în Firebase ai "in asteptare", îl convertește în "pending"
    String mapStatus = map['status'] ?? "pending";
    if (mapStatus == "in asteptare") mapStatus = "pending";
    if (mapStatus == "confirmata") mapStatus = "confirmed";
    if (mapStatus == "anulata") mapStatus = "canceled";

    return Appointment(
      id: map['id'] ?? "",
      doctorId: map['doctorId'] ?? "",
      doctorName: map['doctorName'] ?? "",
      patientId: map['patientId'] ?? "",
      patientName: map['patientName'] ?? "",
      patientEmail: map['patientEmail'],
      patientPhone: map['patientPhone'],
      date: parsedDate,
      time: map['time'] ?? "",
      type: map['type'] ?? "",
      note: map['note'] ?? "",
      status: mapStatus,
      cancelReason: map['cancelReason'],
    );
  }

  /// Către Map pentru Firebase
  Map<String, dynamic> toMap() {
    // Salvează în Firebase statusul modern ("pending", "confirmed", "canceled")
    return {
      'id': id,
      'doctorId': doctorId,
      'doctorName': doctorName,
      'patientId': patientId,
      'patientName': patientName,
      'patientEmail': patientEmail,
      'patientPhone': patientPhone,
      'date': date.toIso8601String().substring(0, 10), // YYYY-MM-DD
      'time': time,
      'type': type,
      'note': note,
      'status': status,         // direct "pending", "confirmed", "canceled"
      'cancelReason': cancelReason,
    };
  }

  /// Helper pentru status (pictogramă și culoare)
  Color getStatusColor() {
    switch (status) {
      case "confirmed":
        return Colors.green;
      case "canceled":
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  IconData getStatusIcon() {
    switch (status) {
      case "confirmed":
        return Icons.check_circle;
      case "canceled":
        return Icons.cancel;
      default:
        return Icons.hourglass_top;
    }
  }

  String getStatusText(BuildContext context) {
    switch (status) {
      case "confirmed":
        return "Confirmed";
      case "canceled":
        return "Canceled";
      default:
        return "Pending";
    }
  }
}
