import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:healthband_app/services/call_service.dart';
import 'package:healthband_app/screens/zego/zego_call_page.dart';

class ApelPacientScreen extends StatefulWidget {
  final String pacientId;
  final String nume;
  final String prenume;

  const ApelPacientScreen({
    Key? key,
    required this.pacientId,
    required this.nume,
    required this.prenume,
  }) : super(key: key);

  @override
  State<ApelPacientScreen> createState() => _ApelPacientScreenState();
}

class _ApelPacientScreenState extends State<ApelPacientScreen> {
  bool _isCalling = false;

  Future<String> getCurrentUserFullName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return "Utilizator";
    if (user.displayName != null && user.displayName!.trim().isNotEmpty) {
      return user.displayName!;
    }
    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final data = doc.data();
    if (data != null) {
      final nume = data['nume'] ?? '';
      final prenume = data['prenume'] ?? '';
      final name = "$nume $prenume".trim();
      return name.isNotEmpty ? name : "Utilizator";
    }
    return "Utilizator";
  }

  Future<String?> _getUserFcmToken(String userId) async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    final data = doc.data();
    if (data != null && data['fcmToken'] != null) {
      return data['fcmToken'] as String;
    }
    return null;
  }

  Future<void> _initiateCall({required bool isVideo}) async {
    setState(() {
      _isCalling = true;
    });
    final currentUser = FirebaseAuth.instance.currentUser;
    final currentUserId = currentUser?.uid ?? "";
    final fullName = "${widget.nume} ${widget.prenume}";
    try {
      final callerName = await getCurrentUserFullName();
      // Ia tokenul FCM al pacientului apelat (poți folosi și pentru medic)
      final receiverFcmToken = await _getUserFcmToken(widget.pacientId);

      if (receiverFcmToken == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Nu s-a găsit tokenul FCM al destinatarului!')),
        );
        setState(() {
          _isCalling = false;
        });
        return;
      }

      // Creează call în Firestore și trimite FCM
      final String callId = await CallService.initiateCall(
        callerId: currentUserId,
        callerName: callerName.isNotEmpty ? callerName : "Utilizator",
        receiverId: widget.pacientId,
        receiverName: fullName,
        isVideo: isVideo,
        receiverFcmToken: receiverFcmToken,
      );

      // Navighează direct în conferință (pacientul intră primul)
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ZegoCallPage(
            userId: currentUserId,
            callId: callId,
            isVideoCall: isVideo,
            displayName: callerName,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Eroare la inițiere apel: $e')),
      );
    } finally {
      setState(() {
        _isCalling = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fullName = "${widget.nume} ${widget.prenume}";
    final currentUser = FirebaseAuth.instance.currentUser;
    final currentUserId = currentUser?.uid ?? "";

    return Scaffold(
      appBar: AppBar(
        title: Text("calls".tr()),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person, size: 72, color: Theme.of(context).primaryColor),
              const SizedBox(height: 18),
              Text(
                fullName,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              const SizedBox(height: 44),
              ElevatedButton.icon(
                onPressed: currentUserId.isEmpty || _isCalling
                    ? null
                    : () => _initiateCall(isVideo: true),
                icon: const Icon(Icons.videocam, size: 34, color: Colors.white),
                label: Text(
                  "video_call".tr(),
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? Colors.tealAccent[700] : Theme.of(context).primaryColor,
                  minimumSize: const Size(double.infinity, 64),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  elevation: 4,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
              const SizedBox(height: 28),
              ElevatedButton.icon(
                onPressed: currentUserId.isEmpty || _isCalling
                    ? null
                    : () => _initiateCall(isVideo: false),
                icon: const Icon(Icons.call, size: 32, color: Colors.white),
                label: Text(
                  "audio_call".tr(),
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? Colors.teal[600] : Colors.teal[700],
                  minimumSize: const Size(double.infinity, 64),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  elevation: 4,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
