import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CallService {
  static Future<String> initiateCall({
    required String callerId,
    required String callerName,
    required String receiverId,
    required String receiverName,
    required bool isVideo,
    required String receiverFcmToken,
  }) async {
    final callDoc = await FirebaseFirestore.instance.collection('calls').add({
      "callerId": callerId,
      "callerName": callerName,
      "receiverId": receiverId,
      "receiverName": receiverName,
      "type": isVideo ? "video" : "audio",
      "status": "pending",
      "createdAt": FieldValue.serverTimestamp(),
    });

    await sendFcmNotification(
      toFcmToken: receiverFcmToken,
      title: isVideo ? "Apel video nou" : "Apel audio nou",
      body: "$callerName te așteaptă în conferință.",
      data: {
        "type": "incoming_call",
        "callId": callDoc.id,
        "callerName": callerName,
        "isVideo": isVideo.toString(),
      },
    );

    return callDoc.id;
  }

  /// Funcție pentru trimitere FCM prin HTTP POST către Firebase
  static Future<void> sendFcmNotification({
    required String toFcmToken,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    const String serverKey = 'AI...YOUR_SERVER_KEY_HERE...'; // Înlocuiește cu server key-ul tău FCM!
    final postUrl = 'https://fcm.googleapis.com/fcm/send';

    final notification = {
      "title": title,
      "body": body,
      "sound": "default",
    };

    final message = {
      "to": toFcmToken,
      "notification": notification,
      "data": data ?? {},
      "priority": "high",
    };

    await http.post(
      Uri.parse(postUrl),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "key=$serverKey",
      },
      body: jsonEncode(message),
    );
  }

  /// MARCHEAZĂ APELUL CA ÎNCHEIAT
  static Future<void> endCall(String callId) async {
    await FirebaseFirestore.instance.collection('calls').doc(callId).update({
      "status": "ended",
      "endedAt": FieldValue.serverTimestamp(),
    });
  }

  /// (OPȚIONAL) ȘTERGE APELUL (dacă nu vrei istoric)
  static Future<void> deleteCall(String callId) async {
    await FirebaseFirestore.instance.collection('calls').doc(callId).delete();
  }
}
