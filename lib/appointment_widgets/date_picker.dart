import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class DatePickerField extends StatelessWidget {
  final DateTime? selectedDate;
  final Function(DateTime?) onDateSelected;

  const DatePickerField({
    Key? key,
    required this.selectedDate,
    required this.onDateSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return InputDecorator(
      decoration: InputDecoration(
        labelText: 'select_date'.tr(),
        border: OutlineInputBorder(),
      ),
      child: InkWell(
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: selectedDate ?? DateTime.now(),
            firstDate: DateTime.now(),
            lastDate: DateTime.now().add(Duration(days: 30)),
          );
          onDateSelected(picked);
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
    );
  }
}
