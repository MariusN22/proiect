import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../appointment_services/doctor_service.dart';
import '../appointment_services/appointment_service.dart';
import '../appointment_models/doctor.dart';
import '../appointment_models/appointment.dart';
import 'package:easy_localization/easy_localization.dart';
import 'my_appointments_popup.dart'; // Asigură-te că importi varianta bună

class AppointmentBookingScreen extends StatefulWidget {
  @override
  State<AppointmentBookingScreen> createState() => _AppointmentBookingScreenState();
}

class _AppointmentBookingScreenState extends State<AppointmentBookingScreen> {
  Doctor? selectedDoctor;
  DateTime? selectedDate;
  String? selectedTime;
  String? type;
  TextEditingController noteController = TextEditingController();

  bool isLoading = false;
  List<Doctor> doctors = [];
  List<String> times = [];

  @override
  void initState() {
    super.initState();
    loadDoctors();
    type = 'consultation_at_office'; // default key (pentru localizare)
  }

  void loadDoctors() async {
    setState(() => isLoading = true);
    var list = await DoctorService().getVerifiedDoctors();
    setState(() {
      doctors = list;
      isLoading = false;
      if (doctors.isEmpty) {
        selectedDoctor = null;
      }
    });
    print('Doctori încărcați: $doctors');
  }

  void loadTimes() async {
    if (selectedDoctor == null || selectedDate == null) {
      setState(() => times = []);
      return;
    }
    setState(() => isLoading = true);
    print('Incarc sloturi pentru doctor=${selectedDoctor?.id}, data=${selectedDate?.toIso8601String()}');
    final slots = await AppointmentService().getAvailableTimeSlots(selectedDoctor!.id, selectedDate!);
    setState(() {
      times = slots;
      isLoading = false;
      if (times.isEmpty) {
        selectedTime = null;
      }
    });
    print('Sloturi returnate: $times');
  }

  void submitAppointment() async {
    if (selectedDoctor == null || selectedDate == null || selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('error_fill_all'.tr()),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    setState(() => isLoading = true);

    // IA DATELE REALE ALE PACIENTULUI LOGAT
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Eroare: Nu ești autentificat!')),
      );
      return;
    }
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .get();
    final userData = userDoc.data() ?? {};

    final String patientId = currentUser.uid;
    final String patientName = ((userData['nume'] ?? '') + ' ' + (userData['prenume'] ?? '')).trim();
    final String? patientEmail = userData['email'] ?? '';
    final String? patientPhone = userData['telefon'] ?? '';

    var appointment = Appointment(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      doctorId: selectedDoctor!.id,
      doctorName: selectedDoctor!.name,
      patientId: patientId,
      patientName: patientName,
      patientEmail: patientEmail,
      patientPhone: patientPhone,
      date: selectedDate!,
      time: selectedTime!,
      type: type ?? '',
      note: noteController.text,
    );

    var ok = await AppointmentService().createAppointment(appointment);
    setState(() => isLoading = false);
    if (ok) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Text("success".tr(),
              style: TextStyle(color: Theme.of(context).colorScheme.primary)),
          content: Text(
            'appointment_success'
                .tr()
                .replaceAll('{doctor}', appointment.doctorName)
                .replaceAll('{date}', appointment.date.toString().substring(0, 10))
                .replaceAll('{time}', appointment.time),
          ),
          actions: [
            TextButton(
              child: Text("ok".tr()),
              onPressed: () => Navigator.of(context).pop(),
            )
          ],
        ),
      );
      setState(() {
        selectedDoctor = null;
        selectedDate = null;
        selectedTime = null;
        type = 'consultation_at_office';
        noteController.clear();
        times = [];
      });
    }
  }

  void showMyAppointmentsPopup() {
    // IA patientId din user curent, nu din demo
    final currentUser = FirebaseAuth.instance.currentUser;
    final String patientId = currentUser?.uid ?? "";
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => MyAppointmentsPopup(
        patientId: patientId,
        onDelete: (id) async {
          await AppointmentService().deleteAppointment(id);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var t = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('make_appointment'.tr()),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: isLoading
            ? Center(child: CircularProgressIndicator())
            : ListView(
          children: [
            // Doctor dropdown
            DropdownButtonFormField<Doctor>(
              value: selectedDoctor,
              items: doctors.isNotEmpty
                  ? doctors
                  .map((d) => DropdownMenuItem(
                value: d,
                child: Text("${d.name} – ${d.specialty}"),
              ))
                  .toList()
                  : [
                DropdownMenuItem(
                  value: null,
                  enabled: false,
                  child: Text('no_doctors'.tr()),
                ),
              ],
              decoration: InputDecoration(
                labelText: 'select_doctor'.tr(),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
              ),
              onChanged: doctors.isNotEmpty
                  ? (d) {
                setState(() {
                  selectedDoctor = d;
                  selectedTime = null;
                });
                loadTimes();
              }
                  : null,
            ),
            SizedBox(height: 16),
            // Date picker
            InputDecorator(
              decoration: InputDecoration(
                labelText: 'select_date'.tr(),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
              ),
              child: InkWell(
                onTap: doctors.isEmpty
                    ? null
                    : () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate ?? DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(Duration(days: 30)),
                  );
                  if (picked != null) {
                    setState(() {
                      selectedDate = picked;
                      selectedTime = null;
                    });
                    loadTimes();
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    selectedDate == null
                        ? 'select_date'.tr()
                        : selectedDate!.toString().substring(0, 10),
                    style: t.textTheme.bodyLarge,
                  ),
                ),
              ),
            ),
            SizedBox(height: 16),
            // Time slot picker
            DropdownButtonFormField<String>(
              value: selectedTime,
              items: times.isNotEmpty
                  ? times
                  .map((time) => DropdownMenuItem(
                value: time,
                child: Text(time),
              ))
                  .toList()
                  : [
                DropdownMenuItem(
                  value: null,
                  enabled: false,
                  child: Text('no_times'.tr()),
                ),
              ],
              decoration: InputDecoration(
                labelText: 'select_time'.tr(),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
              ),
              onChanged: times.isNotEmpty
                  ? (t) => setState(() => selectedTime = t)
                  : null,
            ),
            if (doctors.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  'no_doctors'.tr(),
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
              ),
            if (selectedDoctor != null &&
                selectedDate != null &&
                times.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  'no_times'.tr(),
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
              ),
            SizedBox(height: 16),
            // Type of consultation (tradus din chei, nu stringuri)
            DropdownButtonFormField<String>(
              value: type,
              items: [
                'consultation_at_office',
                'consultation_online',
                'checkup',
              ]
                  .map((key) => DropdownMenuItem(value: key, child: Text(key.tr())))
                  .toList(),
              decoration: InputDecoration(
                labelText: 'type_consultation'.tr(),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
              ),
              onChanged: (t) => setState(() => type = t),
            ),
            SizedBox(height: 16),
            // Note (optional)
            TextFormField(
              controller: noteController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'note_optional'.tr(),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
              ),
            ),
            SizedBox(height: 24),
            // Submit button
            ElevatedButton.icon(
              icon: Icon(Icons.check_circle_outline),
              style: ElevatedButton.styleFrom(
                minimumSize: Size.fromHeight(48),
                backgroundColor: t.colorScheme.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              ),
              label: Text('confirm'.tr(),
                  style: t.textTheme.titleMedium!
                      .copyWith(color: t.colorScheme.onPrimary)),
              onPressed: (selectedDoctor == null ||
                  selectedDate == null ||
                  selectedTime == null ||
                  isLoading)
                  ? null
                  : submitAppointment,
            ),
            SizedBox(height: 12),
            // **Buton vezi lista programări**
            OutlinedButton.icon(
              icon: Icon(Icons.list_alt),
              style: OutlinedButton.styleFrom(
                minimumSize: Size.fromHeight(44),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                side: BorderSide(color: t.colorScheme.primary, width: 2),
              ),
              label: Text('view_appointments_list'.tr()),
              onPressed: showMyAppointmentsPopup,
            ),
          ],
        ),
      ),
    );
  }
}
