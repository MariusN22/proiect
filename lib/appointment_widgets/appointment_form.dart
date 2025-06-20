import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class AppointmentConfirmationScreen extends StatelessWidget {
  final String doctorName;
  final String date;
  final String time;

  const AppointmentConfirmationScreen({
    Key? key,
    required this.doctorName,
    required this.date,
    required this.time,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('success'.tr()),
      ),
      body: Center(
        child: Card(
          margin: const EdgeInsets.all(24),
          elevation: 8,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18)
          ),
          color: t.cardColor,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, size: 60, color: t.colorScheme.primary),
                SizedBox(height: 18),
                Text(
                  'appointment_success'
                      .tr()
                      .replaceAll('{doctor}', doctorName)
                      .replaceAll('{date}', date)
                      .replaceAll('{time}', time),
                  style: t.textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 18),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                  child: Text('ok'.tr()),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
