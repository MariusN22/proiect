import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../appointment_models/appointment.dart';
import '../appointment_services/appointment_service.dart';

class MyAppointmentsPopup extends StatelessWidget {
  final String patientId;
  final Future<void> Function(String id) onDelete;

  const MyAppointmentsPopup({
    Key? key,
    required this.patientId,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Padding(
      padding: MediaQuery.of(context).viewInsets,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: t.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.list_alt, size: 38, color: t.colorScheme.primary),
            Text('my_appointments'.tr(), style: t.textTheme.titleMedium),
            const SizedBox(height: 8),
            // StreamBuilder pentru lista de programări
            StreamBuilder<List<Appointment>>(
              stream: AppointmentService().watchAppointmentsForPatient(patientId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 30),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snapshot.hasError) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 30),
                    child: Text('Eroare la încărcarea programărilor'),
                  );
                }
                final appointments = snapshot.data ?? [];
                if (appointments.isEmpty) {
                  return Text('no_appointments'.tr());
                }
                return ListView.separated(
                  shrinkWrap: true,
                  itemCount: appointments.length,
                  separatorBuilder: (_, __) => Divider(),
                  itemBuilder: (ctx, i) {
                    final appt = appointments[i];
                    // ---------------- NOU ---------------------
                    Color statusColor;
                    IconData statusIcon;
                    String statusText;
                    switch (appt.status) {
                      case 'confirmat':
                        statusColor = Colors.green;
                        statusIcon = Icons.check_circle;
                        statusText = "Confirmed";
                        break;
                      case 'anulat':
                        statusColor = Colors.red;
                        statusIcon = Icons.cancel;
                        statusText = "Canceled";
                        break;
                      default:
                        statusColor = Colors.amber[700]!;
                        statusIcon = Icons.hourglass_empty;
                        statusText = "Pending";
                    }

                    return ListTile(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      tileColor: t.cardColor,
                      // ORA ÎN DREPTUNGHI, NU CERC
                      leading: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: t.colorScheme.primary.withOpacity(0.13),
                          borderRadius: BorderRadius.circular(9),
                          border: Border.all(color: t.colorScheme.primary, width: 1.5),
                        ),
                        child: Text(
                          appt.time,
                          style: TextStyle(
                              color: t.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 16
                          ),
                        ),
                      ),
                      // DOCTOR și TIP, SUB ORA
                      title: Text(appt.doctorName, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${appt.date.toString().substring(0, 10)} – ${'type_${appt.type}'.tr()}'),
                          Row(
                            children: [
                              Icon(Icons.email, size: 16, color: t.colorScheme.primary),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  appt.patientEmail ?? "-",
                                  style: const TextStyle(fontSize: 13),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Icon(Icons.phone, size: 16, color: t.colorScheme.primary),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  appt.patientPhone ?? "-",
                                  style: const TextStyle(fontSize: 13),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          if (appt.status == "anulat" && (appt.cancelReason?.isNotEmpty ?? false))
                            Padding(
                              padding: const EdgeInsets.only(top: 3),
                              child: Row(
                                children: [
                                  Icon(Icons.info_outline, color: Colors.red[700], size: 18),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      appt.cancelReason!,
                                      style: TextStyle(
                                          color: Colors.red[800],
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      // STATUS VIZUAL: bifa, X sau ceas
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(statusIcon, color: statusColor, size: 28),
                          const SizedBox(height: 2),
                          Text(
                            statusText,
                            style: TextStyle(
                                color: statusColor, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ],
                      ),
                      onTap: () {
                        // Opțional: Poți deschide detalii aici, gen AppointmentDetailScreen
                      },
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
