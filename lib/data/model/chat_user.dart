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
      lastMessage: data['lastMessage'] ?? '',
      time: data['time'] ?? '',
      unreadCount: data['unreadCount'] ?? 0,
    );
  }
}