import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class SignalingService {
  final _firestore = FirebaseFirestore.instance;

  final Map<String, dynamic> _configuration = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
    ]
  };

  RTCPeerConnection? _peerConnection;
  MediaStream? localStream;
  MediaStream? remoteStream;
  bool _isDisposed = false; // ✅

  Function(MediaStream)? onLocalStream;
  Function(MediaStream)? onRemoteStream;
  Function()? onCallEnded;

  Future<MediaStream> getUserMedia(bool isVideo) async {
    final constraints = {
      'audio': true,
      'video': isVideo
          ? {'facingMode': 'user', 'width': 640, 'height': 480}
          : false,
    };
    return await navigator.mediaDevices.getUserMedia(constraints);
  }

  Future<RTCPeerConnection> _createPc() async {
    final pc = await createPeerConnection(_configuration);

    pc.onTrack = (event) {
      if (_isDisposed) return; // ✅
      if (event.streams.isNotEmpty) {
        remoteStream = event.streams[0];
        onRemoteStream?.call(remoteStream!);
      }
    };

    pc.onConnectionState = (state) {
      if (_isDisposed) return; // ✅
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateDisconnected) {
        // 5 soniya kutib, hali ham disconnected bo'lsa — tugatamiz
        Future.delayed(const Duration(seconds: 5), () {
          if (_isDisposed) return;
          if (_peerConnection?.connectionState ==
              RTCPeerConnectionState.RTCPeerConnectionStateDisconnected) {
            onCallEnded?.call();
          }
        });
      }
    };

    return pc;
  }

  Future<void> startCall({
    required String callId,
    required String callerId,
    required String receiverId,
    required bool isVideo,
  }) async {
    localStream = await getUserMedia(isVideo);
    if (_isDisposed) return; // ✅
    onLocalStream?.call(localStream!);

    _peerConnection = await _createPc();
    if (_isDisposed) return; // ✅

    localStream!.getTracks().forEach((track) {
      _peerConnection!.addTrack(track, localStream!);
    });

    _peerConnection!.onIceCandidate = (candidate) {
      if (_isDisposed || candidate.candidate == null) return; // ✅
      _firestore
          .collection('calls')
          .doc(callId)
          .collection('callerCandidates')
          .add(candidate.toMap());
    };

    final offer = await _peerConnection!.createOffer();
    if (_isDisposed) return; // ✅

    await _peerConnection!.setLocalDescription(offer);
    if (_isDisposed) return; // ✅

    await _firestore.collection('calls').doc(callId).set({
      'callerId': callerId,
      'receiverId': receiverId,
      'isVideo': isVideo,
      'status': 'calling',
      'offer': {'type': offer.type, 'sdp': offer.sdp},
      'createdAt': Timestamp.now(),
    });

    _firestore.collection('calls').doc(callId).snapshots().listen((snap) async {
      if (_isDisposed || !snap.exists) return; // ✅
      final data = snap.data()!;

      if (data['answer'] != null &&
          _peerConnection?.signalingState !=
              RTCSignalingState.RTCSignalingStateStable) {
        await _peerConnection?.setRemoteDescription(
          RTCSessionDescription(data['answer']['sdp'], data['answer']['type']),
        );
      }

      if (data['status'] == 'ended') onCallEnded?.call();
    });

    _firestore
        .collection('calls')
        .doc(callId)
        .collection('receiverCandidates')
        .snapshots()
        .listen((snap) {
      if (_isDisposed) return; // ✅
      for (final change in snap.docChanges) {
        if (change.type == DocumentChangeType.added) {
          _peerConnection?.addCandidate(RTCIceCandidate(
            change.doc['candidate'],
            change.doc['sdpMid'],
            change.doc['sdpMLineIndex'],
          ));
        }
      }
    });
  }

  Future<void> answerCall({
    required String callId,
    required bool isVideo,
  }) async {
    localStream = await getUserMedia(isVideo);
    if (_isDisposed) return; // ✅
    onLocalStream?.call(localStream!);

    _peerConnection = await _createPc();
    if (_isDisposed) return; // ✅

    localStream!.getTracks().forEach((track) {
      _peerConnection!.addTrack(track, localStream!);
    });

    _peerConnection!.onIceCandidate = (candidate) {
      if (_isDisposed || candidate.candidate == null) return; // ✅
      _firestore
          .collection('calls')
          .doc(callId)
          .collection('receiverCandidates')
          .add(candidate.toMap());
    };

    final callDoc =
    await _firestore.collection('calls').doc(callId).get();
    if (_isDisposed) return; // ✅

    await _peerConnection!.setRemoteDescription(
      RTCSessionDescription(
        callDoc['offer']['sdp'],
        callDoc['offer']['type'],
      ),
    );
    if (_isDisposed) return; // ✅

    final answer = await _peerConnection!.createAnswer();
    if (_isDisposed) return; // ✅

    await _peerConnection!.setLocalDescription(answer);
    if (_isDisposed) return; // ✅

    // ✅ Faqat shu yerda 'answered' ga yangilanadi
    await _firestore.collection('calls').doc(callId).update({
      'answer': {'type': answer.type, 'sdp': answer.sdp},
      'status': 'answered',
    });

    _firestore
        .collection('calls')
        .doc(callId)
        .collection('callerCandidates')
        .snapshots()
        .listen((snap) {
      if (_isDisposed) return; // ✅
      for (final change in snap.docChanges) {
        if (change.type == DocumentChangeType.added) {
          _peerConnection?.addCandidate(RTCIceCandidate(
            change.doc['candidate'],
            change.doc['sdpMid'],
            change.doc['sdpMLineIndex'],
          ));
        }
      }
    });

    _firestore.collection('calls').doc(callId).snapshots().listen((snap) {
      if (_isDisposed) return; // ✅
      if (snap.data()?['status'] == 'ended') onCallEnded?.call();
    });
  }

  Future<void> endCall(String callId) async {
    await _firestore
        .collection('calls')
        .doc(callId)
        .update({'status': 'ended'});
    await _cleanup();
  }

  Future<void> _cleanup() async {
    _isDisposed = true; // ✅
    localStream?.getTracks().forEach((track) => track.stop());
    await localStream?.dispose();
    await remoteStream?.dispose();
    await _peerConnection?.close();
    _peerConnection = null;
    localStream = null;
    remoteStream = null;
  }

  void dispose() => _cleanup();
}