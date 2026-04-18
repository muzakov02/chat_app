import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
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
    };

    _signalingService.onCallEnded = () {
      if (mounted) Navigator.pop(context);
    };

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
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    _signalingService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ✅ Remote video — to'liq ekran
          Positioned.fill(
            child: _isConnected
                ? RTCVideoView(
              _remoteRenderer,
              objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
            )
                : Container(
              color: Colors.black,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: widget.remoteUser.avatarUrl.isNotEmpty
                          ? AssetImage(widget.remoteUser.avatarUrl) as ImageProvider
                          : const AssetImage('assets/images/avatar1.png'),
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
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ✅ Local video — yuqori o'ngda kichik
          Positioned(
            top: 60,
            right: 16,
            width: 100,
            height: 140,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _isCameraOff
                  ? Container(
                color: Colors.grey[800],
                child: const Icon(Icons.videocam_off, color: Colors.white),
              )
                  : RTCVideoView(
                _localRenderer,
                mirror: true,
                objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
              ),
            ),
          ),

          // ✅ Ism — pastki qismda
          Positioned(
            bottom: 140,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Text(
                  widget.remoteUser.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _isConnected ? '00:00' : 'Ulanmoqda...',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),

          // ✅ Tugmalar
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _CallButton(
                  icon: _isCameraOff ? Icons.videocam_off : Icons.videocam,
                  color: Colors.white24,
                  onTap: _toggleCamera,
                ),
                _CallButton(
                  icon: Icons.call_end,
                  color: Colors.red,
                  onTap: _endCall,
                  size: 64,
                ),
                _CallButton(
                  icon: _isMuted ? Icons.mic_off : Icons.mic,
                  color: Colors.white24,
                  onTap: _toggleMute,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CallButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final double size;

  const _CallButton({
    required this.icon,
    required this.color,
    required this.onTap,
    this.size = 56,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: size * 0.45),
      ),
    );
  }
}