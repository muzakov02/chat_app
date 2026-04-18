import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class SignalingService {
  final _firestore = FirebaseFirestore.instance;

  // STUN serverlar — bepul Google serverlari
  final Map<String, dynamic> _configuration = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
    ]
  };

  RTCPeerConnection? _peerConnection;
  MediaStream? localStream;
  MediaStream? remoteStream;

  // Callbacklar — UI ga xabar berish uchun
  Function(MediaStream)? onLocalStream;
  Function(MediaStream)? onRemoteStream;
  Function()? onCallEnded;

  // ✅ Kamera va mikrofon olish
  Future<MediaStream> getUserMedia(bool isVideo) async {
    final constraints = {
      'audio': true,
      'video': isVideo
          ? {'facingMode': 'user', 'width': 640, 'height': 480}
          : false,
    };
    return await navigator.mediaDevices.getUserMedia(constraints);
  }

  // ✅ PeerConnection yaratish
  Future<RTCPeerConnection> _createPc() async {
    final pc = await createPeerConnection(_configuration);

    pc.onTrack = (event) {
      if (event.streams.isNotEmpty) {
        remoteStream = event.streams[0];
        onRemoteStream?.call(remoteStream!);
      }
    };

    pc.onConnectionState = (state) {
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateDisconnected ||
          state == RTCPeerConnectionState.RTCPeerConnectionStateFailed) {
        onCallEnded?.call();
      }
    };

    return pc;
  }

  // ✅ Qo'ng'iroq boshlash (Caller)
  Future<void> startCall({
    required String callId,
    required String callerId,
    required String receiverId,
    required bool isVideo,
  }) async {
    // 1. Media stream olish
    localStream = await getUserMedia(isVideo);
    onLocalStream?.call(localStream!);

    // 2. PeerConnection yaratish
    _peerConnection = await _createPc();

    // 3. Local stream ni qo'shish
    localStream!.getTracks().forEach((track) {
      _peerConnection!.addTrack(track, localStream!);
    });

    // 4. ICE candidates ni saqlash
    _peerConnection!.onIceCandidate = (candidate) {
      if (candidate.candidate != null) {
        _firestore
            .collection('calls')
            .doc(callId)
            .collection('callerCandidates')
            .add(candidate.toMap());
      }
    };

    // 5. Offer yaratish
    final offer = await _peerConnection!.createOffer();
    await _peerConnection!.setLocalDescription(offer);

    // 6. Firestore ga saqlash
    await _firestore.collection('calls').doc(callId).set({
      'callerId': callerId,
      'receiverId': receiverId,
      'isVideo': isVideo,
      'status': 'calling',
      'offer': {'type': offer.type, 'sdp': offer.sdp},
      'createdAt': Timestamp.now(),
    });

    // 7. Answer ni kutish
    _firestore.collection('calls').doc(callId).snapshots().listen((snap) async {
      if (!snap.exists) return;
      final data = snap.data()!;

      if (data['answer'] != null &&
          _peerConnection?.signalingState !=
              RTCSignalingState.RTCSignalingStateStable) {
        await _peerConnection!.setRemoteDescription(
          RTCSessionDescription(data['answer']['sdp'], data['answer']['type']),
        );
      }

      if (data['status'] == 'ended') onCallEnded?.call();
    });

    // 8. Receiver candidates ni tinglash
    _firestore
        .collection('calls')
        .doc(callId)
        .collection('receiverCandidates')
        .snapshots()
        .listen((snap) {
      for (final change in snap.docChanges) {
        if (change.type == DocumentChangeType.added) {
          _peerConnection!.addCandidate(RTCIceCandidate(
            change.doc['candidate'],
            change.doc['sdpMid'],
            change.doc['sdpMLineIndex'],
          ));
        }
      }
    });
  }

  // ✅ Qo'ng'iroqqa javob berish (Receiver)
  Future<void> answerCall({
    required String callId,
    required bool isVideo,
  }) async {
    localStream = await getUserMedia(isVideo);
    onLocalStream?.call(localStream!);

    _peerConnection = await _createPc();

    localStream!.getTracks().forEach((track) {
      _peerConnection!.addTrack(track, localStream!);
    });

    _peerConnection!.onIceCandidate = (candidate) {
      if (candidate.candidate != null) {
        _firestore
            .collection('calls')
            .doc(callId)
            .collection('receiverCandidates')
            .add(candidate.toMap());
      }
    };

    // Offer ni olish
    final callDoc = await _firestore.collection('calls').doc(callId).get();
    await _peerConnection!.setRemoteDescription(
      RTCSessionDescription(
        callDoc['offer']['sdp'],
        callDoc['offer']['type'],
      ),
    );

    // Answer yaratish
    final answer = await _peerConnection!.createAnswer();
    await _peerConnection!.setLocalDescription(answer);

    await _firestore.collection('calls').doc(callId).update({
      'answer': {'type': answer.type, 'sdp': answer.sdp},
      'status': 'answered',
    });

    // Caller candidates ni tinglash
    _firestore
        .collection('calls')
        .doc(callId)
        .collection('callerCandidates')
        .snapshots()
        .listen((snap) {
      for (final change in snap.docChanges) {
        if (change.type == DocumentChangeType.added) {
          _peerConnection!.addCandidate(RTCIceCandidate(
            change.doc['candidate'],
            change.doc['sdpMid'],
            change.doc['sdpMLineIndex'],
          ));
        }
      }
    });

    _firestore.collection('calls').doc(callId).snapshots().listen((snap) {
      if (snap.data()?['status'] == 'ended') onCallEnded?.call();
    });
  }

  // ✅ Qo'ng'iroqni tugatish
  Future<void> endCall(String callId) async {
    await _firestore
        .collection('calls')
        .doc(callId)
        .update({'status': 'ended'});
    await _cleanup();
  }

  Future<void> _cleanup() async {
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