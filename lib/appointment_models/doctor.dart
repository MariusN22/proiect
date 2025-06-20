class Doctor {
  final String id;
  final String name;
  final String specialty;
  final bool isVerified;

  Doctor({
    required this.id,
    required this.name,
    required this.specialty,
    required this.isVerified,
  });

  // Exemplu de factory pentru integrare cu backend (ex: Firebase)
  factory Doctor.fromMap(Map<String, dynamic> map) {
    return Doctor(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      specialty: map['specialty'] ?? '',
      isVerified: map['isVerified'] ?? false,
    );
  }
}
