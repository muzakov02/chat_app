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
  State<MessageScreen> createState() => _MessageScreenState();
}

class _MessageScreenState extends State<MessageScreen> {
  String searchQuery = '';
  final String currentUserId =
      FirebaseAuth.instance.currentUser?.uid ?? '';

  // ✅ chats collection dan o'qish
  Stream<List<Map<String, dynamic>>> getChats() {
    return FirebaseFirestore.instance
        .collection('chats')
        .where('participants', arrayContains: currentUserId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => {'id': doc.id, ...doc.data()})
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
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: getChats(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Xatolik: ${snapshot.error}'));
                  }

                  final chats = snapshot.data ?? [];

                  if (chats.isEmpty) {
                    return const Center(child: Text('Hali chatlar yo\'q'));
                  }

                  final filtered = chats.where((chat) {
                    final names = Map<String, dynamic>.from(
                        chat['participantNames'] ?? {});
                    final otherName = names.entries
                        .firstWhere(
                          (e) => e.key != currentUserId,
                      orElse: () => MapEntry('', ''),
                    )
                        .value
                        .toString()
                        .toLowerCase();
                    return otherName.contains(searchQuery.toLowerCase());
                  }).toList();

                  return ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final chat = filtered[index];

                      final participants =
                      List<String>.from(chat['participants'] ?? []);
                      final otherUserId = participants.firstWhere(
                            (id) => id != currentUserId,
                        orElse: () => '',
                      );

                      final names = Map<String, dynamic>.from(
                          chat['participantNames'] ?? {});
                      final avatars = Map<String, dynamic>.from(
                          chat['participantAvatars'] ?? {});
                      final unreadCount =
                      (chat['unreadFor_$currentUserId'] ?? 0) as int;
                      final lastMessage = chat['lastMessage'] ?? '';
                      final lastTime =
                      chat['lastMessageTime'] as Timestamp?;
                      final timeStr = lastTime != null
                          ? '${lastTime.toDate().toLocal().hour}:${lastTime.toDate().toLocal().minute.toString().padLeft(2, '0')}'
                          : '';

                      final otherUser = ChatUser(
                        id: otherUserId,
                        name: names[otherUserId] ?? '',
                        avatarUrl: avatars[otherUserId] ?? '',
                        isOnline: false,
                        lastMessage: lastMessage,
                        time: timeStr,
                        unreadCount: unreadCount,
                      );

                      return Dismissible(
                        key: Key(chat['id']),
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
                              .collection('chats')
                              .doc(chat['id'])
                              .delete();
                        },
                        child: ChatWidget(
                          user: otherUser,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    ChatScreen(user: otherUser),
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