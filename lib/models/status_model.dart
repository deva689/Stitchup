import 'package:cloud_firestore/cloud_firestore.dart';

class StatusModel {
  final String userId;
  final String statusId;
  final String mediaUrl;
  final bool isVideo;
  final DateTime timestamp;
  final List<String> views;
  final String? userName; // optional
  final String? profileImageUrl; // optional

  StatusModel({
    required this.userId,
    required this.statusId,
    required this.mediaUrl,
    required this.isVideo,
    required this.timestamp,
    required this.views,
    this.userName,
    this.profileImageUrl,
  });

  factory StatusModel.fromJson(Map<String, dynamic> json) {
    return StatusModel(
      userId: json['userId'] ?? '',
      statusId: json['statusId'] ?? '',
      mediaUrl: json['mediaUrl'] ?? '',
      isVideo: json['isVideo'] ?? false,
      timestamp: (json['timestamp'] as Timestamp).toDate(),
      views: List<String>.from(json['views'] ?? []),
      userName: json['userName'],
      profileImageUrl: json['profileImageUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'statusId': statusId,
      'mediaUrl': mediaUrl,
      'isVideo': isVideo,
      'timestamp': Timestamp.fromDate(timestamp),
      'views': views,
      if (userName != null) 'userName': userName,
      if (profileImageUrl != null) 'profileImageUrl': profileImageUrl,
    };
  }
}
