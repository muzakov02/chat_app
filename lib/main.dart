import 'dart:async';

import 'package:chat_app/presentation/screens/incoming_call_screen.dart';
import 'package:chat_app/presentation/screens/message_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'data/model/chat_user.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await FirebaseAuth.instance.signInWithEmailAndPassword(
    email: 'adxamjonyusupov@gmail.com',
    password: 'test312456',
  );

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  StreamSubscription? _callSubscription;
  final Set<String> _shownCallIds = {};

  // ✅ Hozir MessageScreen dan boshqa screen ochiqmi?
  bool get _isOnCallScreen =>
      _navigatorKey.currentState != null &&
          _navigatorKey.currentState!.canPop();

  @override
  void initState() {
    super.initState();
    _listenForIncomingCalls();
  }

  void _listenForIncomingCalls() {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return;

    _callSubscription = FirebaseFirestore.instance
        .collection('calls')
        .where('receiverId', isEqualTo: currentUserId)
        .where('status', isEqualTo: 'calling')
        .snapshots()
        .listen((snapshot) async {
      for (final change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final callId = change.doc.id;

          // ✅ 1. Ikki marta ko'rsatmaslik
          if (_shownCallIds.contains(callId)) continue;

          // ✅ 2. Biror screen ustida bo'lsa — skip
          if (_isOnCallScreen) continue;

          // ✅ 3. Firestore dan fresh status tekshir
          final freshDoc = await FirebaseFirestore.instance
              .collection('calls')
              .doc(callId)
              .get();
          if (!freshDoc.exists) continue;
          if (freshDoc.data()?['status'] != 'calling') continue;

          _shownCallIds.add(callId);

          final data = change.doc.data()!;
          final callerId = data['callerId'] as String;
          final isVideo = data['isVideo'] as bool? ?? false;

          final callerDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(callerId)
              .get();
          if (!callerDoc.exists) continue;

          final caller = ChatUser.fromFirestore(
            callerDoc.data()!,
            callerDoc.id,
          );

          _navigatorKey.currentState?.push(
            MaterialPageRoute(
              builder: (_) => IncomingCallScreen(
                caller: caller,
                callId: callId,
                isVideo: isVideo,
              ),
            ),
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _callSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'Chat App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MessageScreen(),
    );
  }
}