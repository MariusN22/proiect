import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class AppointmentFilterBar extends StatelessWidget {
  final Function(String?) onTypeChanged;
  final Function(String?) onStatusChanged;

  const AppointmentFilterBar({
    Key? key,
    required this.onTypeChanged,
    required this.onStatusChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          // Tip programare
          Expanded(
            child: DropdownButtonFormField<String>(
              value: null,
              decoration: InputDecoration(
                labelText: 'filter_type'.tr(),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                isDense: true,
              ),
              items: [
                DropdownMenuItem(value: null, child: Text('-')),
                DropdownMenuItem(
                    value: 'consultation_at_office',
                    child: Text('type_consultation_at_office'.tr())),
                DropdownMenuItem(
                    value: 'consultation_online',
                    child: Text('type_consultation_online'.tr())),
                DropdownMenuItem(
                    value: 'checkup',
                    child: Text('type_checkup'.tr())),
              ],
              onChanged: onTypeChanged,
            ),
          ),
          SizedBox(width: 10),
          // Status
          Expanded(
            child: DropdownButtonFormField<String>(
              value: null,
              decoration: InputDecoration(
                labelText: 'filter_status'.tr(),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                isDense: true,
              ),
              items: [
                DropdownMenuItem(value: null, child: Text('-')),
                DropdownMenuItem(
                    value: 'in asteptare', child: Text('status_pending'.tr())),
                DropdownMenuItem(
                    value: 'confirmat', child: Text('status_confirmed'.tr())),
                DropdownMenuItem(
                    value: 'anulat', child: Text('status_cancelled'.tr())),
              ],
              onChanged: onStatusChanged,
            ),
          ),
        ],
      ),
    );
  }
}
