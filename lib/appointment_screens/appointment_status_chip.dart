import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class AppointmentStatusChip extends StatelessWidget {
  final String status;
  const AppointmentStatusChip({Key? key, required this.status}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);

    Color chipColor;
    String statusKey;
    switch (status.toLowerCase()) {
      case 'confirmat':
      case 'confirmed':
        chipColor = Colors.green[700]!;
        statusKey = 'status_confirmed';
        break;
      case 'anulat':
      case 'cancelled':
        chipColor = Colors.red[600]!;
        statusKey = 'status_cancelled';
        break;
      default:
        chipColor = Colors.amber[700]!;
        statusKey = 'status_pending';
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      margin: EdgeInsets.only(top: 6),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.18),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: chipColor, width: 1),
      ),
      child: Text(
        statusKey.tr(),
        style: t.textTheme.bodySmall!.copyWith(
          color: chipColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
