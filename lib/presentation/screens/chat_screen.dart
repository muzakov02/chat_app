import 'package:chat_app/data/model/message.dart';
import 'package:chat_app/main.dart';
import 'package:chat_app/presentation/screens/video_call_screen.dart';
import 'package:chat_app/presentation/widgets/chat_bar_widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../../data/model/chat_user.dart';
import 'audio_call_screen.dart';

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
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(_chatId)
          .collection('messages')
          .add(message.toMap());

      await FirebaseFirestore.instance.collection('chats').doc(_chatId).set({
        'lastMessage': trimmed,
        'lastMessageTime': Timestamp.now(),
        'participants': [_currentUserId, widget.user.id],
        'unreadFor_${widget.user.id}': FieldValue.increment(1),
        // ✅ boshqa user uchun
      }, SetOptions(merge: true));



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
    _initChatDocument().then((_) => _resetUnreadCount());

  }
  Future<void> _initChatDocument() async {
    final chatDoc = await FirebaseFirestore.instance
        .collection('chats')
        .doc(_chatId)
        .get();

    final currentUserDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(_currentUserId)
        .get();


    final otherUserDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.user.id)
        .get();

    final currentUserName = currentUserDoc.data()?['name'] ?? '';
    final currentUserAvatar = currentUserDoc.data()?['avatarUrl'] ?? '';


    final otherUserName = widget.user.name.isNotEmpty
        ? widget.user.name
        : (otherUserDoc.data()?['name'] ?? '');
    final otherUserAvatar = widget.user.avatarUrl.isNotEmpty
        ? widget.user.avatarUrl
        : (otherUserDoc.data()?['avatarUrl'] ?? '');

    final existingNames = Map<String, dynamic>.from(
        chatDoc.data()?['participantNames'] ?? {});
    final existingAvatars = Map<String, dynamic>.from(
        chatDoc.data()?['participantAvatars'] ?? {});

    if (existingNames[_currentUserId]?.isEmpty ?? true) {
      existingNames[_currentUserId] = currentUserName;
    }
    if (existingAvatars[_currentUserId]?.isEmpty ?? true) {
      existingAvatars[_currentUserId] = currentUserAvatar;
    }
    if (existingNames[widget.user.id]?.isEmpty ?? true) {
      existingNames[widget.user.id] = otherUserName; // ✅
    }
    if (existingAvatars[widget.user.id]?.isEmpty ?? true) {
      existingAvatars[widget.user.id] = otherUserAvatar; // ✅
    }

    await FirebaseFirestore.instance
        .collection('chats')
        .doc(_chatId)
        .set({
      'participants': [_currentUserId, widget.user.id],
      'participantNames': existingNames,
      'participantAvatars': existingAvatars,
    }, SetOptions(merge: true));
  }

  Future<void> _resetUnreadCount() async {
    await FirebaseFirestore.instance.collection('chats').doc(_chatId).update({
      'unreadFor_$_currentUserId': 0,
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
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(top: 16.0),
          child: Text(
            widget.user.name,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color(0xFF111111),
            ),
          ),
        ),
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0,top: 16.0),
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
          Padding(
            padding: const EdgeInsets.only(top: 16.0, right: 4.0),
            child: Theme(
              data: Theme.of(context).copyWith(
                popupMenuTheme: PopupMenuThemeData(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 8,
                ),
              ),
              child: PopupMenuButton<String>(
                offset: const Offset(-30, 16),
                icon: SvgPicture.asset(
                  'assets/icons/setting_icon.svg',
                  width: 24,
                  height: 24,
                ),
                onSelected: (value) {
                  if (value == 'audio') {
                    Navigator.push(context, MaterialPageRoute(
                      builder: (_) => AudioCallScreen(
                        remoteUser: widget.user,
                        callId: _chatId,
                        isCaller: true,
                      ),
                    ));
                  } else if (value == 'video') {
                    Navigator.push(context, MaterialPageRoute(
                      builder: (_) => VideoCallScreen(
                        remoteUser: widget.user,
                        callId: _chatId,
                        isCaller: true,
                      ),
                    ));
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem<String>(
                    value: 'audio',
                    child: Row(
                      children: [
                        SvgPicture.asset(
                          'assets/icons/call.svg',
                          width: 18,
                          height: 18,
                          colorFilter: const ColorFilter.mode(
                            Color(0xFF111111),
                            BlendMode.srcIn,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Ovozli',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF111111),
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'video',
                    child: Row(
                      children: [
                        SvgPicture.asset(
                          'assets/icons/video.svg',


                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Video',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF56CB01),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
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
                  padding: const EdgeInsets.only(
                    left: 24.0,
                    top: 26.0,
                    right: 24.0
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
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: ChatBarWidget(onSendPressed: _sendMessage),
          ),
        ],
      ),
    );
  }
}


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
            CircleAvatar(
              radius: 16,
              backgroundImage: avatarUrl.isNotEmpty
                  ? AssetImage(avatarUrl) as ImageProvider
                  : const AssetImage('assets/images/avatar1.png'),
            ),
            const SizedBox(width: 6),
          ],

          // Bubble
          Column(
            crossAxisAlignment: isMe
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.7,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isMe ? const Color(0xFF56CB01) : const Color(0xFFEEEEEE),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(isMe ? 16 : 4),
                    bottomRight: Radius.circular(isMe ? 4 : 16),
                  ),
                ),
                child: Text(
                  message.text,
                  style: TextStyle(
                    color: isMe ? Colors.white : const Color(0xFF111111),
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${localTime.hour}:${localTime.minute.toString().padLeft(2, '0')}',
                style: const TextStyle(
                  color: Color(0xFF9CA4AB),
                  fontSize: 11,
                ),
              ),
            ],
          ),

          if (isMe) ...[
            const SizedBox(width: 6),
            CircleAvatar(
              radius: 16,
              backgroundImage: myAvatarUrl.isNotEmpty
                  ? AssetImage(myAvatarUrl) as ImageProvider
                  : const AssetImage('assets/images/avatar1.png'),
            ),
          ],
        ],
      ),
    );
  }
}


