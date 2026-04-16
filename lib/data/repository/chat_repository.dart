import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/chat_user.dart';

class ChatRepository {
  final _firestore = FirebaseFirestore.instance;

  Stream<List<ChatUser>> getUsers() {
    return _firestore
        .collection('users')
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => ChatUser.fromFirestore(doc.data(), doc.id))
        .toList());
  }
}