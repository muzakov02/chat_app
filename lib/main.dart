import 'dart:math';

import 'package:chat_app/presentation/screens/message_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';

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

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chat App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: MessageScreen(),


    );
  }
}

String userID = Random().nextInt(1000).toString();

class CallPage extends StatelessWidget {
  const CallPage({
    super.key,
    required this.callID,
    required this.isVideoCall,
  });

  final String callID;
  final bool isVideoCall;

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser!;

    return ZegoUIKitPrebuiltCall(
      appID: 530905604,
      appSign: '887b318795819e2bd3a0e1b54492364cbf3fd33e752a590591de4aaf421d728a',
      userID: currentUser.uid,
      userName: currentUser.email ?? '',
      callID: callID,
      config: isVideoCall
          ? ZegoUIKitPrebuiltCallConfig.oneOnOneVideoCall()  // ✅ video
          : ZegoUIKitPrebuiltCallConfig.oneOnOneVoiceCall(), // ✅ audio
    );
  }
}
