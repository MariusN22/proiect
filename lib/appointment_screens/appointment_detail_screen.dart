import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../appointment_models/appointment.dart';
import '../appointment_services/appointment_service.dart';
import 'appointment_status_chip.dart';

class AppointmentDetailScreen extends StatefulWidget {
  final Appointment appointment;
  final VoidCallback? onStatusChanged;

  const AppointmentDetailScreen({
    Key? key,
    required this.appointment,
    this.onStatusChanged,
  }) : super(key: key);

  @override
  State<AppointmentDetailScreen> createState() => _AppointmentDetailScreenState();
}

class _AppointmentDetailScreenState extends State<AppointmentDetailScreen> {
  bool isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);

    final String status = widget.appointment.status;
    final String patientEmail = widget.appointment.patientEmail ?? "-";
    final String patientPhone = widget.appointment.patientPhone ?? "-";
    final String? cancelReason = widget.appointment.cancelReason;

    return Padding(
      padding: MediaQuery.of(context).viewInsets,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: t.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(Icons.calendar_month, size: 56, color: t.colorScheme.primary),
              const SizedBox(height: 12),
              Text(
                widget.appointment.patientName,
                style: t.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                '${'type_${widget.appointment.type}'.tr()} | ${widget.appointment.time}',
                style: t.textTheme.bodyMedium?.copyWith(color: t.colorScheme.secondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Center(child: AppointmentStatusChip(status: status)),
              const SizedBox(height: 18),
              // Motiv anulare vizibil dacă există și statusul e anulat
              if (status == "anulat" && cancelReason != null && cancelReason.isNotEmpty)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 18),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.red.shade300, width: 1),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.red[800]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "${"Motiv anulare"}: $cancelReason",
                          style: TextStyle(color: Colors.red[800], fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              if (widget.appointment.note.isNotEmpty)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 18),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: t.cardColor,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(
                    '${'note_optional'.tr()}: ${widget.appointment.note}',
                    style: t.textTheme.bodyMedium,
                  ),
                ),
              const Divider(),
              // Info pacient
              Row(
                children: [
                  Icon(Icons.person, color: t.colorScheme.primary),
                  const SizedBox(width: 10),
                  Expanded(child: Text(widget.appointment.patientName, style: t.textTheme.bodyMedium)),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.email, color: t.colorScheme.primary),
                  const SizedBox(width: 10),
                  Expanded(child: Text(patientEmail, style: t.textTheme.bodyMedium)),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.phone, color: t.colorScheme.primary),
                  const SizedBox(width: 10),
                  Expanded(child: Text(patientPhone, style: t.textTheme.bodyMedium)),
                ],
              ),
              const SizedBox(height: 28),
              if (status == "in asteptare" || status == "pending")
                Row(
                  children: [
                    // CONFIRMĂ
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: t.colorScheme.primary,
                          foregroundColor: t.colorScheme.onPrimary,
                          minimumSize: const Size.fromHeight(52),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          textStyle: t.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: 19),
                          elevation: 5,
                        ),
                        icon: isProcessing
                            ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                            : const Icon(Icons.check_circle_outline, size: 28),
                        label: Text('confirm'.tr()),
                        onPressed: isProcessing
                            ? null
                            : () async {
                          setState(() => isProcessing = true);
                          await AppointmentService().updateStatus(
                            widget.appointment.id,
                            "confirmat",
                          );
                          setState(() => isProcessing = false);
                          if (widget.onStatusChanged != null) widget.onStatusChanged!();
                          Navigator.of(context).pop();
                        },
                      ),
                    ),
                    const SizedBox(width: 14),
                    // ANULEAZĂ
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[700],
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(52),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          textStyle: t.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: 19),
                          elevation: 5,
                        ),
                        icon: isProcessing
                            ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                            : const Icon(Icons.cancel, size: 28),
                        label: Text('cancel'.tr()),
                        onPressed: isProcessing
                            ? null
                            : () async {
                          final String? reason = await showDialog<String>(
                            context: context,
                            builder: (ctx) {
                              final controller = TextEditingController();
                              return AlertDialog(
                                title: Text("Motiv anulare"),
                                content: TextField(
                                  controller: controller,
                                  maxLines: 2,
                                  decoration: InputDecoration(
                                    hintText: "Scrie motivul pentru anulare",
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(ctx).pop(),
                                    child: Text("Renunță"),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.of(ctx).pop(controller.text),
                                    child: Text("Trimite"),
                                  ),
                                ],
                              );
                            },
                          );
                          if (reason != null && reason.trim().isNotEmpty) {
                            setState(() => isProcessing = true);
                            await AppointmentService().updateStatus(
                              widget.appointment.id,
                              "anulat",
                              reason: reason,
                            );
                            setState(() => isProcessing = false);
                            if (widget.onStatusChanged != null) widget.onStatusChanged!();
                            Navigator.of(context).pop();
                          }
                        },
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
