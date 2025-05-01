import 'package:cloud_firestore/cloud_firestore.dart';

class StatusModel {
  final String uid;
  final List<String> statusUrls;
  final DateTime timestamp;
  final String name;
  final String profilePic;

  StatusModel({
    required this.uid,
    required this.statusUrls,
    required this.timestamp,
    required this.name,
    required this.profilePic,
  });

  factory StatusModel.fromMap(Map<String, dynamic> map) {
    return StatusModel(
      uid: map['uid'],
      statusUrls: List<String>.from(map['status']),
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      name: map['name'],
      profilePic: map['profilePic'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'status': statusUrls,
      'timestamp': Timestamp.fromDate(timestamp),
      'name': name,
      'profilePic': profilePic,
    };
  }
}
