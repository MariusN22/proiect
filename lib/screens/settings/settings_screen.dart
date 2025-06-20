import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import '../../core/theme_notifier.dart';
import '../common/change_password_dialog.dart';

class SettingsScreen extends StatefulWidget {
  final String userRole; // "medic" sau "user"
  const SettingsScreen({Key? key, required this.userRole}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool notificationsEnabled = true;

  Future<void> _chooseLanguageDialog() async {
    final selected = await showDialog<Locale>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text('choose_language'.tr()),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, const Locale('ro')),
            child: Text('romanian'.tr()),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, const Locale('en')),
            child: Text('english'.tr()),
          ),
        ],
      ),
    );
    if (selected != null) {
      await context.setLocale(selected);
      setState(() {}); // Update UI to reflect new language
    }
  }

  String getCurrentLanguage(BuildContext context) {
    final code = context.locale.languageCode;
    if (code == 'ro') return 'romanian'.tr();
    if (code == 'en') return 'english'.tr();
    return code;
  }

  Color getIconColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.white
        : Theme.of(context).primaryColor;
  }

  Color getActiveTrackColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.tealAccent
        : Colors.tealAccent;
  }

  Color getInactiveTrackColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.grey[700]!
        : Colors.grey[300]!;
  }

  Color getInactiveThumbColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.grey[400]!
        : Colors.grey[400]!;
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<ThemeNotifier>().themeMode == ThemeMode.dark;
    final themeGreen = const Color(0xFF217A6B);

    return Scaffold(
      appBar: AppBar(
        title: Text('settings'.tr()),
        backgroundColor: themeGreen,
        automaticallyImplyLeading: true,
      ),
      body: ListView(
        children: [
          const SizedBox(height: 10),
          // NOTIFICĂRI
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 18),
            elevation: 3,
            child: SwitchListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text('notifications'.tr(), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              value: notificationsEnabled,
              onChanged: (value) {
                setState(() {
                  notificationsEnabled = value;
                });
              },
              secondary: Icon(Icons.notifications, color: getIconColor(context)),
              activeColor: themeGreen,
              activeTrackColor: getActiveTrackColor(context),
              inactiveThumbColor: getInactiveThumbColor(context),
              inactiveTrackColor: getInactiveTrackColor(context),
              tileColor: Theme.of(context).cardColor,
              contentPadding: const EdgeInsets.symmetric(vertical: 6, horizontal: 18),
            ),
          ),
          // LIMBA (cu app_language!)
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 18),
            elevation: 3,
            child: ListTile(
              leading: Icon(Icons.language, color: getIconColor(context)),
              title: Text('app_language'.tr(), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              subtitle: Text(getCurrentLanguage(context), style: const TextStyle(fontSize: 16)),
              trailing: const Icon(Icons.arrow_forward_ios, size: 20, color: Colors.grey),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              tileColor: Theme.of(context).cardColor,
              contentPadding: const EdgeInsets.symmetric(vertical: 6, horizontal: 18),
              onTap: _chooseLanguageDialog,
            ),
          ),
          // DARK MODE
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 18),
            elevation: 3,
            child: SwitchListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text('dark_mode'.tr(), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              value: isDarkMode,
              onChanged: (value) {
                context.read<ThemeNotifier>().toggleTheme(value);
              },
              secondary: Icon(Icons.dark_mode, color: getIconColor(context)),
              activeColor: themeGreen,
              activeTrackColor: getActiveTrackColor(context),
              inactiveThumbColor: getInactiveThumbColor(context),
              inactiveTrackColor: getInactiveTrackColor(context),
              tileColor: Theme.of(context).cardColor,
              contentPadding: const EdgeInsets.symmetric(vertical: 6, horizontal: 18),
            ),
          ),
          // SCHIMBĂ PAROLA
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 18),
            elevation: 3,
            child: ListTile(
              leading: Icon(Icons.lock, color: getIconColor(context)),
              title: Text('change_password'.tr(), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              trailing: const Icon(Icons.arrow_forward_ios, size: 20, color: Colors.grey),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              tileColor: Theme.of(context).cardColor,
              contentPadding: const EdgeInsets.symmetric(vertical: 6, horizontal: 18),
              onTap: () async {
                await showDialog(
                  context: context,
                  builder: (_) => ChangePasswordDialog(),
                );
                setState(() {}); // Actualizează după dialog pentru eventual translate la butoane
              },
            ),
          ),
          // Mesaj rol
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            child: Text(
              widget.userRole == "medic"
                  ? ""
                  : "",
              style: TextStyle(color: themeGreen, fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
