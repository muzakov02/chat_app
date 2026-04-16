import 'package:chat_app/data/model/message.dart';
import 'package:chat_app/main.dart';
import 'package:chat_app/presentation/widgets/chat_bar_widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../../data/model/chat_user.dart';

class ChatScreen extends StatefulWidget {
  final ChatUser user;

  const ChatScreen({super.key, required this.user});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _scrollController = ScrollController();
  ChatUser? currentUser;

  String get _currentUserId => FirebaseAuth.instance.currentUser!.uid;

  String get _chatId {
    final ids = [_currentUserId, widget.user.id]..sort();
    return ids.join('_');
  }

  Stream<List<Message>> _getMessages() {
    return FirebaseFirestore.instance
        .collection('chats')
        .doc(_chatId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Message.fromFirestore(doc.data(), doc.id))
              .toList(),
        );
  }

  Future<void> _sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final now = DateTime.now();
    final timeStr = '${now.hour}:${now.minute.toString().padLeft(2, '0')}';

    final message = Message(
      id: '',
      senderId: _currentUserId,
      text: trimmed,
      timestamp: now,
    );

    try {
      // 1. Xabarni saqlash
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(_chatId)
          .collection('messages')
          .add(message.toMap());

      // 2. Chat doc yangilash
      await FirebaseFirestore.instance.collection('chats').doc(_chatId).set({
        'lastMessage': trimmed,
        'lastMessageTime': Timestamp.now(),
        'participants': [_currentUserId, widget.user.id],
        'unreadFor_${widget.user.id}': FieldValue.increment(1),
        // ✅ boshqa user uchun
      }, SetOptions(merge: true));

      // 3. Boshqa user — unreadCount oshadi ✅
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user.id) // ← boshqa user
          .update({
            'lastMessage': trimmed,
            'time': timeStr,
            'unreadCount': FieldValue.increment(1),
          });

      // 4. Men — faqat lastMessage yangilanadi, unreadCount OSHMAYDI ✅
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUserId) // ← men
          .update({
            'lastMessage': trimmed,
            'time': timeStr,
            // ❌ 'unreadCount' bu yerda bo'lmasligi kerak!
          });

      _scrollToBottom();
    } catch (e) {
      debugPrint('Xabar yuborishda xatolik: $e');
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _resetUnreadCount();
  }

  Future<void> _resetUnreadCount() async {
    await FirebaseFirestore.instance.collection('chats').doc(_chatId).update({
      'unreadFor_$_currentUserId': 0, // ✅ faqat men uchun nollash
    });
  }

  Future<void> _loadCurrentUser() async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(_currentUserId)
        .get();

    print('=== currentUserId: $_currentUserId');
    print('=== doc exists: ${doc.exists}');
    print('=== avatarUrl: ${doc.data()?['avatarUrl']}');

    if (doc.exists) {
      setState(() {
        currentUser = ChatUser.fromFirestore(doc.data()!, doc.id);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        titleSpacing: 0, // ✅ title spacing ni kamaytirish
        title: Text(
          widget.user.name,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xFF111111),
          ),
        ),
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: SvgPicture.asset(
              'assets/icons/back_icon.svg',
              width: 46,
              height: 46,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        actions: [
          PopupMenuButton(
            offset: const Offset(-32, 24),
            icon: SvgPicture.asset(
              'assets/icons/setting_icon.svg',
              width: 24,
              height: 24,
            ),
            itemBuilder: (context) => [
              PopupMenuItem(
                onTap: () {
                  // ✅ Ovozli qo'ng'iroq
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CallPage(
                        callID: _chatId, // ✅ ikki user orasidagi unique ID
                        isVideoCall: false, // ✅ audio
                      ),
                    ),
                  );
                },
                child: Row(
                  children: [
                    SvgPicture.asset('assets/icons/call.svg', width: 18, height: 18),
                    const SizedBox(width: 8),
                    const Text('Ovozli',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                onTap: () {
                  // ✅ Video qo'ng'iroq
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CallPage(
                        callID: _chatId,
                        isVideoCall: true, // ✅ video
                      ),
                    ),
                  );
                },
                child: Row(
                  children: [
                    SvgPicture.asset('assets/icons/video.svg', width: 18, height: 18),
                    const SizedBox(width: 8),
                    const Text('Video',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
            ],
          ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Message>>(
              stream: _getMessages(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Center(child: Text('Xatolik yuz berdi'));
                }

                final messages = snapshot.data ?? [];

                if (messages.isEmpty) {
                  return const Center(
                    child: Text(
                      'Hali xabar yo\'q',
                      style: TextStyle(color: Color(0xFF9CA4AB)),
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.senderId == _currentUserId;
                    return _MessageBubble(
                      message: message,
                      isMe: isMe,
                      avatarUrl: widget.user.avatarUrl,
                      myAvatarUrl: currentUser?.avatarUrl ?? '',
                    );
                  },
                );
              },
            ),
          ),

          // ✅ Chat bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: ChatBarWidget(onSendPressed: _sendMessage),
          ),
        ],
      ),
    );
  }
}

// ✅ Xabar bubble widget
class _MessageBubble extends StatelessWidget {
  final Message message;
  final bool isMe;
  final String avatarUrl;
  final String myAvatarUrl;

  const _MessageBubble({
    required this.message,
    required this.isMe,
    required this.avatarUrl,
    required this.myAvatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    final localTime = message.timestamp.toLocal();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (!isMe) ...[
            CircleAvatar(radius: 16, backgroundImage: AssetImage(avatarUrl)),
            const SizedBox(width: 6),
          ],

          // Bubble
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.7,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isMe ? const Color(0xFF4CAF50) : const Color(0xFFEEEEEE),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isMe ? 16 : 4),
                bottomRight: Radius.circular(isMe ? 4 : 16),
              ),
            ),
            child: Column(
              crossAxisAlignment: isMe
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Text(
                  message.text,
                  style: TextStyle(
                    color: isMe ? Colors.white : const Color(0xFF111111),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${localTime.hour}:${localTime.minute.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    color: isMe ? Colors.white70 : const Color(0xFF9CA4AB),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),

          if (isMe) ...[
            const SizedBox(width: 6),
            CircleAvatar(radius: 16, backgroundImage: AssetImage(myAvatarUrl)),
          ],
        ],
      ),
    );
  }
}
