import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';

class CalendarAlarmScreen extends StatefulWidget {
  final String pacientId;
  final String nume;
  final String prenume;

  const CalendarAlarmScreen({
    required this.pacientId,
    required this.nume,
    required this.prenume,
    Key? key,
  }) : super(key: key);

  @override
  State<CalendarAlarmScreen> createState() => _CalendarAlarmScreenState();
}

class _CalendarAlarmScreenState extends State<CalendarAlarmScreen> {
  DateTime _selectedDay = DateTime.now();

  void _showAddAlarmBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AlarmAddSheet(
        pacientId: widget.pacientId,
        initialDate: _selectedDay,
      ),
    );
  }

  void _showEditAlarmBottomSheet(
      BuildContext context, DocumentSnapshot alarmDoc, Map<String, dynamic> data) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AlarmAddSheet(
        pacientId: widget.pacientId,
        initialDate: (data['date'] as Timestamp).toDate(),
        isEdit: true,
        alarmDoc: alarmDoc,
        initialTitle: data['title'] ?? '',
        initialDetails: data['details'] ?? '',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeGreen = const Color(0xFF217A6B);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.nume} ${widget.prenume}"),
        backgroundColor: themeGreen,
      ),
      backgroundColor: isDark ? const Color(0xFF18191B) : const Color(0xFFEFF6F4),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
            child: Container(
              decoration: BoxDecoration(
                color: themeGreen,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: themeGreen.withOpacity(0.17),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: TableCalendar(
                  locale: context.locale.languageCode,
                  firstDay: DateTime.now().subtract(const Duration(days: 365)),
                  lastDay: DateTime.now().add(const Duration(days: 365)),
                  focusedDay: _selectedDay,
                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                  onDaySelected: (selected, _) {
                    setState(() => _selectedDay = selected);
                  },
                  calendarStyle: CalendarStyle(
                    todayDecoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18), shape: BoxShape.circle),
                    selectedDecoration: BoxDecoration(
                        color: Colors.white, shape: BoxShape.circle),
                    selectedTextStyle: TextStyle(color: themeGreen, fontWeight: FontWeight.bold),
                    todayTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    weekendTextStyle: TextStyle(color: Colors.yellow[200]),
                    defaultTextStyle: const TextStyle(color: Colors.white),
                    outsideTextStyle: const TextStyle(color: Colors.white24),
                  ),
                  headerStyle: HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                    titleTextStyle: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22),
                    leftChevronIcon: const Icon(Icons.chevron_left, color: Colors.white),
                    rightChevronIcon: const Icon(Icons.chevron_right, color: Colors.white),
                  ),
                  daysOfWeekStyle: const DaysOfWeekStyle(
                    weekdayStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                    weekendStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Expanded(
            child: AlarmListForDay(
              pacientId: widget.pacientId,
              date: _selectedDay,
              onEdit: _showEditAlarmBottomSheet,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddAlarmBottomSheet,
        backgroundColor: themeGreen,
        child: const Icon(Icons.add, color: Colors.white, size: 28),
        tooltip: "add_alarm".tr(),
      ),
    );
  }
}

// ------------------ LISTA ALARME -------------------
class AlarmListForDay extends StatelessWidget {
  final String pacientId;
  final DateTime date;
  final Function(BuildContext, DocumentSnapshot, Map<String, dynamic>) onEdit;

  const AlarmListForDay({
    required this.pacientId,
    required this.date,
    required this.onEdit,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    final themeGreen = const Color(0xFF217A6B);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(pacientId)
          .collection('alarms')
          .where('date', isGreaterThanOrEqualTo: start, isLessThan: end)
          .orderBy('date')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final alarms = snapshot.data!.docs;
        if (alarms.isEmpty) {
          return Center(
              child: Text("no_alarms".tr(),
                  style: TextStyle(
                      color: isDark ? Colors.white70 : themeGreen,
                      fontWeight: FontWeight.bold,
                      fontSize: 17)));
        }
        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          itemCount: alarms.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, i) {
            final data = alarms[i].data() as Map<String, dynamic>;
            final dt = (data['date'] as Timestamp).toDate();
            final hour = dt.hour.toString().padLeft(2, '0');
            final minute = dt.minute.toString().padLeft(2, '0');
            final createdBy = data['createdBy'] ?? 'pacient';

            return Container(
              decoration: BoxDecoration(
                color: createdBy == 'medic'
                    ? Colors.red.withOpacity(0.13)
                    : (isDark ? const Color(0xFF232323) : Colors.white),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: themeGreen.withOpacity(0.09),
                    blurRadius: 7,
                    offset: const Offset(0, 2),
                  )
                ],
                border: createdBy == 'medic'
                    ? Border.all(color: Colors.red, width: 2)
                    : null,
              ),
              child: ListTile(
                leading: Icon(
                  createdBy == 'medic' ? Icons.medical_services : Icons.person,
                  color: createdBy == 'medic' ? Colors.red : themeGreen,
                  size: 32,
                ),
                title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        data['title'] ?? '',
                        style: TextStyle(
                            color: isDark ? Colors.white : themeGreen,
                            fontWeight: FontWeight.bold,
                            fontSize: 17),
                      ),
                    ),
                    if (createdBy == 'medic')
                      Padding(
                        padding: const EdgeInsets.only(left: 4.0),
                        child: Text(
                          "de la medic",
                          style: TextStyle(
                            color: Colors.red[600],
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.only(left: 4.0),
                        child: Text(
                          "personală",
                          style: TextStyle(
                            color: themeGreen,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                  ],
                ),
                subtitle: Text(
                  "${'alarm_time'.tr()}: $hour:$minute\n${data['details'] ?? ''}",
                  style: TextStyle(color: isDark ? Colors.white54 : Colors.black54),
                ),
                trailing: PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      onEdit(context, alarms[i], data);
                    } else if (value == 'delete') {
                      alarms[i].reference.delete();
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(value: 'edit', child: Text('Editează')),
                    PopupMenuItem(value: 'delete', child: Text('Șterge')),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ------------------ ADAUGARE/EDITARE ALARMĂ ------------------
class AlarmAddSheet extends StatefulWidget {
  final String pacientId;
  final DateTime initialDate;
  final bool isEdit;
  final DocumentSnapshot? alarmDoc;
  final String? initialTitle;
  final String? initialDetails;

  const AlarmAddSheet({
    required this.pacientId,
    required this.initialDate,
    this.isEdit = false,
    this.alarmDoc,
    this.initialTitle,
    this.initialDetails,
    Key? key,
  }) : super(key: key);

  @override
  State<AlarmAddSheet> createState() => _AlarmAddSheetState();
}

class _AlarmAddSheetState extends State<AlarmAddSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _detailsController;

  late int selectedMonth;
  late int selectedDay;
  late int selectedHour;
  late int selectedMinute;

  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle ?? '');
    _detailsController = TextEditingController(text: widget.initialDetails ?? '');
    selectedMonth = widget.initialDate.month;
    selectedDay = widget.initialDate.day;
    selectedHour = widget.initialDate.hour;
    selectedMinute = widget.initialDate.minute;
  }

  @override
  Widget build(BuildContext context) {
    final themeGreen = const Color(0xFF217A6B);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mediaQuery = MediaQuery.of(context);

    final months = List.generate(12, (i) => i + 1);
    final days = List.generate(
        DateUtils.getDaysInMonth(DateTime.now().year, selectedMonth), (i) => i + 1);
    final hours = List.generate(24, (i) => i);
    final minutes = List.generate(60, (i) => i);

    return Container(
      constraints: const BoxConstraints(
        minHeight: 320,
        maxHeight: 520,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF232323) : Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: themeGreen.withOpacity(0.13),
            blurRadius: 20,
            offset: const Offset(0, -3),
          )
        ],
      ),
      child: Padding(
        padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: mediaQuery.viewInsets.bottom + 12),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.isEdit ? "Editare alarmă" : "add_alarm".tr(),
                        style: TextStyle(
                          color: themeGreen,
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: Colors.grey[500]),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                // Wheel Pickers
                Center(
                  child: SizedBox(
                    height: 120,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Day
                        _Wheel(
                          items: days.map((e) => e.toString().padLeft(2, "0")).toList(),
                          initial: selectedDay - 1,
                          label: "day".tr(),
                          onChanged: (v) => setState(() => selectedDay = days[v]),
                        ),
                        // Month
                        _Wheel(
                          items: months.map((e) => e.toString().padLeft(2, "0")).toList(),
                          initial: selectedMonth - 1,
                          label: "month".tr(),
                          onChanged: (v) => setState(() {
                            selectedMonth = months[v];
                            final maxDay = DateUtils.getDaysInMonth(DateTime.now().year, selectedMonth);
                            if (selectedDay > maxDay) selectedDay = maxDay;
                          }),
                        ),
                        // Hour
                        _Wheel(
                          items: hours.map((e) => e.toString().padLeft(2, "0")).toList(),
                          initial: selectedHour,
                          label: "hour".tr(),
                          onChanged: (v) => setState(() => selectedHour = hours[v]),
                        ),
                        // Minute
                        _Wheel(
                          items: minutes.map((e) => e.toString().padLeft(2, "0")).toList(),
                          initial: selectedMinute,
                          label: "minute".tr(),
                          onChanged: (v) => setState(() => selectedMinute = minutes[v]),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: "alarm_title".tr(),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    fillColor: themeGreen.withOpacity(0.045),
                    filled: true,
                  ),
                  validator: (v) => v == null || v.isEmpty ? "alarm_title".tr() : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _detailsController,
                  decoration: InputDecoration(
                    labelText: "alarm_details".tr(),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    fillColor: themeGreen.withOpacity(0.045),
                    filled: true,
                  ),
                  minLines: 2,
                  maxLines: 4,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: isSaving
                            ? null
                            : () async {
                          if (!_formKey.currentState!.validate()) return;
                          setState(() => isSaving = true);
                          try {
                            final newDate = DateTime(
                              DateTime.now().year,
                              selectedMonth,
                              selectedDay,
                              selectedHour,
                              selectedMinute,
                            );
                            if (widget.isEdit && widget.alarmDoc != null) {
                              // Update alarmă
                              await widget.alarmDoc!.reference.update({
                                "title": _titleController.text.trim(),
                                "details": _detailsController.text.trim(),
                                "date": newDate,
                                // Nu schimba "createdBy" la editare!
                              });
                              if (mounted) {
                                setState(() => isSaving = false);
                                Navigator.of(context).pop();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text("Alarmă actualizată!")),
                                );
                              }
                            } else {
                              // Adăugare alarmă
                              await FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(widget.pacientId)
                                  .collection('alarms')
                                  .add({
                                "title": _titleController.text.trim(),
                                "details": _detailsController.text.trim(),
                                "date": newDate,
                                "createdBy": "medic",
                              });
                              if (mounted) {
                                setState(() => isSaving = false);
                                Navigator.of(context).pop();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text("alarm_saved".tr())),
                                );
                              }
                            }
                          } catch (e) {
                            setState(() => isSaving = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Eroare la salvare: $e")),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: themeGreen,
                          minimumSize: const Size.fromHeight(52),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          elevation: 2,
                        ),
                        child: isSaving
                            ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.2,
                            ))
                            : Text(widget.isEdit ? "Salvează modificarea" : "save_alarm".tr(),
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 19, color: Colors.white)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// --------- COMPONENTA WHEEL UNICĂ, FOLOSIND CupertinoPicker ---------
class _Wheel extends StatelessWidget {
  final List<String> items;
  final int initial;
  final String label;
  final ValueChanged<int> onChanged;

  const _Wheel({
    required this.items,
    required this.initial,
    required this.label,
    required this.onChanged,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeGreen = const Color(0xFF217A6B);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Flexible(
      flex: 1,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: themeGreen)),
          SizedBox(
            height: 75,
            child: CupertinoPicker(
              backgroundColor: Colors.transparent,
              scrollController: FixedExtentScrollController(initialItem: initial),
              itemExtent: 40,
              diameterRatio: 1.13,
              squeeze: 1.12,
              useMagnifier: true,
              magnification: 1.19,
              onSelectedItemChanged: onChanged,
              children: items
                  .map((e) => Center(
                child: Text(
                  e,
                  style: TextStyle(
                    fontSize: 26,
                    color: isDark ? Colors.white : themeGreen,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}
