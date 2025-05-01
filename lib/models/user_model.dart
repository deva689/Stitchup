import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String phoneNumber;
  final String profilePic;
  final String about;
  final bool isOnline;
  final DateTime? lastSeen;

  UserModel({
    required this.uid,
    required this.name,
    required this.phoneNumber,
    required this.profilePic,
    required this.about,
    required this.isOnline,
    required this.lastSeen,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'phoneNumber': phoneNumber,
      'profilePic': profilePic,
      'about': about,
      'isOnline': isOnline,
      'lastSeen': lastSeen != null ? Timestamp.fromDate(lastSeen!) : null,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      profilePic: map['profilePic'] ?? '',
      about: map['about'] ?? '',
      isOnline: map['isOnline'] ?? false,
      lastSeen: (map['lastSeen'] as Timestamp?)?.toDate(), // ✅ Safe conversion
    );
  }
}
