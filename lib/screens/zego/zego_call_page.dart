import 'package:flutter/material.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import 'package:healthband_app/services/call_service.dart'; // adaptează calea dacă e necesar

class ZegoCallPage extends StatefulWidget {
  final String userId;
  final String callId;
  final bool isVideoCall;
  final String displayName;

  static const int appId = 272784063;
  static const String appSign = 'e8668ff45761569b02e3b3429ab0e23a74ddc96864211b02807381b36179934d';

  const ZegoCallPage({
    Key? key,
    required this.userId,
    required this.callId,
    required this.isVideoCall,
    required this.displayName,
  }) : super(key: key);

  @override
  State<ZegoCallPage> createState() => _ZegoCallPageState();
}

class _ZegoCallPageState extends State<ZegoCallPage> {
  @override
  void dispose() {
    // cleanup la închidere ecran (automat la hangup sau back)
    CallService.endCall(widget.callId);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String safeName = (widget.displayName.trim().isNotEmpty)
        ? widget.displayName.trim()
        : "Utilizator";

    final config = widget.isVideoCall
        ? ZegoUIKitPrebuiltCallConfig.oneOnOneVideoCall()
        : ZegoUIKitPrebuiltCallConfig.oneOnOneVoiceCall();

    return Scaffold(
      body: SafeArea(
        child: ZegoUIKitPrebuiltCall(
          appID: ZegoCallPage.appId,
          appSign: ZegoCallPage.appSign,
          userID: widget.userId,
          userName: safeName,
          callID: widget.callId,
          config: config,
        ),
      ),
    );
  }
}
