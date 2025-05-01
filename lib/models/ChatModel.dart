import 'package:cloud_firestore/cloud_firestore.dart';

class ChatModel {
  final String chatId;
  final List<String> participants;
  final LastMessage? lastMessage;

  ChatModel({
    required this.chatId,
    required this.participants,
    this.lastMessage,
  });

  factory ChatModel.fromMap(Map<String, dynamic> map, String docId) {
    return ChatModel(
      chatId: docId,
      participants: List<String>.from(map['participants'] ?? []),
      lastMessage: map['lastMessage'] != null
          ? LastMessage.fromMap(map['lastMessage'] as Map<String, dynamic>)
          : null,
    );
  }
}

class LastMessage {
  final String text;
  final Timestamp timestamp;
  final String senderId;
  final String status;

  LastMessage({
    required this.text,
    required this.timestamp,
    required this.senderId,
    required this.status,
  });

  factory LastMessage.fromMap(Map<String, dynamic> map) {
    return LastMessage(
      text: map['text'] as String? ?? '',
      timestamp: map['timestamp'] as Timestamp? ?? Timestamp.now(),
      senderId: map['senderId'] as String? ?? '',
      status: map['status'] as String? ?? 'sent', // sent, delivered, read
    );
  }
}
