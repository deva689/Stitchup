// ✅ WhatsApp-like Flutter Chat Models with Firestore Integration

import 'package:cloud_firestore/cloud_firestore.dart';

// 📘 ChatModel → Represents a chat between two users
class ChatModel {
  final List<String> participants;
  final Map<String, int> unreadCounts;
  final LastMessage? lastMessage;
  final Timestamp lastUpdated;

  ChatModel({
    required this.participants,
    required this.unreadCounts,
    required this.lastUpdated,
    this.lastMessage,
  });

  Map<String, dynamic> toMap() {
    return {
      'participants': participants,
      'unreadCounts': unreadCounts,
      'lastUpdated': lastUpdated,
      'lastMessage': lastMessage?.toMap(),
    };
  }

  factory ChatModel.fromMap(Map<String, dynamic> map) {
    return ChatModel(
      participants: List<String>.from(map['participants']),
      unreadCounts: Map<String, int>.from(map['unreadCounts']),
      lastUpdated: map['lastUpdated'],
      lastMessage: map['lastMessage'] != null
          ? LastMessage.fromMap(Map<String, dynamic>.from(map['lastMessage']))
          : null,
    );
  }
}

// 💬 LastMessage → Nested inside ChatModel to show preview
class LastMessage {
  final String id;
  final String text;
  final String senderId;
  final Timestamp timestamp;
  final List<String> seenBy;
  final String type; // "text", "image", "video", "audio"

  LastMessage({
    required this.id,
    required this.text,
    required this.senderId,
    required this.timestamp,
    required this.seenBy,
    this.type = "text",
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'text': text,
      'senderId': senderId,
      'timestamp': timestamp,
      'seenBy': seenBy,
      'type': type,
    };
  }

  factory LastMessage.fromMap(Map<String, dynamic> map) {
    return LastMessage(
      id: map['id'],
      text: map['text'],
      senderId: map['senderId'],
      timestamp: map['timestamp'],
      seenBy: List<String>.from(map['seenBy']),
      type: map['type'] ?? "text",
    );
  }
}

// 📨 MessageModel → Individual message inside chats/{chatId}/messages/
class MessageModel {
  final String id;
  final String senderId;
  final String? text;
  final String? mediaUrl; // For images, videos, audio
  final String type; // "text", "image", "video", "audio"
  final Timestamp timestamp;
  final List<String> seenBy;
  final String? repliedToMessageId;
  final String? repliedToText;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.timestamp,
    required this.seenBy,
    this.text,
    this.mediaUrl,
    this.type = "text",
    this.repliedToMessageId,
    this.repliedToText,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'senderId': senderId,
      'text': text,
      'mediaUrl': mediaUrl,
      'type': type,
      'timestamp': timestamp,
      'seenBy': seenBy,
      'repliedToMessageId': repliedToMessageId,
      'repliedToText': repliedToText,
    };
  }

  factory MessageModel.fromMap(Map<String, dynamic> map) {
    return MessageModel(
      id: map['id'],
      senderId: map['senderId'],
      text: map['text'],
      mediaUrl: map['mediaUrl'],
      type: map['type'] ?? "text",
      timestamp: map['timestamp'],
      seenBy: List<String>.from(map['seenBy']),
      repliedToMessageId: map['repliedToMessageId'],
      repliedToText: map['repliedToText'],
    );
  }
}

// ✅ These models support:
// - Text & Media messages
// - Message seen status
// - Reply feature (like WhatsApp)
// - Last message preview in chat list
// - Unread count per user
