import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class TimeSlotsDropdown extends StatelessWidget {
  final String? selectedTime;
  final List<String> times;
  final Function(String?) onChanged;

  const TimeSlotsDropdown({
    Key? key,
    required this.selectedTime,
    required this.times,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: selectedTime,
      items: times
          .map((time) => DropdownMenuItem(
        value: time,
        child: Text(time),
      ))
          .toList(),
      decoration: InputDecoration(
        labelText: 'select_time'.tr(),
        border: OutlineInputBorder(),
      ),
      onChanged: onChanged,
    );
  }
}
