import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:easy_localization/easy_localization.dart';

class ChangePasswordDialog extends StatefulWidget {
  @override
  State<ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<ChangePasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool isSaving = false;
  String? error;

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      isSaving = true;
      error = null;
    });
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("not_authenticated".tr());
      final email = user.email;
      final cred = EmailAuthProvider.credential(
        email: email!,
        password: _oldPasswordController.text.trim(),
      );
      await user.reauthenticateWithCredential(cred);
      await user.updatePassword(_newPasswordController.text.trim());
      setState(() => isSaving = false);
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("password_changed_success".tr())),
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        isSaving = false;
        if (e.code == 'wrong-password') {
          error = "wrong_password".tr();
        } else {
          error = e.message ?? "unknown_error".tr();
        }
      });
    } catch (e) {
      setState(() {
        isSaving = false;
        error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("change_password".tr()),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _oldPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: "current_password".tr(),
              ),
              validator: (v) => (v == null || v.isEmpty)
                  ? "current_password".tr()
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _newPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: "new_password".tr(),
              ),
              validator: (v) => v == null || v.length < 6
                  ? "password_short".tr()
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _confirmPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: "confirm_password".tr(),
              ),
              validator: (v) =>
              v != _newPasswordController.text
                  ? "passwords_no_match".tr()
                  : null,
            ),
            if (error != null) ...[
              const SizedBox(height: 10),
              Text(
                error!,
                style: const TextStyle(color: Colors.red, fontSize: 15),
              ),
            ]
          ],
        ),
      ),
      actions: [
        TextButton(
          child: Text("cancel".tr()),
          onPressed: () => Navigator.of(context).pop(),
        ),
        ElevatedButton(
          child: isSaving
              ? const SizedBox(
            height: 22,
            width: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
              : Text("save".tr()),
          onPressed: isSaving ? null : _changePassword,
        ),
      ],
    );
  }
}
