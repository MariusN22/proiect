import 'package:cloud_firestore/cloud_firestore.dart';
import '../appointment_models/doctor.dart';

class DoctorService {
  Future<List<Doctor>> getVerifiedDoctors() async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('rol', isEqualTo: 'medic')   // <-- modificat
        .where('status', isEqualTo: 'aprobat') // <-- modificat
        .get();

    return querySnapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      // Adaptează și la numele câmpurilor tale (nume, prenume, specializare etc)
      return Doctor(
        id: data['id'],
        name: (data['nume'] ?? '') + ' ' + (data['prenume'] ?? ''),
        specialty: data['specializare'] ?? '',
        isVerified: true, // forțăm true, dacă apare în listă înseamnă că e aprobat
      );
    }).toList();
  }
}
