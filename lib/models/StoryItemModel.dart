import 'package:cloud_firestore/cloud_firestore.dart';

class StoryItemModel {
  final String storyId;
  final String mediaType;
  final String mediaUrl;
  final DateTime uploadedAt;
  final List<String> viewedBy;

  StoryItemModel({
    required this.storyId,
    required this.mediaType,
    required this.mediaUrl,
    required this.uploadedAt,
    required this.viewedBy,
  });

  factory StoryItemModel.fromJson(Map<String, dynamic> json, String storyId) {
    return StoryItemModel(
      storyId: storyId,
      mediaType: json['mediaType'],
      mediaUrl: json['mediaUrl'],
      uploadedAt: (json['uploadedAt'] as Timestamp).toDate(),
      viewedBy: List<String>.from(json['viewedBy'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'mediaType': mediaType,
      'mediaUrl': mediaUrl,
      'uploadedAt': uploadedAt,
      'viewedBy': viewedBy,
    };
  }
}
