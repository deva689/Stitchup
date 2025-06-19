import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String senderId;
  final String receiverId;
  final String message;
  final DateTime timestamp;
  final bool isDelivered;
  final bool isRead;
  final String type;
  final String? imageUrl;
  final String? voiceUrl;
  final Map<String, String>? reactions;

  MessageModel({
    required this.senderId,
    required this.receiverId,
    required this.message,
    required this.timestamp,
    required this.isDelivered,
    required this.isRead,
    required this.type,
    this.imageUrl,
    this.voiceUrl,
    this.reactions,
  });

  factory MessageModel.fromMap(Map<String, dynamic> map) {
    try {
      return MessageModel(
        senderId: map['senderId'] ?? '',
        receiverId: map['receiverId'] ?? '',
        message: map['text'] ?? '',
        timestamp: map['timestamp'] is Timestamp
            ? (map['timestamp'] as Timestamp).toDate()
            : DateTime.now(),
        isDelivered: map['isDelivered'] ?? false,
        isRead: map['isRead'] ?? false,
        type: map['type']?.toString() ?? 'text',
        imageUrl: map['imageUrl']?.toString(),
        voiceUrl: map['voiceUrl']?.toString(),
        reactions: _parseReactions(map['reactions']),
      );
    } catch (e) {
      print('❌ Error parsing MessageModel: $e');
      print('⚠️ Raw map: $map');
      return MessageModel(
        senderId: '',
        receiverId: '',
        message: 'Error',
        timestamp: DateTime.now(),
        isDelivered: false,
        isRead: false,
        type: 'text',
      );
    }
  }

  static Map<String, String>? _parseReactions(dynamic data) {
    if (data == null || data is! Map) return null;
    return data.map<String, String>((key, value) {
      return MapEntry(key.toString(), value.toString());
    });
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'receiverId': receiverId,
      'text': message,
      'timestamp': Timestamp.fromDate(timestamp),
      'isDelivered': isDelivered,
      'isRead': isRead,
      'type': type,
      'imageUrl': imageUrl,
      'voiceUrl': voiceUrl,
      'reactions': reactions,
    };
  }

  @override
  String toString() {
    return 'MessageModel(senderId: $senderId, receiverId: $receiverId, message: $message, '
        'timestamp: $timestamp, isDelivered: $isDelivered, isRead: $isRead, '
        'type: $type, imageUrl: $imageUrl, voiceUrl: $voiceUrl, reactions: $reactions)';
  }
}
