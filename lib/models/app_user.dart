import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole {
  renter,
  owner,
  both,
}

class AppUser {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String? profileImageUrl;
  final UserRole role;
  final String? address;
  final double? latitude;
  final double? longitude;
  final bool isVerified;
  final bool isEmailVerified;
  final bool isPhoneVerified;
  final DateTime createdAt;
  final DateTime lastActiveAt;
  final double rating;
  final int reviewCount;
  final List<String> savedItems;
  final Map<String, dynamic> preferences;
  final Map<String, dynamic> metadata;

  AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.profileImageUrl,
    this.role = UserRole.renter,
    this.address,
    this.latitude,
    this.longitude,
    this.isVerified = false,
    this.isEmailVerified = false,
    this.isPhoneVerified = false,
    required this.createdAt,
    required this.lastActiveAt,
    this.rating = 0.0,
    this.reviewCount = 0,
    this.savedItems = const [],
    this.preferences = const {},
    this.metadata = const {},
  });

  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppUser(
      id: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      profileImageUrl: data['profileImageUrl'],
      role: UserRole.values.firstWhere(
        (e) => e.toString() == 'UserRole.${data['role']}',
        orElse: () => UserRole.renter,
      ),
      address: data['address'],
      latitude: data['latitude']?.toDouble(),
      longitude: data['longitude']?.toDouble(),
      isVerified: data['isVerified'] ?? false,
      isEmailVerified: data['isEmailVerified'] ?? false,
      isPhoneVerified: data['isPhoneVerified'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastActiveAt: (data['lastActiveAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      rating: (data['rating'] ?? 0).toDouble(),
      reviewCount: data['reviewCount'] ?? 0,
      savedItems: List<String>.from(data['savedItems'] ?? []),
      preferences: Map<String, dynamic>.from(data['preferences'] ?? {}),
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'profileImageUrl': profileImageUrl,
      'role': role.toString().split('.').last,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'isVerified': isVerified,
      'isEmailVerified': isEmailVerified,
      'isPhoneVerified': isPhoneVerified,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastActiveAt': Timestamp.fromDate(lastActiveAt),
      'rating': rating,
      'reviewCount': reviewCount,
      'savedItems': savedItems,
      'preferences': preferences,
      'metadata': metadata,
    };
  }

  String get roleDisplayName {
    switch (role) {
      case UserRole.renter:
        return 'Renter';
      case UserRole.owner:
        return 'Owner';
      case UserRole.both:
        return 'Renter & Owner';
    }
  }

  bool get canRent => role == UserRole.renter || role == UserRole.both;
  bool get canListItems => role == UserRole.owner || role == UserRole.both;

  String get initials {
    final nameParts = name.split(' ');
    if (nameParts.length >= 2) {
      return '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase();
    } else if (nameParts.isNotEmpty) {
      return nameParts[0][0].toUpperCase();
    }
    return 'U';
  }

  AppUser copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? profileImageUrl,
    UserRole? role,
    String? address,
    double? latitude,
    double? longitude,
    bool? isVerified,
    bool? isEmailVerified,
    bool? isPhoneVerified,
    DateTime? createdAt,
    DateTime? lastActiveAt,
    double? rating,
    int? reviewCount,
    List<String>? savedItems,
    Map<String, dynamic>? preferences,
    Map<String, dynamic>? metadata,
  }) {
    return AppUser(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      role: role ?? this.role,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isVerified: isVerified ?? this.isVerified,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      isPhoneVerified: isPhoneVerified ?? this.isPhoneVerified,
      createdAt: createdAt ?? this.createdAt,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      savedItems: savedItems ?? this.savedItems,
      preferences: preferences ?? this.preferences,
      metadata: metadata ?? this.metadata,
    );
  }
}