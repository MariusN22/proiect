import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../appointment_services/appointment_service.dart';
import '../appointment_models/appointment.dart';
import 'appointment_status_chip.dart';
// import 'appointment_filter_bar.dart'; // <-- eliminat!
import 'appointment_detail_screen.dart';

class MedicAppointmentsScreen extends StatefulWidget {
  @override
  State<MedicAppointmentsScreen> createState() => _MedicAppointmentsScreenState();
}

class _MedicAppointmentsScreenState extends State<MedicAppointmentsScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  List<Appointment> appointments = [];
  List<Appointment> filteredAppointments = [];
  String? medicId;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    medicId = FirebaseAuth.instance.currentUser?.uid;
  }

  void _filterAppointments(List<Appointment> allAppointments) {
    setState(() {
      appointments = allAppointments;
      filteredAppointments = appointments.where((appt) {
        final apptDate = DateTime(appt.date.year, appt.date.month, appt.date.day);
        bool sameDay = _selectedDay == null ||
            (apptDate.year == _selectedDay!.year &&
                apptDate.month == _selectedDay!.month &&
                apptDate.day == _selectedDay!.day);
        return sameDay;
      }).toList();
    });
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay, List<Appointment> allAppointments) {
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
    });
    _filterAppointments(allAppointments);
  }

  void _onAppointmentTap(Appointment appt, List<Appointment> allAppointments) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => AppointmentDetailScreen(
        appointment: appt,
        onStatusChanged: () {
          _filterAppointments(allAppointments);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);

    if (medicId == null) {
      return Scaffold(
        appBar: AppBar(title: Text('appointments_calendar'.tr())),
        body: Center(child: Text('Eroare: Nu ești autentificat ca medic!')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('appointments_calendar'.tr()),
      ),
      body: StreamBuilder<List<Appointment>>(
        stream: AppointmentService().watchAppointmentsForMedic(medicId!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Eroare la încărcarea programărilor: ${snapshot.error}',
                style: t.textTheme.bodyLarge?.copyWith(color: t.colorScheme.error),
              ),
            );
          }
          final allAppointments = snapshot.data ?? [];
          appointments = allAppointments;
          filteredAppointments = appointments.where((appt) {
            final apptDate = DateTime(appt.date.year, appt.date.month, appt.date.day);
            bool sameDay = _selectedDay == null ||
                (apptDate.year == _selectedDay!.year &&
                    apptDate.month == _selectedDay!.month &&
                    apptDate.day == _selectedDay!.day);
            return sameDay;
          }).toList();

          return ListView(
            padding: const EdgeInsets.all(18),
            children: [
              // Calendar în card modern cu colțuri mari și shadow
              Container(
                margin: const EdgeInsets.only(bottom: 18),
                decoration: BoxDecoration(
                  color: t.cardColor,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: t.shadowColor.withOpacity(0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 12),
                  child: TableCalendar(
                    locale: context.locale.languageCode,
                    firstDay: DateTime(DateTime.now().year - 1, 1, 1),
                    lastDay: DateTime(DateTime.now().year + 1, 12, 31),
                    focusedDay: _focusedDay,
                    selectedDayPredicate: (day) =>
                    _selectedDay != null &&
                        day.year == _selectedDay!.year &&
                        day.month == _selectedDay!.month &&
                        day.day == _selectedDay!.day,
                    calendarFormat: CalendarFormat.month,
                    onDaySelected: (selectedDay, focusedDay) =>
                        _onDaySelected(selectedDay, focusedDay, allAppointments),
                    calendarStyle: CalendarStyle(
                      todayDecoration: BoxDecoration(
                        color: t.colorScheme.secondary.withOpacity(0.18),
                        shape: BoxShape.circle,
                      ),
                      selectedDecoration: BoxDecoration(
                        color: t.colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      markerDecoration: BoxDecoration(
                        color: t.colorScheme.secondary,
                        shape: BoxShape.circle,
                      ),
                      weekendTextStyle: t.textTheme.bodyLarge!.copyWith(color: t.colorScheme.secondary),
                    ),
                    headerStyle: HeaderStyle(
                      titleCentered: true,
                      formatButtonVisible: false,
                      titleTextStyle: t.textTheme.titleLarge!,
                      leftChevronIcon: Icon(Icons.chevron_left, color: t.colorScheme.primary),
                      rightChevronIcon: Icon(Icons.chevron_right, color: t.colorScheme.primary),
                      decoration: BoxDecoration(
                        color: t.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    eventLoader: (day) => allAppointments
                        .where((a) =>
                    a.date.year == day.year &&
                        a.date.month == day.month &&
                        a.date.day == day.day)
                        .toList(),
                  ),
                ),
              ),
              // FILTRELE AU FOST ELIMINATE
              const SizedBox(height: 8),
              filteredAppointments.isEmpty
                  ? Padding(
                padding: const EdgeInsets.symmetric(vertical: 60),
                child: Center(
                  child: Text(
                    'no_appointments_today'.tr(),
                    style: t.textTheme.bodyLarge?.copyWith(color: t.colorScheme.onSurfaceVariant),
                  ),
                ),
              )
                  : ListView.separated(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: filteredAppointments.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (ctx, i) {
                  final appt = filteredAppointments[i];
                  return Material(
                    elevation: 4,
                    borderRadius: BorderRadius.circular(18),
                    color: t.cardColor,
                    child: ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      tileColor: t.cardColor,
                      // --- ORA ÎN DREPTUNGHI, NU BULĂ ---
                      leading: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: t.colorScheme.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          appt.time,
                          style: TextStyle(
                            color: t.colorScheme.onPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      // --- NUMELE PACIENTULUI ---
                      title: Text(appt.patientName, style: t.textTheme.titleMedium),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('type_${appt.type}'.tr()),
                          AppointmentStatusChip(status: appt.status),
                          // Afișează email și telefon DOAR dacă există
                          if ((appt.patientEmail ?? '').isNotEmpty)
                            Text(appt.patientEmail!, style: t.textTheme.bodySmall),
                          if ((appt.patientPhone ?? '').isNotEmpty)
                            Text(appt.patientPhone!, style: t.textTheme.bodySmall),
                        ],
                      ),
                      onTap: () => _onAppointmentTap(appt, allAppointments),
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
