import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../../data/model/chat_user.dart';
import 'audio_call_screen.dart';
import 'chat_screen.dart'; // ✅ chat screen importi
import 'video_call_screen.dart';

class IncomingCallScreen extends StatefulWidget {
  final ChatUser caller;
  final String callId;
  final bool isVideo;

  const IncomingCallScreen({
    super.key,
    required this.caller,
    required this.callId,
    required this.isVideo,
  });

  @override
  State<IncomingCallScreen> createState() => _IncomingCallScreenState();
}

class _IncomingCallScreenState extends State<IncomingCallScreen> {
  StreamSubscription? _callSubscription;

  @override
  void initState() {
    super.initState();
    _listenCallStatus();
  }

  void _listenCallStatus() {
    _callSubscription = FirebaseFirestore.instance
        .collection('calls')
        .doc(widget.callId)
        .snapshots()
        .listen((snap) {
          if (!snap.exists) {
            if (mounted) Navigator.maybePop(context);
            return;
          }
          final status = snap.data()?['status'];
          if (status == 'ended') {
            if (mounted) Navigator.maybePop(context);
          }
        });
  }

  // ❌ Rad etish — call_off
  Future<void> _declineCall() async {
    _callSubscription?.cancel();
    await FirebaseFirestore.instance
        .collection('calls')
        .doc(widget.callId)
        .update({'status': 'ended'});
    if (mounted) Navigator.maybePop(context);
  }

  // ✅ Qabul qilish — call_on
  void _acceptCall() {
    _callSubscription?.cancel();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => widget.isVideo
            ? VideoCallScreen(
                remoteUser: widget.caller,
                callId: widget.callId,
                isCaller: false,
              )
            : AudioCallScreen(
                remoteUser: widget.caller,
                callId: widget.callId,
                isCaller: false,
              ),
      ),
    );
  }

  // 💬 Chat ga o'tish — message
  void _openChat() {
    _callSubscription?.cancel();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(user: widget.caller), // ✅ chat screen
      ),
    );
  }

  @override
  void dispose() {
    _callSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) await _declineCall();
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Color(0xFF56CB01),
          elevation: 0,
          leading: Padding(
            padding: const EdgeInsets.only(top: 16.0, left: 16),
            child: SvgPicture.asset('assets/icons/back_white.svg', width: 24),
          ),
          title: Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: const Text(
                'Kutilmoqda ...',
                style: TextStyle(color: Colors.white,fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),
        body: Container(
          width: double.infinity, // ✅ to'liq kenglik
          height: double.infinity, // ✅ to'liq balandlik
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF56CB01), Color(0xFF3A8A00)],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // ✅ Yuqori qism — avatar va ism
              Column(
                children: [
                  const SizedBox(height: 160),
                  CircleAvatar(
                    radius: 55,
                    backgroundImage: widget.caller.avatarUrl.isNotEmpty
                        ? AssetImage(widget.caller.avatarUrl) as ImageProvider
                        : const AssetImage('assets/images/avatar1.png'),
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      widget.caller.name,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              Padding(
                padding: const EdgeInsets.only(bottom: 40),
                child: Container(
                  height: 100,
                  margin: const EdgeInsets.symmetric(horizontal: 30),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: Row(
                    children: [
                      // 1️⃣ Rad etish — call_off
                      Expanded(
                        child: Center(
                          child: _CallButton(
                            svgPath: 'assets/icons/call_off.svg',
                            onTap: _declineCall,
                            size: 56,
                          ),
                        ),
                      ),

                      // 2️⃣ Qabul qilish — call_on
                      Expanded(
                        child: Center(
                          child: _CallButton(
                            svgPath: 'assets/icons/call_on.svg',
                            onTap: _acceptCall,
                            size: 64,
                          ),
                        ),
                      ),

                      // 3️⃣ Chat ga o'tish — message
                      Expanded(
                        child: Center(
                          child: _CallButton(
                            svgPath: 'assets/icons/message-text.svg',
                            onTap: _openChat,
                            size: 52,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CallButton extends StatelessWidget {
  final String svgPath;
  final VoidCallback onTap;
  final double size;

  const _CallButton({
    required this.svgPath,
    required this.onTap,
    this.size = 56,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SvgPicture.asset(svgPath, width: size, height: size),
    );
  }
}
