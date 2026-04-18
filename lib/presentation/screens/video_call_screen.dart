import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../../data/model/chat_user.dart';
import '../../data/services/signaling_service.dart';

class VideoCallScreen extends StatefulWidget {
  final ChatUser remoteUser;
  final String callId;
  final bool isCaller;

  const VideoCallScreen({
    super.key,
    required this.remoteUser,
    required this.callId,
    required this.isCaller,
  });

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  final _signalingService = SignalingService();
  final _localRenderer = RTCVideoRenderer();
  final _remoteRenderer = RTCVideoRenderer();

  bool _isMuted = false;
  bool _isCameraOff = false;
  bool _isConnected = false;

  // ✅ Timer
  Timer? _timer;
  int _seconds = 0;

  String get _timeString {
    final m = (_seconds ~/ 60).toString().padLeft(2, '0');
    final s = (_seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _seconds++);
    });
  }

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();

    _signalingService.onLocalStream = (stream) {
      setState(() => _localRenderer.srcObject = stream);
    };

    _signalingService.onRemoteStream = (stream) {
      setState(() {
        _remoteRenderer.srcObject = stream;
        _isConnected = true;
      });
      _startTimer();
    };

    _signalingService.onCallEnded = () {
      if (mounted) Navigator.pop(context);
    };

    // ✅ Status tinglash
    if (widget.isCaller) {
      FirebaseFirestore.instance
          .collection('calls')
          .doc(widget.callId)
          .snapshots()
          .listen((snap) {
        if (snap.data()?['status'] == 'answered' && !_isConnected) {
          setState(() => _isConnected = true);
          _startTimer();
        }
      });
    }

    if (widget.isCaller) {
      await _signalingService.startCall(
        callId: widget.callId,
        callerId: FirebaseAuth.instance.currentUser!.uid,
        receiverId: widget.remoteUser.id,
        isVideo: true,
      );
    } else {
      await _signalingService.answerCall(
        callId: widget.callId,
        isVideo: true,
      );
    }
  }

  Future<void> _endCall() async {
    _timer?.cancel();
    await _signalingService.endCall(widget.callId);
    if (mounted) Navigator.pop(context);
  }

  void _toggleMute() {
    setState(() => _isMuted = !_isMuted);
    _signalingService.localStream?.getAudioTracks().forEach((track) {
      track.enabled = !_isMuted;
    });
  }

  void _toggleCamera() {
    setState(() => _isCameraOff = !_isCameraOff);
    _signalingService.localStream?.getVideoTracks().forEach((track) {
      track.enabled = !_isCameraOff;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    _signalingService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) await _endCall();
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: Padding(
            padding: const EdgeInsets.only(top: 16.0, left: 16),
            child: SvgPicture.asset(
              'assets/icons/back_white.svg',
              width: 24,
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(top: 16.0, right: 16),
              child: SvgPicture.asset(
                'assets/icons/message-text.svg',
                width: 24,
              ),
            ),
          ],
        ),
        extendBodyBehindAppBar: true,
        backgroundColor: Colors.black,
        body: Stack(
          children: [

            Positioned.fill(
              child: _isConnected
                  ? RTCVideoView(
                _remoteRenderer,
                objectFit:
                RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
              )
                  : Container(
                color: Colors.black,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 35,
                        backgroundImage:
                        widget.remoteUser.avatarUrl.isNotEmpty
                            ? AssetImage(widget.remoteUser.avatarUrl)
                        as ImageProvider
                            : const AssetImage(
                            'assets/images/avatar1.png'),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        widget.remoteUser.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Ulanmoqda...',
                        style: TextStyle(
                            color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            ),


            Positioned(
              top: 80,
              right: 16,
              width: 100,
              height: 140,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _isCameraOff
                    ? Container(
                  color: Colors.grey[800],
                  child: const Icon(Icons.videocam_off,
                      color: Colors.white),
                )
                    : RTCVideoView(
                  _localRenderer,
                  mirror: true,
                  objectFit: RTCVideoViewObjectFit
                      .RTCVideoViewObjectFitCover,
                ),
              ),
            ),

            Positioned(
              bottom: 160,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  Text(
                    widget.remoteUser.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isConnected ? _timeString : 'Ulanmoqda...',
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),


            Positioned(
              bottom: 40,
              left: 30,
              right: 30,
              child: Container(
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(40),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Mikrofon
                    _CallButton(
                      svgPath: _isCameraOff
                          ? 'assets/icons/video_off.svg'
                          : 'assets/icons/video_on.svg',
                      onTap: _toggleCamera,
                    ),


                    _CallButton(
                      svgPath: 'assets/icons/call_off.svg',
                      onTap: _endCall,
                      size: 64,
                    ),


                    _CallButton(
                      svgPath: _isMuted
                          ? 'assets/icons/mikrafon_off.svg'
                          : 'assets/icons/mikrafon_on.svg',
                      onTap: _toggleMute,
                    ),
                  ],
                ),
              ),
            ),
          ],
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
      child: SvgPicture.asset(
        svgPath,
        width: size,
        height: size,
      ),
    );
  }
}