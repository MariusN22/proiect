import 'package:flutter/material.dart';
import '../appointment_models/doctor.dart';
import 'package:easy_localization/easy_localization.dart';

class DoctorDropdown extends StatelessWidget {
  final List<Doctor> doctors;
  final Doctor? selectedDoctor;
  final Function(Doctor?) onChanged;

  const DoctorDropdown({
    Key? key,
    required this.doctors,
    required this.selectedDoctor,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<Doctor>(
      value: selectedDoctor,
      items: doctors
          .map((d) => DropdownMenuItem(
        value: d,
        child: Text("${d.name} – ${d.specialty}"),
      ))
          .toList(),
      decoration: InputDecoration(
        labelText: 'select_doctor'.tr(),
        border: OutlineInputBorder(),
      ),
      onChanged: onChanged,
    );
  }
}
