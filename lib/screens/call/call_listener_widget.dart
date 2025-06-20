import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:healthband_app/screens/zego/zego_call_page.dart';

class CallListenerWidget extends StatefulWidget {
  const CallListenerWidget({Key? key}) : super(key: key);

  @override
  State<CallListenerWidget> createState() => _CallListenerWidgetState();
}

class _CallListenerWidgetState extends State<CallListenerWidget> {
  StreamSubscription<QuerySnapshot>? _subscription;
  bool _dialogShown = false;

  @override
  void initState() {
    super.initState();
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      _subscription = FirebaseFirestore.instance
          .collection('calls')
          .where('receiverId', isEqualTo: currentUser.uid)
          .where('status', isEqualTo: 'pending')
          .snapshots()
          .listen((snapshot) {
        if (snapshot.docs.isNotEmpty && !_dialogShown) {
          final callDoc = snapshot.docs.first;
          final data = callDoc.data() as Map<String, dynamic>;
          _showCallDialog(context, callDoc.id, data);
        }
      });
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _showCallDialog(BuildContext context, String callId, Map<String, dynamic> data) async {
    if (!mounted || _dialogShown) return;
    _dialogShown = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          title: Text('Apel de la ${data['callerName'] ?? 'Necunoscut'}'),
          content: Text('Tip apel: ${data['type'] == 'video' ? 'Video' : 'Audio'}'),
          actions: [
            TextButton(
              onPressed: () async {
                // Refuză
                await FirebaseFirestore.instance
                    .collection('calls')
                    .doc(callId)
                    .update({'status': 'declined'});
                Navigator.of(ctx).pop();
                setState(() {
                  _dialogShown = false;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Apel refuzat')),
                );
              },
              child: const Text('Refuză'),
            ),
            ElevatedButton(
              onPressed: () async {
                // Acceptă
                await FirebaseFirestore.instance
                    .collection('calls')
                    .doc(callId)
                    .update({'status': 'accepted'});
                Navigator.of(ctx).pop();

                // DEBUG: vezi exact ce parametri folosești!
                Future.delayed(const Duration(milliseconds: 120), () {
                  if (!mounted) return;
                  final currentUser = FirebaseAuth.instance.currentUser;
                  print('=== RECEIVER NAVIGHEAZĂ: ===');
                  print('userId: ${currentUser!.uid}');
                  print('callId: $callId');
                  print('isVideoCall: ${data['type'] == 'video'}');
                  print('displayName: ${currentUser.displayName ?? "Utilizator"}');
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => ZegoCallPage(
                      userId: currentUser.uid,
                      callId: callId,
                      isVideoCall: (data['type'] == 'video'),
                      displayName: currentUser.displayName ?? "Utilizator",
                    ),
                  ));
                  setState(() {
                    _dialogShown = false;
                  });
                });
              },
              child: const Text('Acceptă'),
            ),
          ],
        );
      },
    ).then((_) {
      if (mounted) setState(() => _dialogShown = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
