class ChatUser {
  final String id;
  final String name;
  final String avatarUrl;
  final bool isOnline;
  final String lastMessage;
  final String time;
  final int unreadCount;

  ChatUser({
    required this.id,
    required this.name,
    required this.avatarUrl,
    required this.isOnline,
    required this.lastMessage,
    required this.time,
    required this.unreadCount,
  });

  factory ChatUser.fromFirestore(Map<String, dynamic> data, String id) {
    return ChatUser(
      id: id,
      name: data['name'] ?? '',
      avatarUrl: data['avatarUrl'] ?? '',
      isOnline: data['isOnline'] ?? false,
      lastMessage: '',
      time: '',
      unreadCount: 0,
    );
  }

  // ✅ chats collection dan — lastMessage, time, unreadCount olish
  factory ChatUser.fromChat({
    required String id,
    required String name,
    required String avatarUrl,
    required bool isOnline,
    required String lastMessage,
    required String time,
    required int unreadCount,
  }) {
    return ChatUser(
      id: id,
      name: name,
      avatarUrl: avatarUrl,
      isOnline: isOnline,
      lastMessage: lastMessage,
      time: time,
      unreadCount: unreadCount,
    );
  }
}