import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({Key? key}) : super(key: key);

  List<Map<String, String>> get _faq => [
    {
      "question": "help_q1",
      "answer": "help_a1",
    },
    {
      "question": "help_q2",
      "answer": "help_a2",
    },
    {
      "question": "help_q3",
      "answer": "help_a3",
    },
    {
      "question": "help_q4",
      "answer": "help_a4",
    },
    {
      "question": "help_q5",
      "answer": "help_a5",
    },
    {
      "question": "help_q6",
      "answer": "help_a6",
    },
  ];

  @override
  Widget build(BuildContext context) {
    final themeGreen = const Color(0xFF217A6B);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final List<Widget> items = [];
    for (int i = 0; i < _faq.length; i++) {
      items.add(_HelpCard(
        questionKey: _faq[i]['question']!,
        answerKey: _faq[i]['answer']!,
        themeGreen: themeGreen,
        isDark: isDark,
      ));
      if (i != _faq.length - 1) {
        items.add(const SizedBox(height: 14));
      }
    }
    items.add(const SizedBox(height: 14));
    items.add(_SupportCard(themeGreen: themeGreen, isDark: isDark));

    return Scaffold(
      appBar: AppBar(
        title: Text('ajutor'.tr()),
        backgroundColor: themeGreen,
      ),
      backgroundColor: isDark ? const Color(0xFF18191B) : const Color(0xFFEFF6F4),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
        children: items,
      ),
    );
  }
}

class _HelpCard extends StatelessWidget {
  final String questionKey;
  final String answerKey;
  final Color themeGreen;
  final bool isDark;

  const _HelpCard({
    required this.questionKey,
    required this.answerKey,
    required this.themeGreen,
    required this.isDark,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      color: isDark ? const Color(0xFF232323) : Colors.white,
      elevation: 3,
      child: ListTile(
        leading: Icon(Icons.help_outline, color: themeGreen, size: 30),
        title: Text(
          questionKey.tr(),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey),
        onTap: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              title: Text(
                questionKey.tr(),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 19),
              ),
              content: Text(
                answerKey.tr(),
                style: const TextStyle(fontSize: 17),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text("inchide".tr()),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SupportCard extends StatelessWidget {
  final Color themeGreen;
  final bool isDark;

  const _SupportCard({required this.themeGreen, required this.isDark, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      color: isDark ? const Color(0xFF232323) : Colors.white,
      elevation: 3,
      child: ListTile(
        leading: Icon(Icons.support_agent, color: themeGreen, size: 30),
        title: Text(
          "help_contact_title".tr(),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        subtitle: Text(
          "help_contact_details".tr(),
          style: const TextStyle(fontSize: 15),
        ),
        onTap: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              title: Text("help_contact_popup_title".tr()),
              content: Text("help_contact_popup_content".tr()),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text("inchide".tr()),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
