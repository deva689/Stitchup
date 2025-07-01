import 'package:cloud_firestore/cloud_firestore.dart';

class StatusModel {
  final String userId;
  final String statusId;
  final String mediaUrl;
  final String? thumbnailUrl; // ✅ For video preview
  final bool isVideo;
  final DateTime timestamp;
  final List<String> views;
  final String? userName; // Optional: Can be displayed in viewer
  final String? profileImageUrl; // Optional: For profile circle
  final String? caption; // ✅ Optional text with status

  StatusModel({
    required this.userId,
    required this.statusId,
    required this.mediaUrl,
    this.thumbnailUrl,
    required this.isVideo,
    required this.timestamp,
    required this.views,
    this.userName,
    this.profileImageUrl,
    this.caption,
  });

  factory StatusModel.fromJson(Map<String, dynamic> json) {
    return StatusModel(
      userId: json['userId'] ?? '',
      statusId: json['statusId'] ?? '',
      mediaUrl: json['mediaUrl'] ?? '',
      thumbnailUrl: json['thumbnailUrl'], // ✅ May be null
      isVideo: json['isVideo'] ?? false,
      timestamp: (json['timestamp'] as Timestamp).toDate(),
      views: List<String>.from(json['views'] ?? []),
      userName: json['userName'], // nullable
      profileImageUrl: json['profileImageUrl'], // nullable
      caption: json['caption'], // nullable
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'statusId': statusId,
      'mediaUrl': mediaUrl,
      if (thumbnailUrl != null) 'thumbnailUrl': thumbnailUrl,
      'isVideo': isVideo,
      'timestamp': Timestamp.fromDate(timestamp),
      'views': views,
      if (userName != null) 'userName': userName,
      if (profileImageUrl != null) 'profileImageUrl': profileImageUrl,
      if (caption != null) 'caption': caption,
    };
  }
}
