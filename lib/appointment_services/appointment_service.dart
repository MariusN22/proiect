import 'package:cloud_firestore/cloud_firestore.dart';
import '../appointment_models/appointment.dart';

class AppointmentService {
  /// Creează programarea și o salvează în Firebase
  Future<bool> createAppointment(Appointment appointment) async {
    try {
      await FirebaseFirestore.instance
          .collection('appointments')
          .add(appointment.toMap());
      print('Programare salvată cu succes!');
      return true;
    } catch (e) {
      print('Eroare la crearea programării: $e');
      return false;
    }
  }

  /// Generează toate sloturile orare posibile între 8:00 și 16:00, la 30 min
  List<String> generateTimeSlots() {
    List<String> slots = [];
    for (int h = 8; h < 16; h++) {
      slots.add('${h.toString().padLeft(2, '0')}:00');
      slots.add('${h.toString().padLeft(2, '0')}:30');
    }
    slots.add('16:00');
    return slots;
  }

  /// Returnează doar sloturile disponibile pentru un medic și o dată
  Future<List<String>> getAvailableTimeSlots(String doctorId, DateTime date) async {
    try {
      final formattedDate = date.toIso8601String().substring(0, 10);
      print('Caut sloturi pentru doctorId=$doctorId, data=$formattedDate');
      final querySnapshot = await FirebaseFirestore.instance
          .collection('appointments')
          .where('doctorId', isEqualTo: doctorId)
          .where('date', isEqualTo: formattedDate)
          .get()
          .timeout(const Duration(seconds: 10));

      List<String> bookedTimes = querySnapshot.docs.map((doc) {
        try {
          final t = doc['time'];
          return t is String ? t : '';
        } catch (e) {
          print('Eroare la conversia slotului: $e');
          return '';
        }
      }).where((s) => s.isNotEmpty).toList();

      List<String> allSlots = generateTimeSlots();
      print('Sloturi ocupate: $bookedTimes');
      print('Toate sloturile posibile: $allSlots');
      final available = allSlots.where((slot) => !bookedTimes.contains(slot)).toList();
      print('Sloturi disponibile: $available');
      return available;
    } catch (e) {
      print('Eroare la citirea sloturilor disponibile: $e');
      return generateTimeSlots();
    }
  }

  /// Obține programările pentru un pacient (după id) - varianta Future
  Future<List<Appointment>> getAppointmentsForPatient(String patientId) async {
    try {
      final docs = await FirebaseFirestore.instance
          .collection('appointments')
          .where('patientId', isEqualTo: patientId)
          .orderBy('date')
          .orderBy('time')
          .get();

      print('Programări găsite pentru pacient $patientId: ${docs.docs.length}');
      return docs.docs
          .map((doc) => Appointment.fromMap(doc.data()..['id'] = doc.id))
          .toList();
    } catch (e) {
      print('Eroare la încărcarea programărilor pacientului: $e');
      return [];
    }
  }

  /// Stream: programările pentru pacient (update instant în UI)
  Stream<List<Appointment>> watchAppointmentsForPatient(String patientId) {
    return FirebaseFirestore.instance
        .collection('appointments')
        .where('patientId', isEqualTo: patientId)
        .orderBy('date')
        .orderBy('time')
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => Appointment.fromMap(doc.data()..['id'] = doc.id))
        .toList());
  }

  /// Șterge o programare după id
  Future<void> deleteAppointment(String appointmentId) async {
    try {
      await FirebaseFirestore.instance
          .collection('appointments')
          .doc(appointmentId)
          .delete();
      print('Programare $appointmentId ștearsă!');
    } catch (e) {
      print('Eroare la ștergerea programării: $e');
    }
  }

  /// Obține toate programările pentru un medic (status, calendar/filtru) - Future
  Future<List<Appointment>> getAppointmentsForMedic(String medicId) async {
    try {
      final docs = await FirebaseFirestore.instance
          .collection('appointments')
          .where('doctorId', isEqualTo: medicId)
          .orderBy('date')
          .orderBy('time')
          .get();

      print('Programări găsite pentru medic $medicId: ${docs.docs.length}');
      return docs.docs
          .map((doc) => Appointment.fromMap(doc.data()..['id'] = doc.id))
          .toList();
    } catch (e) {
      print('Eroare la încărcarea programărilor medicului: $e');
      return [];
    }
  }

  /// Stream: programările pentru medic (update instant în UI)
  Stream<List<Appointment>> watchAppointmentsForMedic(String medicId) {
    return FirebaseFirestore.instance
        .collection('appointments')
        .where('doctorId', isEqualTo: medicId)
        .orderBy('date')
        .orderBy('time')
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => Appointment.fromMap(doc.data()..['id'] = doc.id))
        .toList());
  }

  /// Actualizează statusul unei programări
  Future<void> updateStatus(String appointmentId, String newStatus, {String? reason}) async {
    try {
      final data = {
        'status': newStatus,
      };
      if (reason != null && reason.trim().isNotEmpty) {
        data['cancelReason'] = reason;
      }
      await FirebaseFirestore.instance.collection('appointments').doc(appointmentId).update(data);
      print('Status programare $appointmentId actualizat la $newStatus');
      if (reason != null) {
        print('Motiv anulare: $reason');
      }
    } catch (e) {
      print('Eroare la actualizarea statusului programării: $e');
    }
  }

}
