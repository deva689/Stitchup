import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String senderId;
  final String receiverId;
  final String message;
  final DateTime timestamp;
  final bool isDelivered;
  final bool isRead;
  final String? voiceUrl; // For voice messages
  final Map<String, String>? reactions; // UID → Emoji map

  MessageModel({
    required this.senderId,
    required this.receiverId,
    required this.message,
    required this.timestamp,
    required this.isDelivered,
    required this.isRead,
    this.voiceUrl,
    this.reactions,
  });

  /// ✅ From Firestore document
  factory MessageModel.fromMap(Map<String, dynamic> map) {
    return MessageModel(
      senderId: map['senderId'] ?? '',
      receiverId: map['receiverId'] ?? '',
      message: map['message'] ?? '',
      timestamp: map['timestamp'] != null
          ? (map['timestamp'] as Timestamp).toDate()
          : DateTime.now(), // fallback if null
      isDelivered: map['isDelivered'] ?? false,
      isRead: map['isRead'] ?? false,
      voiceUrl: map['voiceUrl'],
      reactions: map['reactions'] != null
          ? Map<String, String>.from(map['reactions'])
          : null,
    );
  }

  /// ✅ To Firestore document
  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'receiverId': receiverId,
      'message': message,
      'timestamp': Timestamp.fromDate(timestamp),
      'isDelivered': isDelivered,
      'isRead': isRead,
      'voiceUrl': voiceUrl,
      'reactions': reactions,
    };
  }

  /// ✅ Create modified copy
  MessageModel copyWith({
    String? senderId,
    String? receiverId,
    String? message,
    DateTime? timestamp,
    bool? isDelivered,
    bool? isRead,
    String? voiceUrl,
    Map<String, String>? reactions,
  }) {
    return MessageModel(
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      isDelivered: isDelivered ?? this.isDelivered,
      isRead: isRead ?? this.isRead,
      voiceUrl: voiceUrl ?? this.voiceUrl,
      reactions: reactions ?? this.reactions,
    );
  }

  /// ✅ For debugging
  @override
  String toString() {
    return 'MessageModel(senderId: $senderId, receiverId: $receiverId, message: $message, '
        'timestamp: $timestamp, isDelivered: $isDelivered, isRead: $isRead, '
        'voiceUrl: $voiceUrl, reactions: $reactions)';
  }
}
