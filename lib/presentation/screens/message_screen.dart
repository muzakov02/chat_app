import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../data/model/chat_user.dart';
import '../widgets/chat_search_bar.dart';
import '../widgets/chat_widget.dart';
import 'chat_screen.dart';

class MessageScreen extends StatefulWidget {
  const MessageScreen({super.key});

  @override
  State<MessageScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<MessageScreen> {
  String searchQuery = '';

  Stream<List<ChatUser>> getUsers() {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    return FirebaseFirestore.instance
        .collection('users')
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => ChatUser.fromFirestore(doc.data(), doc.id))
        .where((user) => user.id != currentUserId)
        .toList());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFFFFF),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Xabarlar',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xFF111111),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.only(left: 16.0, right: 16.0),
        child: Column(
          children: [
            const SizedBox(height: 16),
            ChatSearchBar(
              hintText: 'Qidirish...',
              onQueryChanged: (query) {
                setState(() => searchQuery = query);
              },
            ),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<List<ChatUser>>(
                stream: getUsers(),
                builder: (context, snapshot) {
                  // Loading
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  // Error
                  if (snapshot.hasError) {
                    return Center(child: Text('Xatolik: ${snapshot.error}'));
                  }

                  // Filter by search
                  final users = (snapshot.data ?? [])
                      .where((u) => u.name
                      .toLowerCase()
                      .contains(searchQuery.toLowerCase()))
                      .toList();

                  if (users.isEmpty) {
                    return const Center(child: Text('Foydalanuvchi topilmadi'));
                  }

                  return ListView.builder(
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      return Dismissible(
                        key: Key(users[index].id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFEEEE),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.delete_outline,
                              color: Colors.red),
                        ),
                        onDismissed: (_) {
                          FirebaseFirestore.instance
                              .collection('users')
                              .doc(users[index].id)
                              .delete();
                        },
                        child: ChatWidget(
                          user: users[index],
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ChatScreen(user: users[index]),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () {},
          backgroundColor: const Color(0xFF111111),
          elevation: 0,
          shape: const CircleBorder(),
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }
}