class UserModel {
  final String uid;
  final String username;
  final String? name;
  final String? photoUrl;

  UserModel({
    required this.uid,
    required this.username,
    this.name,
    this.photoUrl,
  });

  factory UserModel.fromMap(Map<String, dynamic> data, String uid) {
    return UserModel(
      uid: uid,
      username: data['username'] ?? '',
      name: data['name'],
      photoUrl: data['photoUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'name': name,
      'photoUrl': photoUrl,
    };
  }
}
