class ChatModel {
  final String chatId;
  final List<String> participants;
  final DateTime lastMessageTime;
  final String lastMessage;
  final String lastMessageSender;

  ChatModel({
    required this.chatId,
    required this.participants,
    required this.lastMessageTime,
    required this.lastMessage,
    required this.lastMessageSender,
  });

  factory ChatModel.fromMap(Map<String, dynamic> map, String id) {
    return ChatModel(
      chatId: id,
      participants: List<String>.from(map['participants']),
      lastMessageTime: map['lastMessageTime'].toDate(),
      lastMessage: map['lastMessage'],
      lastMessageSender: map['lastMessageSender'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'participants': participants,
      'lastMessageTime': lastMessageTime,
      'lastMessage': lastMessage,
      'lastMessageSender': lastMessageSender,
    };
  }
}
