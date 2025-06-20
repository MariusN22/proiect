import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:healthband_app/screens/zego/zego_call_page.dart';

class CallOutgoingListenerWidget extends StatefulWidget {
  const CallOutgoingListenerWidget({Key? key}) : super(key: key);

  @override
  State<CallOutgoingListenerWidget> createState() => _CallOutgoingListenerWidgetState();
}

class _CallOutgoingListenerWidgetState extends State<CallOutgoingListenerWidget> {
  StreamSubscription<QuerySnapshot>? _subscription;
  bool _dialogShown = false;

  @override
  void initState() {
    super.initState();
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      _subscription = FirebaseFirestore.instance
          .collection('calls')
          .where('callerId', isEqualTo: currentUser.uid)
          .where('status', whereIn: ['pending', 'accepted', 'declined'])
          .orderBy('createdAt', descending: true)
          .limit(1)
          .snapshots()
          .listen((snapshot) {
        if (snapshot.docs.isNotEmpty && !_dialogShown) {
          final callDoc = snapshot.docs.first;
          final data = callDoc.data() as Map<String, dynamic>;
          final status = data['status'];
          final callId = callDoc.id;

          if (status == 'accepted') {
            _dialogShown = true;
            final user = FirebaseAuth.instance.currentUser;
            print('=== CALLER NAVIGHEAZĂ: ===');
            print('userId: ${user!.uid}');
            print('callId: $callId');
            print('isVideoCall: ${data['type'] == 'video'}');
            print('displayName: ${user.displayName ?? "Utilizator"}');
            Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => ZegoCallPage(
                userId: user.uid,
                callId: callId,
                isVideoCall: (data['type'] == 'video'),
                displayName: user.displayName ?? "Utilizator",
              ),
            )).then((_) {
              _dialogShown = false;
            });
          } else if (status == 'declined') {
            _dialogShown = true;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Apelul a fost refuzat')),
            );
            Future.delayed(const Duration(seconds: 2), () {
              setState(() => _dialogShown = false);
            });
          }
        }
      });
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
